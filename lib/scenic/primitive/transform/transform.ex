#
#  Created by Boyd Multerer on 2017-10-02.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform do
  @moduledoc """
  Change the position, rotation, scale and more of a primitive.

  Unlike html, which uses auto-layout to position items on the screen, Scenic moves primitives around using matrix transforms. This is common in video games and provides powerful control of your primitives.

  A [matrix](https://en.wikipedia.org/wiki/Matrix_(mathematics)) is an array of numbers that can be used to change the positions, rotations, scale and more of locations.

  **Don’t worry!** You will not need to look at any matrices unless you want to get fancy. In Scenic, you will rarely (if ever) create matrices on your own (you can if you know what you are doing!), and will instead use the transform helpers.

  Multiple transforms can be applied to any primitive. Transforms combine down the graph to create a very flexible way to manage your scene.

  There are a fixed set of transform helpers that create matrices for you.

  * [`Matrix`](Scenic.Primitive.Transform.Matrix.html) hand specify a matrix.
  * [`Pin`](Scenic.Primitive.Transform.Pin.html) set a pin to rotate or scale around. Most primitives define a sensible default pin.
  * [`Rotate`](Scenic.Primitive.Transform.Rotate.html) rotate around the pin.
  * [`Scale`](Scenic.Primitive.Transform.Scale.html) scale larger or smaller. Centered around the pin.
  * [`Translate`](Scenic.Primitive.Transform.Translate.html) move/translate horizontally and veritcally.

  ### Specifying Transforms

  You apply transforms to a primitive the same way you specify styles.

      graph =
        Graph.build
        |> circle( 100, fill: {:color, :green}, translate: {200, 200} )
        |> ellipse( {40, 60, fill: {:color, :red}, rotate: 0.4, translate: {100, 100} )

  Don't worry about the order you apply transforms to a single object. Scenic will multiply them together in the correct way when it comes time to render them.
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

      @doc false
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

  # ===========================================================================
  @doc false
  def verify!(tx_key, tx_data) do
    case Map.get(@style_name_map, tx_key) do
      nil -> raise FormatError, message: "Unknown transform", module: tx_key, data: tx_data
      module -> module.verify!(tx_data)
    end
  end

  # ============================================================================
  # transform helper functions

  # --------------------------------------------------------
  @doc """
  Given a Map describing the transforms on a primitive, calculate the combined matrix
  that should be applied.

  This is trickier than just multiplying them together. Rotations, translations and scale,
  need to be done in the right order, which is why this function is provided.

  You will not normally need to use this function. It is used internally by the input system.
  """

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
