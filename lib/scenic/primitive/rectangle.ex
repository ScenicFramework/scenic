#
#  Created by Boyd Multerer on 2017-05-08.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Rectangle do
  @moduledoc """
  Draw a rectangle on the screen.

  ## Data

  `{width, height}`

  The data for a line is a tuple containing two numbers.
  * `width` - width of the rectangle
  * `height` - height of the rectangle

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.
  * [`join`](Scenic.Primitive.Style.Join.html) - control how segments are joined.
  * [`miter_limit`](Scenic.Primitive.Style.MiterLimit.html) - control how segments are joined.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#rectangle/3)
  """

  use Scenic.Primitive
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  @type t :: {width :: number, height :: number}
  @type styles_t :: [:hidden | :fill | :stroke_width | :stroke_fill | :join | :miter_limit]

  @styles [:hidden, :fill, :stroke_width, :stroke_fill, :join, :miter_limit]

  @impl Primitive
  @spec validate( t() ) :: {:ok, t()} | {:error, String.t()}
  def validate( {width, height} ) when is_number(width) and is_number(height) do
    {:ok, {width, height}}
  end

  def validate( data ) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Rectangle specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a Rectangle is {height, width}#{IO.ANSI.default_color()}
      """
    }
  end


  # --------------------------------------------------------
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @impl Primitive
  @spec valid_styles() :: styles_t()
  def valid_styles(), do: @styles


  # --------------------------------------------------------
  @doc """
  Compile the data for this primitive into a mini script. This can be combined with others to
  generate a larger script and is called when a graph is compiled.
  """
  @impl Primitive
  @spec compile( primitive::Primitive.t(), styles::Style.m() ) :: Script.t()
  def compile( %Primitive{module: __MODULE__, data: {width, height}}, styles ) do
    Script.draw_rectangle([], width, height, Script.draw_flag(styles) )
  end





  # --------------------------------------------------------
  def default_pin(data), do: centroid(data)

  # --------------------------------------------------------
  @doc """
  Returns the centroid of the rectangle. This is used as the default pin when applying
  rotate or scale transforms.
  """
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
