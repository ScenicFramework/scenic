#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
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


  def validate({:color, _} = opt), do: Paint.Color.validate(opt)
  def validate({:linear, _} = opt), do: Paint.LinearGradient.validate(opt)
  def validate({:radial, _} = opt), do: Paint.RadialGradient.validate(opt)
  def validate({:image, _} = opt), do: Paint.Image.validate(opt)
  def validate({:stream, _} = opt), do: Paint.Stream.validate(opt)
  # default is to treat it like a single color
  def validate(color) do
    case Paint.Color.validate(color) do
      {:ok, color} -> {:ok, {:color, color}}
      err -> err
    end
  end

end
