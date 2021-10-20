#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.Color do
  @moduledoc """
  Fill a primitive with a single color

  The color paint is used as the data for the [`:fill`](Scenic.Primitive.Style.Fill.html) style.

  ### Data Format

  `{:color, valid_color}`

  The full format is a tuple with two parameters. The first is the :color atom indicating
  that this is color paint data. The second is any valid color (see below).

  ### Valid Colors

  You can pass in any color format that is supported by the `Scenic.Color.to_rgba/1` function.

  This includes any named color. See the documentation for `Scenic.Color` for more information.

  Example:

  ```elixir
  graph
    |> rect( {100,200}, fill: {:color, :blue} )
    |> rect( {100,200}, stroke: {1, {:color, :green}} )
  ```


  ### Shortcut Format

  `valid_color`

  Because the color paint type is used so frequently, you can simply pass in any valid
  color and the `:fill` style will infer that it is to be used as paint.

  Example:

  ```elixir
  graph
    |> rect( {100,200}, fill: :blue )
    |> rect( {100,200}, stroke: {1, :green} )
  ```
  """

  # --------------------------------------------------------
  @doc false
  def validate({:color, color}) do
    try do
      {:ok, {:color, Scenic.Color.to_rgba(color)}}
    rescue
      _ -> {:error, error_msg({:color, color})}
    end
  end

  def validate(color) do
    try do
      {:ok, Scenic.Color.to_rgba(color)}
    rescue
      _ -> {:error, error_msg(color)}
    end
  end

  defp error_msg({:color, color}) do
    """
    Invalid Color specification: #{inspect(color)}
    #{IO.ANSI.yellow()}
    Valid color fills can be either just a color (the default fill) or an explicit {:color, color_data} tuple.

    Valid examples:
      fill: :green                # named color
      fill: {:green, 0xef}        # {named color, alpha}
      fill: { 10, 20, 30}         # {r, g, b} color
      fill: { 10, 20, 30, 0xff}   # {r, g, b, a} color

    Or any of the above can be a fully explicit color paint
      fill: {:color, :green}
      fill: {:color, { 10, 20, 30, 0xff}}
      etc...

    See the documentation for a list of named colors.
    https://hexdocs.pm/scenic/Scenic.Color.html#module-named-colors#{IO.ANSI.default_color()}
    """
  end

  defp error_msg(color) do
    """
    Invalid Color specification: #{inspect(color)}
    #{IO.ANSI.yellow()}
    Example colors:
      :green                # named color
      {:green, 0xef}        # {named color, alpha}
      { 10, 20, 30}         # {r, g, b} color
      { 10, 20, 30, 0xff}   # {r, g, b, a} color

    See the documentation for a list of named colors.
    https://hexdocs.pm/scenic/Scenic.Color.html#module-named-colors#{IO.ANSI.default_color()}
    """
  end
end
