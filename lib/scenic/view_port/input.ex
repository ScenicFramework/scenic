
#  Created by Boyd Multerer on 2017-11-05.
#  Rewritten: 2018-25-03
#  Rewritten: 2021-18-02
#  Copyright © 2017 - 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.ViewPort.Input do
  alias Scenic.Math
  alias Scenic.ViewPort

  # import IEx


  @type t ::
          {:codepoint, {codepoint :: String.t(), mods :: integer}}
          | {:key, {key :: String.t(), :press | :release | :repeat, mods :: integer}}
          | {:cursor_button, {button::0|1|2, action:: :press | :release, mods :: integer,
              position :: Math.point()}}
          | {:cursor_scroll, {offset :: Math.point(), position :: Math.point()}}
          | {:cursor_pos, position :: Math.point()}
          | {:viewport, {:enter, position :: Math.point()}}
          | {:viewport, {:exit, position :: Math.point()}}
          | {:viewport, {:reshape, size :: Math.point()}}

  @type class ::
    :cursor_button |
    :cursor_scroll |
    :cursor_pos |
    :codepoint |
    :key |
    :viewport

  @spec valid_inputs() :: [class]
  def valid_inputs() do
    [
      :cursor_button,
      :cursor_scroll,
      :cursor_pos,
      :codepoint,
      :key,
      :viewport
    ]
  end

  # --------------------------------------------------------
  @doc """
  Capture one or more types of input.

  returns :ok or an error
  """
  @spec capture(
          viewport :: ViewPort.t(),
          inputs :: ViewPort.Input.class() | list(ViewPort.Input.class()),
          from :: nil | pid
        ) :: :ok
  def capture( viewport, inputs, from \\ nil )
  def capture( viewport, input, nil ), do: capture( viewport, input, self() )
  def capture( viewport, input, from ) when is_atom(input), do: capture( viewport, [input], from )
  def capture( %ViewPort{pid: pid}, inputs, from ) when is_list( inputs ) and is_pid(from) do
    case validate_types( inputs ) do
      {:ok, inputs} ->
        GenServer.cast(pid, {:_capture_input, inputs, from})

      err ->
        err
    end
  end


  # --------------------------------------------------------
  @doc """
  release the captured inputs from the calling process.
  """
  @spec release(
          viewport :: ViewPort.t(),
          input_class :: ViewPort.Input.class() | list(ViewPort.Input.class()) | :all,
          from :: nil | pid
 ) :: :ok
  def release( viewport, inputs \\ :all, from \\ nil )
  def release( viewport, input, nil ), do: release( viewport, input, self() )
  def release( viewport, input, from ) when is_atom(input), do: release( viewport, [input], from )
  def release( %ViewPort{pid: pid}, inputs, from ) when is_list(inputs) and is_pid(from) do
    GenServer.cast( pid, {:_release_input, inputs, from} )
  end


  # --------------------------------------------------------
  @doc """
  release the captured inputs from ALL processes
  """
  @spec release!(
          viewport :: ViewPort.t(),
          input_class :: ViewPort.Input.class() | list(ViewPort.Input.class()) | :all
 ) :: :ok
  def release!( viewport, inputs )
  def release!( viewport, input ) when is_atom(input), do: release!( viewport, [input] )
  def release!( %ViewPort{pid: pid}, inputs ) when is_list(inputs) do
    GenServer.cast( pid, {:_release_input!, inputs} )
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
  def fetch_captures( viewport, captured_by \\ nil )
  def fetch_captures( viewport, nil ), do: fetch_captures( viewport, self() )
  def fetch_captures( %ViewPort{pid: pid}, captured_by ) when is_pid(captured_by) do
    GenServer.call( pid, {:_fetch_input_captures, captured_by} )
  end



  # --------------------------------------------------------
  @doc """
  Retrieve a list of input captured by all processes.

  Returns: { :ok, list }
  """
  @spec fetch_captures!(
          viewport :: ViewPort.t()
        ) :: {:ok, list}
  def fetch_captures!( viewport )
  def fetch_captures!( %ViewPort{pid: pid} ) do
    GenServer.call( pid, :_fetch_input_captures! )
  end










  # def request()
  # --------------------------------------------------------
  @doc """
  Request one or more types of input.

  returns :ok or an error
  """
  @spec request(
          viewport :: ViewPort.t(),
          inputs :: ViewPort.Input.class() | list(ViewPort.Input.class()),
          from :: nil | pid
        ) :: :ok
  def request( viewport, inputs, from \\ nil )
  def request( viewport, input, nil ), do: request( viewport, input, self() )
  def request( viewport, input, from ) when is_atom(input), do: request( viewport, [input], from )
  def request( %ViewPort{pid: pid}, inputs, from ) when is_list( inputs ) and is_pid(from) do
    case validate_types( inputs ) do
      {:ok, inputs} ->
        GenServer.cast(pid, {:_request_input, inputs, from})

      err ->
        err
    end
  end


  # --------------------------------------------------------
  @doc """
  unrequest the captured inputs from the calling process.
  """
  @spec unrequest(
          viewport :: ViewPort.t(),
          input_class :: ViewPort.Input.class() | list(ViewPort.Input.class()) | :all,
          from :: nil | pid
 ) :: :ok
  def unrequest( viewport, inputs \\ :all, from \\ nil )
  def unrequest( viewport, input, nil ), do: unrequest( viewport, input, self() )
  def unrequest( viewport, input, from ) when is_atom(input), do: unrequest( viewport, [input], from )
  def unrequest( %ViewPort{pid: pid}, inputs, from ) when is_list(inputs) and is_pid(from) do
    GenServer.cast( pid, {:_unrequest_input, inputs, from} )
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
  def fetch_requests( viewport, requested_by \\ nil )
  def fetch_requests( viewport, nil ), do: fetch_requests( viewport, self() )
  def fetch_requests( %ViewPort{pid: pid}, requested_by ) when is_pid(requested_by) do
    GenServer.call( pid, {:_fetch_input_requests, requested_by} )
  end


  # --------------------------------------------------------
  @doc """
  Retrieve a list of input requested by all processes.

  Returns: { :ok, inputs }
  """
  @spec fetch_requests!(
          viewport :: ViewPort.t()
        ) :: {:ok, list}
  def fetch_requests!( viewport )
  def fetch_requests!( %ViewPort{pid: pid} ) do
    GenServer.call( pid, :_fetch_input_requests! )
  end




  # --------------------------------------------------------
  @doc """
  Send raw input to a viewport.

  This is used primarily by drivers to send raw user input to the viewport. Having said that,
  nothing stops a scene from using it to send input into the system. There are a few cases
  where that is useful.

  See the [input docs](Scenic.ViewPort.Input.html#t:t/0) for the input formats you can send.
  """
  @spec send(
          viewport :: ViewPort.t,
          input :: ViewPort.Input.t()
        ) :: :ok
  def send( %ViewPort{pid: pid}, input ) do
    case validate_input( input ) do
      :ok -> GenServer.cast(pid, {:input, input})
      err -> err
    end
  end


  # --------------------------------------------------------
  defp validate_types( input_types ) when is_list(input_types) do
    Enum.find_value(input_types, :ok, fn(type) ->
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
        { :error, :invalid, bad_value }
    end
  end

  # --------------------------------------------------------
  defp validate_input( input )
  defp validate_input( {:codepoint, {codepoint, mods}} ) when is_bitstring(codepoint) and is_integer(mods), do: :ok
  defp validate_input( {:key, {key, :press, mods}} ) when is_bitstring(key) and is_integer(mods), do: :ok
  defp validate_input( {:key, {key, :release, mods}} ) when is_bitstring(key) and is_integer(mods), do: :ok
  defp validate_input( {:key, {key, :repeat, mods}} ) when is_bitstring(key) and is_integer(mods), do: :ok


  defp validate_input( {:cursor_button, {btn, :press, mods, {x,y}}} ) when
    is_integer(btn) and is_integer(mods) and is_number(x) and is_number(y), do: :ok
  defp validate_input( {:cursor_button, {btn, :release, mods, {x,y}}} ) when
    is_integer(btn) and is_integer(mods) and is_number(x) and is_number(y), do: :ok



  # defp validate_input( {:cursor, {:scroll, {ox,oy}, {px,py}}} )
  # when is_integer(ox) and is_integer(oy) and
  # is_integer(px) and is_integer(py), do: :ok

  defp validate_input( {:cursor_pos, {x,y}} ) when is_number(x) and is_number(y), do: :ok

  defp validate_input( {:viewport, {:enter, {x,y}}} ) when is_number(x) and is_number(y), do: :ok
  defp validate_input( {:viewport, {:exit, {x,y}}} ) when is_number(x) and is_number(y), do: :ok
  defp validate_input( {:viewport, {:reshape, {w,h}}} ) when is_number(w) and is_number(h), do: :ok

  defp validate_input( _ ), do: { :error, :invalid }

end
