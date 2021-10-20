#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Stroke do
  @moduledoc """
  Draw an outline around a primitive with the given paint.

  Example:

  ```elixir
  graph
    |> triangle( {{0,40},{40,40},{40,0}}
      miter_limit: 2,
      stroke: {2, :green}
    )
  ```

  ### Data Format

  `{width, paint}`

  * `width` - Width of the border being stroked.
  * `paint` - Any paint data.

  The paint can any be any format defined by the following modules:

  * `Scenic.Primitive.Style.Paint.Color`
  * `Scenic.Primitive.Style.Paint.Image`
  * `Scenic.Primitive.Style.Paint.LinearGradient`
  * `Scenic.Primitive.Style.Paint.RadialGradient`
  * `Scenic.Primitive.Style.Paint.Stream`

  See the documentation for the paint module for further details.
  """

  use Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Paint

  # ============================================================================
  # data verification and serialization

  @doc false
  def validate({width, paint} = data) when is_number(width) and width >= 0 do
    case Paint.validate(paint) do
      {:ok, paint} -> {:ok, {width, paint}}
      {:error, msg} -> err_paint(data, msg)
    end
  end

  def validate(data), do: err_invalid(data)

  defp err_paint(data, msg) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Stroke specification
      Received: #{inspect(data)}
      #{msg}
      """
    }
  end

  defp err_invalid(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Stroke specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :stroke style is specified in the form of: { width, paint }

      'width' is a positive number representing how wide the border should be.
      'paint' is a valid paint specification (color, image, dynamic, linear, radial...)#{IO.ANSI.default_color()}
      """
    }
  end
end
