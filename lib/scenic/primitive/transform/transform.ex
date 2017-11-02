#
#  Created by Boyd Multerer on 10/02/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# generic code for the transform styles. Not intended to be used directly

defmodule Scenic.Primitive.Transform do
  alias Scenic.Math.MatrixBin, as: Matrix
  alias Scenic.Math.Vector

  @callback info() :: bitstring
  @callback verify( any ) :: boolean
  @callback serialize( any ) :: binary
  @callback deserialize( binary ) :: any

  @identity   Matrix.identity()

#  defstruct pin: nil, matrix: nil, rotate: nil, scale: nil, translate: nil

  #===========================================================================
#  defmacro __using__([type_code: type_code]) when is_integer(type_code) do
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Primitive.Transform

      def verify!( data ) do
        case verify(data) do
          true -> data
          false -> raise info()
        end
      end

    end # quote
  end # defmacro


  #============================================================================
  # transform helper functions

  #--------------------------------------------------------
  def calculate_local( txs )

  def calculate_local( nil ), do: nil
  def calculate_local( txs ) when (txs == %{}), do: nil
  
  def calculate_local( %{pin: pin} = txs ) do
  # look for case where only the pin is set
    case Enum.count(txs) do
      1 -> nil
      _ -> do_calculate_local( txs )
    end
  end
  def calculate_local( txs ), do: do_calculate_local( txs )
  
  defp do_calculate_local( txs ) do
    # start with identity - which is like multiplying by 1
    @identity
    |> multiply_partial( :matrix, txs[:matrix] )
    |> multiply_partial( :translate, txs[:translate] )
    |> rotate_and_scale( txs )
  end

  #--------------------------------------------------------
  defp multiply_partial(mx, type, value)

  defp multiply_partial(mx, _, nil), do: mx

  defp multiply_partial(mx, :pin, point),       do: Matrix.translate( mx, point )
  defp multiply_partial(mx, :scale, pct),       do: Matrix.scale( mx, pct )
  defp multiply_partial(mx, :rotate, rot),      do: Matrix.rotate( mx, rot )
  defp multiply_partial(mx, :translate, trns),  do: Matrix.translate(mx, trns)
  defp multiply_partial(mx, :matrix, dev_mx),   do: Matrix.mul( mx, dev_mx )
  defp multiply_partial(mx, :inv_pin, point) do
    Matrix.translate( mx, Vector.invert( point ) )
  end

  #--------------------------------------------------------
  defp rotate_and_scale( mx, txs ) do
    # don't do any work if neight rotate nor scale are set
    # don't need to translate twice for no reason
    case txs[:rotate] || txs[:scale] do
      nil -> mx
      _   ->
        mx
        |> multiply_partial( :pin, txs[:pin] )
        |> multiply_partial( :rotate, txs[:rotate] )
        |> multiply_partial( :scale, txs[:scale] )
        |> multiply_partial( :inv_pin, txs[:pin] )
    end
  end



end