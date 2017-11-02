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

  #--------------------------------------------------------
  def info(), do: "Scenic.Primitive.Transform is not meant to be used directly."

  #--------------------------------------------------------
  def verify(_), do: false


#  #===========================================================================
#  def get(transform_map, transform_type)
#
#  def get(txs, :pin) do
#    Map.get(txs, :pin)
#  end
#
#  def get(txs, :matrix) do
#    Map.get(txs, :matrix)
#  end
#
#  def get(txs, :rotate) do
#    Map.get(txs, :rotate)
#  end
#
#  def get(txs, :scale) do
#    Map.get(txs, :scale)
#  end
#
#  def get(txs, :translate) do
#    Map.get(txs, :translate)
#  end
#
#  def get(_, type) do
#    raise "Attempted to get a transform of type #{inspect(type)}.\n" <>
#      "The only allowed transform types are :pin, :matrix, :rotate, :scale, and :translate"
#  end

  #===========================================================================
#  def put(transform_map, transform_type, data)
#
#  def put(txs, type, nil) do
#    Map.delete(txs, type)
#  end
#
#  def put(txs, :pin, data) do
#    Scenic.Primitive.Style.Transform.Pin.verify!(data)
#    Map.put(txs, :pin, data)
#  end
#
#  def put(txs, :matrix, data) do
#    Scenic.Primitive.Style.Transform.Matrix.verify!(data)
#    Map.put(txs, :matrix, data)
#  end
#
#  def put(txs, :rotate, data) do
#    Scenic.Primitive.Style.Transform.Rotate.verify!(data)
#    Map.put(txs, :rotate, data)
#  end
#
#  def put(txs, :scale, data) do
#    Scenic.Primitive.Style.Transform.Scale.verify!(data)
#    Map.put(txs, :scale, data)
#  end
#
#  def put(txs, :translate, data) do
#    Scenic.Primitive.Style.Transform.Translate.verify!(data)
#    Map.put(txs, :translate, data)
#  end
#
#  def put(_, type, _) do
#    raise "Attempted to put a transform of type #{inspect(type)}.\n" <>
#      "The only allowed transform types are :pin, :matrix, :rotate, :scale, and :translate"
#  end




  #============================================================================
  # transform helper functions

  def calculate_local( txs )

  def calculate_local( nil ), do: nil
  def calculate_local( txs ) when (txs == %{}), do: nil
  
  def calculate_local( txs ) do
    # start with identity - which is like multiplying by 1
    @identity
    |> multiply_partial( :matrix, txs[:matrix] )
    |> multiply_partial( :translate, txs[:translate] )
    |> rotate_and_scale( txs )
  end

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


  #============================================================================
  # calculate full matrix based on a stack of matrixes up the graph#

  alias Scenic.Graph
  alias Scenic.Primitive

  def calc_final_matrix(graph, primitive) do
    gather_matrix_list(graph, primitive)
    |> Matrix.mul()
  end

  def gather_matrix_list(graph, primitive, list \\ [])
  def gather_matrix_list(_, nil, list), do: list
  def gather_matrix_list(graph, primitive, list) do
    parent = Graph.get(graph, Primitive.get_parent_uid(primitive))

    Primitive.get_transforms( primitive )
    |> calculate_local()
    |> case do
      nil -> gather_matrix_list(graph, parent, list)
      mx  -> gather_matrix_list(graph, parent, [ mx | list])
    end
  end
  

end