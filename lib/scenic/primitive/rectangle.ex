#
#  Created by Boyd Multerer on 2017-05-08.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Rectangle do
  @moduledoc false

  use Scenic.Primitive

  @styles [:hidden, :fill, :stroke]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be: {width, height}
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify({width, height} = data) when is_number(width) and is_number(height) do
    {:ok, data}
  end

  def verify(_), do: :invalid_data

  # ============================================================================
  @spec valid_styles() :: [:fill | :hidden | :stroke, ...]
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  def default_pin(data), do: centroid(data)

  # --------------------------------------------------------
  def centroid(data)

  def centroid({width, height}) do
    {width / 2, height / 2}
  end

  # --------------------------------------------------------
  def contains_point?({w, h}, {xp, yp}) do
    # width and xp must be the same sign
    # height and yp must be the same sign
    # xp must be less than the width
    # yp must be less than the height
    xp * w >= 0 && yp * h >= 0 && abs(xp) <= abs(w) && abs(yp) <= abs(h)
  end
end
