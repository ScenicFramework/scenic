#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.Stream do
  @moduledoc """
  Fill a primitive with an image or bitmap from Scenic.Assets.Stream

  ## Format

  `{:stream, key}`

  Fill with the static image indicated by `key`

  This example fills a rect with the contents of the `"color_cycle"` stream.
  When the source of the stream updates the bitmap it contains, the rect's
  fill will automatically be updated.
 
  ```elixir
  Graph.build()
    |> rect( {100, 50}, fill: {:stream, "color_cycle"} )
  ```
  """

  def validate(data)

  def validate({:stream, key}) when is_bitstring(key) do
    {:ok, {:stream, key}}
  end

  def validate(_) do
    {
      :error,
      """
      #{IO.ANSI.yellow()}
      Streaming texture fills must be a string that names a texture published into Scenic.ViewPort.Stream

      The texture does not need to be published when it is reference.
      However, it will not draw until it is. #{IO.ANSI.default_color()}
      """
    }
  end
end
