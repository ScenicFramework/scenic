#
#  Created by Boyd Multerer on 2017-10-02.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Transform do
  @moduledoc """
  Change the position, rotation, scale and more of a primitive.

  Unlike html, which uses auto-layout to position items on the screen, Scenic moves primitives around using matrix transforms. This is common in video games and provides powerful control of your primitives.

  A [matrix](https://en.wikipedia.org/wiki/Matrix_(mathematics)) is an array of numbers that can be used to change the positions, rotations, scale and more of locations.

  **Don't worry!** You will not need to look at any matrices unless you want to get fancy. In Scenic, you will rarely (if ever) create matrices on your own (you can if you know what you are doing!), and will instead use the transform helpers.

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

  @callback validate(data :: any) :: {:ok, data :: any} | {:error, String.t()}

  # ===========================================================================

  @opts_map %{
    :pin => Transform.Pin,
    :scale => Transform.Scale,
    :rotate => Transform.Rotate,
    :translate => Transform.Translate,
    :matrix => Transform.Matrix,
    :s => Transform.Scale,
    :r => Transform.Rotate,
    :t => Transform.Translate
  }

  @opts_schema [
    translate: [type: {:custom, Transform.Translate, :validate, []}],
    scale: [type: {:custom, Transform.Scale, :validate, []}],
    rotate: [type: {:custom, Transform.Rotate, :validate, []}],
    pin: [type: {:custom, Transform.Pin, :validate, []}],
    matrix: [type: {:custom, Transform.Matrix, :validate, []}],
    t: [rename_to: :translate],
    s: [rename_to: :scale],
    r: [rename_to: :rotate]
  ]

  @primitive_transforms [
    :pin,
    :scale,
    :rotate,
    :translate,
    :matrix
  ]

  def opts_map(), do: @opts_map
  def opts_schema(), do: @opts_schema

  # ===========================================================================
  #  defmacro __using__([type_code: type_code]) when is_integer(type_code) do
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Primitive.Transform
    end
  end

  def valid(), do: @primitive_transforms

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
    # don't do any work if neither otate nor scale are set
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
