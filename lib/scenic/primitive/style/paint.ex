#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint do
  @moduledoc false

  alias Scenic.Primitive.Style.Paint

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  # verify that a color is correctly described

  def verify(paint) do
    try do
      normalize(paint)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  # single color
  def normalize({:color, color}), do: {:color, Paint.Color.normalize(color)}
  def normalize({:linear, gradient}), do: {:linear, Paint.LinearGradient.normalize(gradient)}
  def normalize({:box, gradient}), do: {:box, Paint.BoxGradient.normalize(gradient)}
  def normalize({:radial, gradient}), do: {:radial, Paint.RadialGradient.normalize(gradient)}
  def normalize({:image, pattern}), do: {:image, Paint.Image.normalize(pattern)}
  # default is to treat it like a sindle color
  def normalize(color), do: {:color, Paint.Color.normalize(color)}
end
