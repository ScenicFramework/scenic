#
#  Created by Boyd Multerer on 2018-06-05.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Fill do
  @moduledoc """
  Fill primitives with the specified paint.

  Example:

      graph
      |> rectangle( {10, 20}, fill: :blue )

  ### Data Format

  Any valid paint. This can any be any paint format defined by the following modules:

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
  def validate(paint) do
    case Paint.validate(paint) do
      {:ok, paint} ->
        {:ok, paint}

      {:error, error_str} ->
        {
          :error,
          """
          #{IO.ANSI.red()}Invalid Fill specification - must be a valid paint
          Received: #{inspect(paint)}
          #{error_str}
          """
        }
    end
  end
end
