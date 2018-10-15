#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint do
  @moduledoc """
  Paint is used to "fill" the area of primitives.

  When you apply the `:fill` style to a primitive, you must supply valid
  paint data.

  There are five types of paint.
  * [`:color`](Scenic.Primitive.Style.Paint.Color.html) - Fill with a solid color. This is the most common and has shortcuts.
  * [`:image`](Scenic.Primitive.Style.Paint.Image.html) - Fill with an image from the cache.
  * [`:box_gradient`](Scenic.Primitive.Style.Paint.BoxGradient.html) - Fill with a box gradient.
  * [`:linear_gradient`](Scenic.Primitive.Style.Paint.LinearGradient.html) - Fill with a linear gradient.
  * [`:radial_gradient`](Scenic.Primitive.Style.Paint.RadialGradient.html) - Fill with a radial gradient.

  See the documentation for each type for details.

  ## Color Shortcut

  Filling with a color is so common, you can just declare any valid color
  in a fill, and it will figure out the right paint to use.

  Examples:

      graph
      |> rect({100,200}, fill: :blue)
      |> rect({60,120}, fill: {:blue, 128})
      |> rect({30,60}, fill: {10,20,30,40})
  """

  alias Scenic.Primitive.Style.Paint

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  # verify that a color is correctly described
  @doc false
  def verify(paint) do
    try do
      normalize(paint)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  @doc false
  def normalize({:color, color}), do: {:color, Paint.Color.normalize(color)}
  def normalize({:linear, gradient}), do: {:linear, Paint.LinearGradient.normalize(gradient)}
  def normalize({:box, gradient}), do: {:box, Paint.BoxGradient.normalize(gradient)}
  def normalize({:radial, gradient}), do: {:radial, Paint.RadialGradient.normalize(gradient)}
  def normalize({:image, pattern}), do: {:image, Paint.Image.normalize(pattern)}
  # default is to treat it like a sindle color
  def normalize(color), do: {:color, Paint.Color.normalize(color)}
end
