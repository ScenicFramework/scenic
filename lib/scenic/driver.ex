#
#  Created by Boyd Multerer on 2021-02-06
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Driver do
  @moduledoc """
  The main module for drawing and user input.

  Note: The driver model has completely changed in v0.11.

  Drivers make up the bottom layer of the Scenic architectural stack. They draw
  everything on the screen and originate the raw user input. In general, different
  drawing targets will need different drivers.

  The driver interface provides a great deal of flexibility, but is more
  advanced than writing scenes. You can write drivers that only provide user input,
  only draw scripts, or do both. There is no assumption at all as to what the
  output target or user source is.

  ## Starting Drivers

  Drivers are always managed by a ViewPort that hosts them.

  The most common way to instantiate a driver is set it up in the config of
  a ViewPort when it starts up.

  ```elixir
  config :my_app, :viewport,
    size: {800, 600},
    name: :main_viewport,
    theme: :dark,
    default_scene: MyApp.Scene.MainScene,
    drivers: [
      [
        module: Scenic.Driver.Glfw,
        name: :glfw_driver,
        title: "My Application",
        resizeable: false
      ],
      [
        module: MyApp.Driver.MyDriver,
        my_param: "abc"
      ],
    ]
  ```

  In the example above, two drivers are configured to be started when the
  `:main_viewport` starts up. Both drivers drivers will be running at the
  same time and will receive the same messages from the ViewPort.

  Drivers can be dynamically started on a `ViewPort` using
  `Scenic.ViewPort.start_driver/2`. They can be dyncamically stopped on
  a `ViewPort` using  `Scenic.ViewPort.stop_driver/2`.

  Drivers can also define their own configuration options. See the
  documentation for the driver you are interested in starting to see the
  available options.

  ## Messages from the ViewPort

  The way a ViewPort communicates with it's drivers is by sending them a
  set of well-known messages. These are picked up by the Driver module and
  sent to your driver through the standard callbacks
  them.


  THE TABLE BELOW NEEDS TO BE UPDATED

  | Callback | Description |
  |---|---|
  | `{:request_input, keys}` | The ViewPort is requesting user inputs from the `keys` list |
  | `:reset` | The `ViewPort` context has been reset. The driver can clean up all scripts and cached media |
  | `{:put_scripts, ids}` | The scripts identified by `ids` have been update and should be processed |
  | `{:del_script, id}` | The script identified by `id` has been deleted and can be cleaned up |
  | `:gate_start` | Start a script gate. Scripts should be processed, but not drawn until the gate is complete |
  | `:gate_complete` | The gate is complete. This should trigger a redraw |


  ## Handling Updates

  The main drawing related task of a Driver is to receive the `{:put_scripts, ids}`
  message and then draw those scripts to the screen, or whatever output medium the
  driver supports.

  In the simplest case, it would look something like this.

  ```elixir
  def handle_cast( {:put_scripts, ids}, %{port: port, view_port: vp, gated: gated} = state ) do
    ids
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.each( fn(id) ->
      with {:ok, script} <- ViewPort.get_script_by_id(vp, id) do
        script
        |> Scenic.Script.serialize()
        |> my_send_to_port(id, port)
      end
    end)
    if gated == false do
      my_send_redraw_to_port(port)
    end
  end
  ```

  The above example is overly simple and just there to get you started. There are several
  points you should make note of.

    * Only the ids of the scripts are sent. You still need to fish them out of the `ViewPort`
    * The list of ids sent to the driver might need to be flattened
    * If a script is updated very quickly, it might be in the list twice. Use `Enum.uniq()`
    to avoid doing unnecessary work
    * You might have been previously sent a `:gate_start` message. If you are not in a gate,
    do whatever you need to do to redraw the screen after processing all the put scripts.
    * If you are in a gate, do not redraw the screen. This happens when there are more
    `:put_scripts` messages coming.

  Normally, you would want to add some amount of debouncing to handle cases when a script
  is updated faster than your frame rate, or other constraint. You can also add options
  to the `Scenic.Script.serialize` call to customize how the data is serialized.


  ## User Input

  User input events are created whenever a driver has events to share. The `ViewPort`
  will send `{:request_input, keys}` messages to the drivers to indicate which input
  types it is listening for, but that is a guide to prevent unnecessary work. You can
  send any input message at any time.

  In this example, there is some source of user input that casts messages to our driver.

  ```elixir
  def handle_cast( {:my_cursor_press, button, xy}, %{viewport: vp} = state ) do
    Scenic.ViewPort.Input.send(vp, {:cursor_button, {button, :press, 0, xy}} )
    { :noreply, state }
  end
  ```

  No matter what type of input you are sending to the `ViewPort`, it will be checked to
  make sure it conforms the [known input types](Scenic.ViewPort.Input.html#t:t/0).

  NOTE: In older versions of Scenic, the button indicator was one of `:left`, `:center`, or `:right`.
  It seemed like `:left` was really being used to mean the "primary" button, which is a form of
  handedness bias. So now the button indicator is typed to an integer, typically
  `0`, `1`, or `2`, where `0` is the primary button.
  """

  alias Scenic.Driver
  alias Scenic.ViewPort
  alias Scenic.Color

  # import IEx
  require Logger

  @root_id ViewPort.root_id()
  # @main_id ViewPort.main_id()

  # ============================================================================
  # Driver Struct

  @type t :: %Driver{
          viewport: ViewPort.t(),
          pid: pid,
          module: atom,
          limit_ms: integer,
          dirty_ids: list,
          gated: boolean,
          input_limited: boolean,
          input_buffer: %{ViewPort.Input.class() => ViewPort.Input.t()},
          busy: boolean,
          requested_inputs: [ViewPort.Input.class()],
          assigns: map,
          update_requested: boolean,
          update_ready: boolean,
          clear_color: Color.rgba()
        }

  defstruct viewport: nil,
            pid: nil,
            module: nil,
            limit_ms: 0,
            dirty_ids: [],
            gated: false,
            input_limited: false,
            input_buffer: %{},
            busy: false,
            requested_inputs: [],
            assigns: %{},
            update_requested: false,
            update_ready: false,
            clear_color: {:color_rgba, {0, 0, 0, 255}}

  @type response_opts ::
          list(
            timeout()
            | :hibernate
            | {:continue, term}
          )

  @init :_init_
  @input_limiter :_input_limiter_expired_
  @not_busy :_not_busy_
  @do_update :_do_update_

  @put_scripts ViewPort.msg_put_scripts()
  @request_input ViewPort.msg_request_input()
  @del_scripts ViewPort.msg_del_scripts()
  @reset_scene ViewPort.msg_reset_scene()
  @gate_start ViewPort.msg_gate_start()
  @gate_complete ViewPort.msg_gate_complete()
  @clear_color ViewPort.msg_clear_color()

  # ============================================================================
  # callback definitions

  @doc """
  Validate the options passed to a Driver.

  The list of options for a driver are passed in as `opts`. If you decide then are
  good, return them, or a transformed set of them as `{:ok, opts}`

  If they are invalid, return either one of:
    * `{:error, String.t()}`
    * `{:error, NimbleOptions.ValidationError.t()}`

  Scenic uses `NimbleOptions` internally for options validation, so `NimbleOptions`
  errors are supported.
  """
  @callback validate_opts(opts :: Keyword.t()) ::
              {:ok, any}
              | {:error, String.t()}
              | {:error, NimbleOptions.ValidationError.t()}

  @doc """
  Initialize a driver process.

  The `ViewPort` and an options list for the driver are passed in. Just like
  initializing any `GenServer` process, it should return `{:ok, state}`
  """
  @callback init(
              driver :: Driver.t(),
              opts :: Keyword.t()
            ) :: {:ok, Driver.t()}

  @callback reset_scene(driver :: Driver.t()) :: {:ok, Driver.t()}

  @callback request_input(
              input :: [Scenic.ViewPort.Input.class()],
              driver :: Driver.t()
            ) :: {:ok, Driver.t()}

  @callback update_scene(
              script_ids :: [Scenic.Script.id()],
              driver :: Driver.t()
            ) :: {:ok, Driver.t()}

  @callback del_scripts(
              script_ids :: [Scenic.Script.id()],
              driver :: Driver.t()
            ) :: {:ok, Driver.t()}

  @callback clear_color(
              color :: Scenic.Color.t(),
              driver :: Driver.t()
            ) :: {:ok, Driver.t()}

  @optional_callbacks reset_scene: 1,
                      request_input: 2,
                      update_scene: 2,
                      del_scripts: 2,
                      clear_color: 2

  # ===========================================================================
  defmodule Error do
    defexception message: nil
  end

  # ============================================================================
  # client api - working with the driver

  @doc """
  Convenience function to get an assigned value out of a driver struct.
  """
  @spec get(driver :: Driver.t(), key :: any, default :: any) :: any
  def get(%Driver{assigns: assigns}, key, default \\ nil) do
    Map.get(assigns, key, default)
  end

  @doc """
  Convenience function to fetch an assigned value out of a driver struct.
  """
  @spec fetch(driver :: Driver.t(), key :: any) :: {:ok, any} | :error
  def fetch(%Driver{assigns: assigns}, key) do
    Map.fetch(assigns, key)
  end

  @doc """
  Convenience function to assign a list of values into a driver struct.
  """
  @spec assign(driver :: Driver.t(), key_list :: Keyword.t()) :: Driver.t()
  def assign(%Driver{} = driver, key_list) when is_list(key_list) do
    Enum.reduce(key_list, driver, fn {k, v}, acc -> assign(acc, k, v) end)
  end

  @doc """
  Convenience function to assign a value into a driver struct.
  """
  @spec assign(driver :: Driver.t(), key :: any, value :: any) :: Driver.t()
  def assign(%Driver{assigns: assigns} = driver, key, value) do
    %{driver | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Convenience function to assign a list of new values into a driver struct.

  Only values that do not already exist will be assigned
  """
  @spec assign_new(driver :: Driver.t(), key_list :: Keyword.t()) :: Driver.t()
  def assign_new(%Driver{} = driver, key_list) when is_list(key_list) do
    Enum.reduce(key_list, driver, fn {k, v}, acc -> assign_new(acc, k, v) end)
  end

  @doc """
  Convenience function to assign a new values into a driver struct.

  The value will only be assigned if it does not already exist in the struct.
  """
  @spec assign_new(driver :: Driver.t(), key :: any, value :: any) :: Driver.t()
  def assign_new(%Driver{assigns: assigns} = driver, key, value) do
    %{driver | assigns: Map.put_new(assigns, key, value)}
  end

  @doc """
  Set or clear the busy flag.

  When the busy flag is set, put_script messages will be consolidated until cleared.
  """
  @spec set_busy(driver :: Driver.t(), flag :: boolean) :: Driver.t()
  def set_busy(%Driver{} = driver, flag) when is_boolean(flag) do
    %{driver | busy: flag}
  end

  @doc """
  Send input from the driver.

  Send input from the driver to its ViewPort. `:cursor_pos` and `:cursor_scroll`
  input will be buffered/rate limited according the driver's `:limit_ms` setting.
  """
  @spec send_input(driver :: Driver.t(), input :: ViewPort.Input.t()) :: Driver.t()
  def send_input(%Driver{limit_ms: 0} = drvr, input), do: do_send_input(drvr, input)

  def send_input(
        %Driver{input_limited: true, input_buffer: buffer} = driver,
        {class, _} = input
      ) do
    # Logger.warn( "input_limited #{inspect({input})}" )
    case class do
      :cursor_pos -> %{driver | input_buffer: Map.put(buffer, class, input)}
      :cursor_scroll -> %{driver | input_buffer: Map.put(buffer, class, input)}
      # Everything else is sent right away
      _ -> do_send_input(driver, input)
    end
  end

  def send_input(
        %Driver{limit_ms: limit_ms} = driver,
        {class, _} = input
      ) do
    # Logger.warn( "input #{inspect({input})}" )
    case class do
      :cursor_pos ->
        Process.send_after(self(), @input_limiter, limit_ms)
        do_send_input(%{driver | input_limited: true}, input)

      :cursor_scroll ->
        Process.send_after(self(), @input_limiter, limit_ms)
        do_send_input(%{driver | input_limited: true}, input)

      _ ->
        # Everything else is does not trigger a limit
        do_send_input(driver, input)
    end
  end

  defp do_send_input(
         %Driver{viewport: vp, requested_inputs: requested_inputs} = driver,
         {input_type, _} = input
       ) do
    if Enum.member?(requested_inputs, input_type) do
      case ViewPort.input(vp, input) do
        :ok ->
          :ok

        {:error, :invalid} ->
          Logger.error("""
          #{inspect(driver.module)} attempted send an improperly formatted input message.
          Received: #{inspect(input)}
          """)
      end
    end

    driver
  end

  @doc """
  Send updates to the driver.

  This is used internally when scripts are updated. Some drivers use it to batch updates
  into a single atomic operation. This call is rate limited by limit_ms.
  """

  def request_update(%Driver{update_requested: true} = driver), do: driver
  def request_update(%Driver{update_ready: true} = driver), do: driver

  # no limiter. update right away.
  def request_update(%Driver{limit_ms: 0, pid: pid} = driver) do
    send(pid, @do_update)
    %{driver | update_requested: true}
  end

  def request_update(%Driver{limit_ms: limit_ms, pid: pid} = driver) do
    Process.send_after(pid, @do_update, limit_ms)
    %{driver | update_requested: true}
  end

  # updating doesn't happen until it is marked ready, not gated and not busy
  defp do_update(%Driver{update_requested: false} = driver), do: driver
  defp do_update(%Driver{update_ready: false} = driver), do: driver
  defp do_update(%Driver{gated: true} = driver), do: driver
  defp do_update(%Driver{busy: true} = driver), do: driver

  # perform an actual update
  defp do_update(%Driver{module: module, dirty_ids: ids} = driver) do
    case Kernel.function_exported?(module, :update_scene, 2) do
      true ->
        ids =
          ids
          |> List.flatten()
          |> Enum.uniq()

        case module.update_scene(ids, %{driver | dirty_ids: ids}) do
          {:ok, %Driver{} = driver} -> driver
          other -> raise state_msg("update_scene", other)
        end

      false ->
        driver
    end
    |> Map.put(:update_requested, false)
    |> Map.put(:update_ready, false)
    |> Map.put(:dirty_ids, [])
  end

  # ===========================================================================
  # the using macro for scenes adopting this behavior
  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour Scenic.Driver

      import Scenic.Driver,
        only: [
          get: 2,
          get: 3,
          fetch: 2,
          assign: 2,
          assign: 3,
          assign_new: 2,
          assign_new: 3,
          set_busy: 2,
          send_input: 2
        ]

      @doc false
      def init(_param), do: :ignore
    end

    # quote
  end

  # ===========================================================================
  # calls for starting up a driver

  @doc false
  def child_spec(data) do
    %{
      id: make_ref(),
      start: {__MODULE__, :start_link, [data]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc false
  # internal start_link
  def start_link({vp_info, opts}) do
    # GenServer.start_link(__MODULE__, {vp_info, opts})
    case opts[:name] do
      nil -> GenServer.start_link(__MODULE__, {vp_info, opts})
      name -> GenServer.start_link(__MODULE__, {vp_info, opts}, name: name)
    end
  end

  # --------------------------------------------------------
  @doc false
  def init({vp, _opts} = data) do
    GenServer.cast(vp.pid, {:register_driver, self()})
    {:ok, nil, {:continue, {@init, data}}}
  end

  # ============================================================================
  # terminate

  def terminate(reason, %Driver{module: module} = driver) do
    case Kernel.function_exported?(module, :terminate, 2) do
      true -> module.terminate(reason, driver)
      false -> nil
    end
  end

  def terminate(reason, _state), do: reason

  # --------------------------------------------------------
  @doc false
  def handle_continue({@init, {vp, opts}}, nil) do
    {:ok, module} = Keyword.fetch(opts, :module)

    # create the driver struct
    driver = %Driver{
      viewport: vp,
      module: module,
      pid: self(),
      limit_ms: opts[:limit_ms] || 0
    }

    # start up the scene
    case module.init(driver, Keyword.delete(opts, :module)) do
      {:ok, %Driver{} = driver} ->
        {:noreply, driver}

      {:ok, other} ->
        raise """
        Driver callback init returned an invalid Scenic.Driver struct
        Received: #{inspect(other)}
        """

      {:ok, %Driver{} = state, opt} ->
        {:noreply, state, opt}

      {:ok, other, _opt} ->
        raise """
        Driver callback init returned an invalid Scenic.Driver struct
        Received: #{inspect(other)}
        """

      :ignore ->
        :ignore

      {:stop, reason} ->
        {:stop, reason}
    end
  end

  # --------------------------------------------------------
  @doc false
  def handle_continue(msg, %Driver{module: module, busy: old_busy} = driver) do
    case module.handle_continue(msg, driver) do
      {:noreply, %Driver{busy: new_busy} = driver} ->
        if old_busy && !new_busy, do: send(self(), @not_busy)
        {:noreply, driver}

      {:noreply, state} ->
        raise """
        Driver callback handle_continue must return a driver struct as the state
        Received: #{inspect(state)}
        """

      {:noreply, %Driver{busy: new_busy} = driver, opts} ->
        if old_busy && !new_busy, do: send(self(), @not_busy)
        {:noreply, driver, opts}

      {:noreply, state, _opts} ->
        raise """
        Driver callback handle_continue must return a driver struct as the state
        Received: #{inspect(state)}
        """

      response ->
        response
    end
  end

  # --------------------------------------------------------
  # info
  @doc false

  def handle_info(@do_update, driver), do: handle_do_update(driver)
  def handle_info(@not_busy, driver), do: do_not_busy(driver)
  def handle_info(@input_limiter, driver), do: do_input_limit_expired(driver)
  # def handle_info(@limiter, driver), do: do_limit_expired(driver)
  def handle_info({@put_scripts, ids}, driver), do: do_put_scripts(ids, driver)
  def handle_info({@del_scripts, ids}, driver), do: do_del_scripts(ids, driver)
  def handle_info({@request_input, req}, driver), do: do_input_reqs(req, driver)
  def handle_info(@reset_scene, driver), do: do_reset_scene(driver)
  def handle_info(@gate_start, driver), do: do_gate_start(driver)
  def handle_info(@gate_complete, driver), do: do_gate_complete(driver)
  def handle_info({@clear_color, color}, driver), do: do_clear_color(color, driver)

  # generic handle_info. give the driver a chance to handle it
  def handle_info(msg, %Driver{module: module, busy: old_busy} = driver) do
    case module.handle_info(msg, driver) do
      {:noreply, %Driver{busy: new_busy} = driver} ->
        if old_busy && !new_busy, do: send(self(), @not_busy)
        {:noreply, driver}

      {:noreply, state} ->
        raise """
        Driver callback handle_info must return a driver struct as the state
        Received: #{inspect(state)}
        """

      {:noreply, %Driver{busy: new_busy} = driver, opts} ->
        if old_busy && !new_busy, do: send(self(), @not_busy)
        {:noreply, driver, opts}

      {:noreply, state, _opts} ->
        raise """
        Driver callback handle_info must return a driver struct as the state
        Received: #{inspect(state)}
        """

      response ->
        response
    end
  end

  # --------------------------------------------------------
  # cast
  @doc false
  def handle_cast(msg, %Driver{module: module, busy: old_busy} = driver) do
    case module.handle_cast(msg, driver) do
      {:noreply, %Driver{busy: new_busy} = driver} ->
        if old_busy && !new_busy, do: send(self(), @not_busy)
        {:noreply, driver}

      {:noreply, state} ->
        raise """
        Driver callback handle_cast must return a driver struct as the state
        Received: #{inspect(state)}
        """

      {:noreply, %Driver{busy: new_busy} = driver, opts} ->
        if old_busy && !new_busy, do: send(self(), @not_busy)
        {:noreply, driver, opts}

      {:noreply, state, _opts} ->
        raise """
        Driver callback handle_cast must return a driver struct as the state
        Received: #{inspect(state)}
        """

      response ->
        response
    end
  end

  # --------------------------------------------------------
  @doc false
  def handle_call(msg, from, %Driver{module: module, busy: old_busy} = driver) do
    case module.handle_call(msg, from, driver) do
      {:noreply, %Driver{busy: new_busy} = driver} ->
        if old_busy && !new_busy, do: send(self(), @not_busy)
        {:noreply, driver}

      {:noreply, other} ->
        raise """
        Driver callback handle_call must return a driver struct as the state
        Received: #{inspect(other)}
        """

      {:noreply, %Driver{busy: new_busy} = driver, opts} ->
        if old_busy && !new_busy, do: send(self(), @not_busy)
        {:noreply, driver, opts}

      {:noreply, other, _opts} ->
        raise """
        Driver callback handle_call must return a driver struct as the state
        Received: #{inspect(other)}
        """

      {:reply, reply, %Driver{busy: new_busy} = driver} ->
        if old_busy && !new_busy, do: send(self(), @not_busy)
        {:reply, reply, driver}

      {:reply, _reply, other} ->
        raise """
        Driver callback handle_call must return a driver struct as the state
        Received: #{inspect(other)}
        """

      {:reply, reply, %Driver{busy: new_busy} = driver, opts} ->
        if old_busy && !new_busy, do: send(self(), @not_busy)
        {:reply, reply, driver, opts}

      {:reply, _reply, other, _opts} ->
        raise """
        Driver callback handle_call must return a driver struct as the state
        Received: #{inspect(other)}
        """

      response ->
        response
    end
  end

  # ============================================================================
  # internal handlers

  defp state_msg(name, data) do
    """
    Driver callback '#{name}' must return {:ok, driver}
    The 'driver' field must be a valid %Scenic.Driver{} struct.
    Received: #{inspect(data)}
    """
  end

  defp do_not_busy(%Driver{} = driver) do
    {:noreply, do_update(%{driver | busy: false})}
  end

  defp handle_do_update(%Driver{} = driver) do
    {:noreply, do_update(%{driver | update_ready: true})}
  end

  defp do_put_scripts([], driver), do: {:noreply, driver}

  defp do_put_scripts(ids, %Driver{dirty_ids: dirty_ids} = driver) do
    {:noreply, request_update(%{driver | dirty_ids: [ids | dirty_ids]})}
  end

  defp do_input_limit_expired(
         %Driver{viewport: vp, limit_ms: limit_ms, input_buffer: buffer} = driver
       ) do
    case buffer == %{} do
      true ->
        # no buffered input. End the rate limit.
        {:noreply, %{driver | input_limited: false}}

      false ->
        Process.send_after(self(), @input_limiter, limit_ms)
        Enum.each(buffer, fn {_, input} -> ViewPort.input(vp, input) end)
        {:noreply, %{driver | input_limited: true, input_buffer: %{}}}
    end
  end

  defp do_del_scripts(ids, %Driver{module: module} = driver) do
    case Kernel.function_exported?(module, :del_scripts, 2) do
      true ->
        case module.del_scripts(ids, driver) do
          {:ok, %Driver{} = driver} -> {:noreply, driver}
          other -> raise state_msg("del_scripts", other)
        end

      false ->
        {:noreply, driver}
    end
  end

  defp do_input_reqs(requested_inputs, %Driver{module: module} = driver) do
    # always update the inputs even if the callback isn't defined
    driver = %{driver | requested_inputs: requested_inputs}

    case Kernel.function_exported?(module, :request_input, 2) do
      true ->
        case module.request_input(requested_inputs, driver) do
          {:ok, %Driver{} = driver} -> {:noreply, driver}
          other -> raise state_msg("request_input", other)
        end

      false ->
        {:noreply, driver}
    end
  end

  defp do_reset_scene(%Driver{module: module} = driver) do
    driver =
      case Kernel.function_exported?(module, :reset_scene, 1) do
        true ->
          driver
          |> module.reset_scene()
          |> case do
            {:ok, %Driver{} = driver} -> driver
            other -> raise state_msg("reset", other)
          end

        false ->
          driver
      end
      |> Map.put(:dirty_ids, [@root_id])
      |> Map.put(:gated, false)

    # |> Map.put( :update_requested, false )
    # |> Map.put( :update_ready, false )

    {:noreply, driver}
  end

  defp do_gate_start(%Driver{} = driver) do
    {:noreply, %{driver | gated: true}}
  end

  defp do_gate_complete(%Driver{} = driver) do
    {:noreply, do_update(%{driver | gated: false})}
  end

  defp do_clear_color(color, %Driver{module: module} = driver) do
    color = Color.to_rgba(color)
    driver = %{driver | clear_color: color}

    driver =
      case Kernel.function_exported?(module, :clear_color, 2) do
        true ->
          case module.clear_color(color, driver) do
            {:ok, %Driver{} = driver} -> driver
            other -> raise state_msg("clear_color", other)
          end

        false ->
          driver
      end

    {:noreply, driver}
  end

  # --------------------------------------------------------
  # options validation
  @opts_schema [
    module: [required: true, type: :atom],
    name: [type: :atom]
  ]

  @doc false
  def validate([]), do: {:ok, []}

  def validate(drivers) do
    case Enum.reduce(drivers, [], &do_validate(&1, &2)) do
      opts when is_list(opts) -> {:ok, Enum.reverse(opts)}
      err -> err
    end
  end

  defp do_validate(opts, drivers) do
    core_opts =
      []
      |> put_set(:module, opts[:module])
      |> put_set(:name, opts[:name])

    driver_opts =
      opts
      |> Keyword.delete(:module)
      |> Keyword.delete(:name)

    with {:ok, core} <- NimbleOptions.validate(core_opts, @opts_schema),
         {:ok, opts} <- core[:module].validate_opts(driver_opts) do
      [core ++ opts | drivers]
    else
      {:error, %NimbleOptions.ValidationError{} = error} ->
        raise Exception.message(error)
        # err -> err
    end
  end

  defp put_set(opts, _, nil), do: opts
  defp put_set(opts, key, value), do: Keyword.put(opts, key, value)
end
