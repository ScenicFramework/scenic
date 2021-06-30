#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Stroke do
  @moduledoc """
  Draw an outline around a primitive with the given paint.

  Example:

      graph
      |> triangle( {{0,40},{40,40},{40,0}}
        miter_limit: 2,
        stroke: {2, :green}
      )

  ## Data

  `paint`
  `{width, paint}`

  * `width` - Width of the border being stroked.
  * `:paint` - Any [valid paint](Scenic.Primitive.Style.Paint.html).

  Using the form `{width, paint}` is the same as setting the styles `stroke: paint_type, stroke_width: width`

  """

  use Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Paint

  # ============================================================================
  # data verification and serialization


  def validate( {width, paint} = data ) when is_number(width) and width >= 0 do
    case Paint.validate(paint) do
      {:ok, paint} -> {:ok, {width, paint}}
      {:error, msg} -> err_paint( data, msg )
    end
  end
  def validate( data ), do: err_invalid(data)



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