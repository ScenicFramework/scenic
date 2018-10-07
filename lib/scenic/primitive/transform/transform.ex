#
#  Created by Boyd Multerer on 10/02/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform do
  @moduledoc """
  Generic code for the transform styles.
  Not intended to be used directly
  """
  alias Scenic.Math.Matrix
  alias Scenic.Math.Vector2
  alias Scenic.Primitive.Transform

  @callback info(data :: any) :: bitstring
  @callback verify(any) :: boolean

  # ===========================================================================
  defmodule FormatError do
    @moduledoc false

    defexception message: nil, module: nil, data: nil
  end

  @style_name_map %{
    :pin => Transform.Pin,
    :scale => Transform.Scale,
    :rotate => Transform.Rotate,
    :translate => Transform.Translate,
    :matrix => Transform.Matrix
  }

  # ===========================================================================
  #  defmacro __using__([type_code: type_code]) when is_integer(type_code) do
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Primitive.Transform

      def verify!(data) do
        case verify(data) do
          true ->
            data

          false ->
            raise FormatError, message: info(data), module: __MODULE__, data: data
        end
      end
    end

    # quote
  end

  # defmacro

  # ===========================================================================
  def verify!(tx_key, tx_data) do
    case Map.get(@style_name_map, tx_key) do
      nil -> raise FormatError, message: "Unknown transform", module: tx_key, data: tx_data
      module -> module.verify!(tx_data)
    end
  end

  # ============================================================================
  # transform helper functions

  # --------------------------------------------------------
  def calculate_local(txs)

  def calculate_local(nil), do: nil
  def calculate_local(txs) when txs == %{}, do: nil

  def calculate_local(%{pin: _} = txs) do
    # look for case where only the pin is set
    case Enum.count(txs) do
      1 -> nil
      _ -> do_calculate_local(txs)
    end
  end

  def calculate_local(txs), do: do_calculate_local(txs)

  defp do_calculate_local(txs) do
    # start with identity - which is like multiplying by 1
    Matrix.identity()
    |> multiply_partial(:matrix, txs[:matrix])
    |> multiply_partial(:translate, txs[:translate])
    |> rotate_and_scale(txs)
  end

  # --------------------------------------------------------
  defp multiply_partial(mx, type, value)

  defp multiply_partial(mx, _, nil), do: mx

  defp multiply_partial(mx, :pin, point), do: Matrix.translate(mx, point)
  defp multiply_partial(mx, :scale, pct), do: Matrix.scale(mx, pct)
  defp multiply_partial(mx, :rotate, rot), do: Matrix.rotate(mx, rot)
  defp multiply_partial(mx, :translate, trns), do: Matrix.translate(mx, trns)
  defp multiply_partial(mx, :matrix, dev_mx), do: Matrix.mul(mx, dev_mx)

  defp multiply_partial(mx, :inv_pin, point) do
    Matrix.translate(mx, Vector2.invert(point))
  end

  # --------------------------------------------------------
  defp rotate_and_scale(mx, txs) do
    # don't do any work if neight rotate nor scale are set
    # don't need to translate twice for no reason
    case txs[:rotate] || txs[:scale] do
      nil ->
        mx

      _ ->
        mx
        |> multiply_partial(:pin, txs[:pin])
        |> multiply_partial(:rotate, txs[:rotate])
        |> multiply_partial(:scale, txs[:scale])
        |> multiply_partial(:inv_pin, txs[:pin])
    end
  end
end
