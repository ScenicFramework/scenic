#  Created by Boyd Multerer on 2017-11-05.
#  Rewritten: 2018-25-03
#  Rewritten: 2021-18-02
#  Copyright © 2017 - 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.ViewPort.Input do
  @moduledoc """
  The low-level interface for working in input into and out of a `ViewPort`.

  You will typically use the input related functions in `Scenic.Scene`, which
  wrap this module and make them easy to use from a Scene module.

  If you wanted monitor input from some other `GenServer`, or inject input into
  a `ViewPort`, then this is the API to use.

  Input events begin when a driver sends an event to the `ViewPort` it is attached
  to. In order to keep scenes simple, and to reduce the amount of work and data
  transferred when input is created (for example, a moving mouse...), events are
  only sent to any scenes that have indicated that they are listening.

  There are two ways a scene indicates that it is interested in an input event.

  ## Requested Input

  Normally, a scene "requests" input. This will route any keyboard or other
  location independent events to the scene. However, any positional input, such
  as `:cursor_button` will only be received it if is over an item in a graph
  managed by a scene that has the `input: true` style.

  ```elixir
  graph
    |> rect( {20, 40}, t: {10, 10}, id: :rect_in, input: true, fill: :blue )
    |> rect( {20, 40}, t: {10, 50}, id: :rect_other, fill: :blue )
  ```

  In the above example, the scene would only receive :cursor_button events if the
  :rect_in rect is clicked. This is because it is the only rect that has the 
  `input: true` style on it.

  Cursor clicks over the `:rect_other` rect, are not delivered to the scene.

  ## Captured Input

  If you look at the code behind components such as Button or Slider, you will see
  that when the button is clicked, it "captures" the `:cursor_button` input type.

  This causes the caller to receive *all* input events of that type, regardless of
  the `:input` style. This means that even `:cursor_button` events that would be
  otherwise be routed to some other scene are sent *only* to the scene that has
  captured the input. The other scene that has only "requested" the event does
  not receive it.

  If multiple scenes have captured an input type, the most recent call wins. When
  scene releases the capture, the event type remains captured but is now sent to
  the second scene that had been overridden.

  ## Sending Input

  When a driver (or any other caller, but it is typically a `Scenic.Driver`)
  wants to send an input event to the ViewPort, it creates a message and sends
  it to it's ViewPort with the `Scenic.ViewPort.Input.send/2` function.

  Drivers have no knowledge of the running scenes. The `ViewPort` takes care of
  that routing.

  Input events are validated against `Scenic.ViewPort.Input.validate/1` function.
  """

  alias Scenic.Math
  alias Scenic.ViewPort
  alias Scenic.Driver.KeyMap

  # import IEx

  @type t ::
          {:codepoint, {codepoint :: String.t(), mods :: KeyMap.mod_keys()}}
          | {:key, {key :: atom, value :: integer, mods :: KeyMap.mod_keys()}}
          | {:cursor_button,
             {button :: atom, value :: integer, mods :: KeyMap.mod_keys(),
              position :: Math.point()}}
          | {:cursor_scroll, {offset :: Math.point(), position :: Math.point()}}
          | {:cursor_pos, position :: Math.point()}
          | {:viewport, {:enter | :exit | :reshape, xy :: Math.point()}}
          | {:relative, vector :: Math.point()}
          | {:led, {id :: atom, value :: integer}}
          | {:switch, {id :: atom, value :: integer}}

  @type class ::
          :cursor_button
          | :cursor_scroll
          | :cursor_pos
          | :codepoint
          | :key
          | :viewport
          | :relative
          | :led
          | :switch

  @type positional ::
          :cursor_button
          | :cursor_scroll
          | :cursor_pos
          | :relative

  @spec valid_inputs() :: [class]
  defp valid_inputs() do
    [
      :cursor_button,
      :cursor_scroll,
      :cursor_pos,
      :codepoint,
      :key,
      :viewport,
      :relative,
      :led,
      :switch
    ]
  end

  @spec positional_inputs() :: [positional()]
  @doc false
  def positional_inputs() do
    [
      :cursor_button,
      :cursor_scroll,
      :cursor_pos,
      :relative
    ]
  end

  # --------------------------------------------------------
  @doc """
  Capture one or more types of input.

  Returns `:ok` or an error

  ### Options
  * `:pid` - Send input to the specified pid instead of the caller process.
  """
  @spec capture(
          viewport :: ViewPort.t(),
          inputs :: ViewPort.Input.class() | [ViewPort.Input.class()],
          opts :: Keyword.t()
        ) :: :ok
  def capture(viewport, inputs, opts \\ [])
  def capture(viewport, input, opts) when is_atom(input), do: capture(viewport, [input], opts)

  def capture(%ViewPort{pid: pid}, inputs, opts) when is_list(inputs) and is_list(opts) do
    from =
      case Keyword.fetch(opts, :pid) do
        {:ok, pid} -> pid
        _ -> self()
      end

    case validate_types(inputs) do
      {:ok, inputs} ->
        GenServer.cast(pid, {:_capture_input, inputs, from})

      err ->
        err
    end
  end

  # --------------------------------------------------------
  @doc """
  Release the captured inputs from the calling process.

  ### Options
  * `:pid` - Release from the specified pid instead of the caller process.
  """
  @spec release(
          viewport :: ViewPort.t(),
          input_class :: ViewPort.Input.class() | [ViewPort.Input.class()] | :all,
          opts :: Keyword.t()
        ) :: :ok
  def release(viewport, inputs \\ :all, opts \\ [])
  def release(viewport, input, opts) when is_atom(input), do: release(viewport, [input], opts)

  def release(%ViewPort{pid: pid}, inputs, opts) when is_list(inputs) and is_list(opts) do
    from =
      case Keyword.fetch(opts, :pid) do
        {:ok, pid} -> pid
        _ -> self()
      end

    GenServer.cast(pid, {:_release_input, inputs, from})
  end

  # --------------------------------------------------------
  @doc """
  Release the captured inputs from ALL processes
  """
  @spec release!(
          viewport :: ViewPort.t(),
          input_class :: ViewPort.Input.class() | [ViewPort.Input.class()] | :all
        ) :: :ok
  def release!(viewport, inputs)
  def release!(viewport, input) when is_atom(input), do: release!(viewport, [input])

  def release!(%ViewPort{pid: pid}, inputs) when is_list(inputs) do
    GenServer.cast(pid, {:_release_input!, inputs})
  end

  # --------------------------------------------------------
  @doc """
  Retrieve a list of input captured by the caller.

  Returns: { :ok, list }
  """
  @spec fetch_captures(
          viewport :: ViewPort.t(),
          captured_by :: nil | pid
        ) :: {:ok, list}
  def fetch_captures(viewport, captured_by \\ nil)
  def fetch_captures(viewport, nil), do: fetch_captures(viewport, self())

  def fetch_captures(%ViewPort{pid: pid}, captured_by) when is_pid(captured_by) do
    GenServer.call(pid, {:_fetch_input_captures, captured_by})
  end

  # --------------------------------------------------------
  @doc """
  Retrieve a list of input captured by all processes.

  Returns: { :ok, list }
  """
  @spec fetch_captures!(viewport :: ViewPort.t()) :: {:ok, list}
  def fetch_captures!(viewport)

  def fetch_captures!(%ViewPort{pid: pid}) do
    GenServer.call(pid, :_fetch_input_captures!)
  end

  # def request()
  # --------------------------------------------------------
  @doc """
  Request one or more types of input.

  Returns :ok or an error

  ### Options
  * `:pid` - Send input to the specified pid instead of the caller process.
  """
  @spec request(
          viewport :: ViewPort.t(),
          inputs :: ViewPort.Input.class() | [ViewPort.Input.class()],
          opts :: Keyword.t()
        ) :: :ok
  def request(viewport, inputs, opts \\ [])
  def request(viewport, input, opts) when is_atom(input), do: request(viewport, [input], opts)

  def request(%ViewPort{pid: pid}, inputs, opts) when is_list(inputs) and is_list(opts) do
    from =
      case Keyword.fetch(opts, :pid) do
        {:ok, pid} -> pid
        _ -> self()
      end

    case validate_types(inputs) do
      {:ok, inputs} -> GenServer.cast(pid, {:_request_input, inputs, from})
      err -> err
    end
  end

  # --------------------------------------------------------
  @doc """
  Unrequest the captured inputs from the calling process.

  ### Options
  * `:pid` - Unrequest from the specified pid instead of the caller process.
  """
  @spec unrequest(
          viewport :: ViewPort.t(),
          input_class :: ViewPort.Input.class() | [ViewPort.Input.class()] | :all,
          opts :: Keyword.t()
        ) :: :ok
  def unrequest(viewport, inputs \\ :all, opts \\ [])
  def unrequest(viewport, input, opts) when is_atom(input), do: unrequest(viewport, [input], opts)

  def unrequest(%ViewPort{pid: pid}, inputs, opts) when is_list(inputs) and is_list(opts) do
    from =
      case Keyword.fetch(opts, :pid) do
        {:ok, pid} -> pid
        _ -> self()
      end

    GenServer.cast(pid, {:_unrequest_input, inputs, from})
  end

  # --------------------------------------------------------
  @doc """
  Retrieve a list of input requested by the caller or the process requested_by.

  Returns: { :ok, inputs }
  """
  @spec fetch_requests(
          viewport :: ViewPort.t(),
          requested_by :: nil | pid
        ) :: {:ok, list}
  def fetch_requests(viewport, requested_by \\ nil)
  def fetch_requests(viewport, nil), do: fetch_requests(viewport, self())

  def fetch_requests(%ViewPort{pid: pid}, requested_by) when is_pid(requested_by) do
    GenServer.call(pid, {:_fetch_input_requests, requested_by})
  end

  # --------------------------------------------------------
  @doc """
  Retrieve a list of input requested by all processes.

  Returns: { :ok, inputs }
  """
  @spec fetch_requests!(viewport :: ViewPort.t()) :: {:ok, list}
  def fetch_requests!(viewport)

  def fetch_requests!(%ViewPort{pid: pid}) do
    GenServer.call(pid, :_fetch_input_requests!)
  end

  # --------------------------------------------------------
  @doc """
  Send raw input to a viewport.

  This is used primarily by drivers to send raw user input to the viewport. Having said that,
  nothing stops a scene or any other process from using it to send input into the system.
  There are a few cases where that is useful.

  See the [input types](Scenic.ViewPort.Input.html#t:t/0) for the input formats you can send.
  """
  @spec send(
          viewport :: ViewPort.t(),
          input :: ViewPort.Input.t()
        ) :: :ok | {:error, atom}
  def send(%ViewPort{pid: pid}, input) do
    # IO.inspect(input, label: "Raw Send")

    case validate(input) do
      :ok -> GenServer.cast(pid, {:input, input})
      err -> err
    end
  end

  # --------------------------------------------------------
  defp validate_types(input_types) when is_list(input_types) do
    Enum.find_value(input_types, :ok, fn type ->
      case Enum.member?(valid_inputs(), type) do
        true ->
          # is ok. don't do anything
          nil

        false ->
          # this type is not in the valid types list. return it.
          type
      end
    end)
    |> case do
      :ok ->
        {:ok, Enum.uniq(input_types)}

      bad_value ->
        {:error, :invalid, bad_value}
    end
  end

  # --------------------------------------------------------
  @doc """
  Validate an input message.

  Returns `:ok` if the message is valid.

  Returns `{:error, :invalid}` if the message is not valid.
  """
  @spec validate(input :: t()) :: :ok | {:error, :invalid}

  def validate({:codepoint, {codepoint, mods}})
      when is_bitstring(codepoint) and is_list(mods),
      do: :ok

  def validate({:key, {key, action, mods}})
      when is_atom(key) and is_integer(action) and is_list(mods),
      do: :ok

  def validate({:cursor_button, {btn, action, mods, {x, y}}})
      when is_atom(btn) and is_integer(action) and is_list(mods) and is_number(x) and is_number(y),
      do: :ok

  def validate({:cursor_scroll, {{ox, oy}, {px, py}}})
      when is_number(ox) and is_number(oy) and is_number(px) and is_number(py),
      do: :ok

  def validate({:cursor_pos, {x, y}}) when is_number(x) and is_number(y), do: :ok

  def validate({:viewport, {:enter, {x, y}}}) when is_number(x) and is_number(y), do: :ok
  def validate({:viewport, {:exit, {x, y}}}) when is_number(x) and is_number(y), do: :ok
  def validate({:viewport, {:reshape, {w, h}}}) when is_number(w) and is_number(h), do: :ok

  def validate({:relative, {x, y}}) when is_number(x) and is_number(y), do: :ok
  def validate({:led, {id, value}}) when is_atom(id) and is_integer(value), do: :ok
  def validate({:switch, {id, value}}) when is_atom(id) and is_integer(value), do: :ok

  def validate(_), do: {:error, :invalid}
end
