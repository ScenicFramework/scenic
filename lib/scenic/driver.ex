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
  set of well-known messages. It is up to the drivers to react to and process
  them.

  | Message | Description |
  |---|---|
  | `{:request_input, keys}` | The ViewPort is requesting user inputs from the `keys` list |
  | `:reset` | The `ViewPort` context has been reset. The driver can clean up all scripts and cached media |
  | `{:put_scripts, ids}` | The scripts identified by `ids` have been update and should be processed |
  | `{:del_script, id}` | The script identified by `id` has been deleted and can be cleaned up |
  | `:gate_start` | Start a script gate. Scripts should be processed, but not drawn until the gate is complete |
  | `:gate_complete` | The gate is complete. This should trigger a redraw |


  ## Handling Scripts

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
              vp_info :: Scenic.ViewPort.t(),
              opts :: Keyword.t()
            ) :: {:ok, any}

  # ===========================================================================
  defmodule Error do
    defexception message: nil
  end

  # ===========================================================================
  # the using macro for scenes adopting this behavior
  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour Scenic.Driver

      def validate_opts(opts), do: {:ok, opts}

      def init({vp_info, opts}) do
        GenServer.cast(vp_info.pid, {:register_driver, self()})
        {:ok, nil, {:continue, {:__init__, vp_info, opts}}}
      end

      def build_assets(_src_dir), do: :ok

      def start_link({vp_info, opts}) do
        opts = Keyword.delete(opts, :module)

        case opts[:name] do
          nil -> GenServer.start_link(__MODULE__, {vp_info, opts})
          name -> GenServer.start_link(__MODULE__, {vp_info, opts}, name: name)
        end
      end

      def handle_continue({:__init__, vp_info, opts}, nil) do
        assets = opts[:assets]

        opts =
          opts
          |> Keyword.delete(:module)
          |> Keyword.delete(:name)

        {:ok, state} = init(vp_info, opts)
        {:noreply, state}
      end

      # --------------------------------------------------------
      defoverridable validate_opts: 1,
                     handle_continue: 2,
                     build_assets: 1
    end

    # quote
  end

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
