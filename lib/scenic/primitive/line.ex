#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Line do
  @moduledoc """
  Draw a line on the screen.

  ## Data

  `{point_a, point_b}`

  The data for a line is a tuple containing two points.
  * `point_a` - position to start drawing from
  * `point_b` - position to draw to

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`cap`](Scenic.Primitive.Style.Cap.html) - says how to draw the ends of the line.
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#line/3)
  """

  use Scenic.Primitive

  #  import IEx

  @styles [:hidden, :stroke, :cap]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be two points: {{x0,y0}, {x1,y1}}
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify({{x0, y0}, {x1, y1}} = data)
      when is_number(x0) and is_number(y0) and is_number(x1) and is_number(y1),
      do: {:ok, data}

  def verify(_), do: :invalid_data

  # ============================================================================
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @spec valid_styles() :: [:cap | :hidden | :stroke, ...]
  def valid_styles(), do: @styles

  # ============================================================================

  # --------------------------------------------------------
  def default_pin(data), do: centroid(data)

  # --------------------------------------------------------
  @doc """
  Returns a the midpoint of the line. This is used as the default pin when applying
  rotate or scale transforms.
  """
  def centroid(data)

  def centroid({{x0, y0}, {x1, y1}}) do
    {
      (x0 + x1) / 2,
      (y0 + y1) / 2
    }
  end
end
