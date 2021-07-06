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

  * `Scenic.Primitive.Style.Paint.Color`
  * `Scenic.Primitive.Style.Paint.Image`
  * `Scenic.Primitive.Style.Paint.LinearGradient`
  * `Scenic.Primitive.Style.Paint.RadialGradient`
  * `Scenic.Primitive.Style.Paint.Stream`

  See the documentation for the paint module for further details.
  """

  alias Scenic.Primitive.Style.Paint

  # ============================================================================
  # data verification and serialization

  @doc false
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
