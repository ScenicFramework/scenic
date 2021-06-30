#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.Stream do
  @moduledoc """
  Fill a primitive with an texture from Scenic.ViewPort.Stream

  ## Format

  * `{:stream, key}` - Fill with the streamed textured indicated by `key`
  """

  def validate({:stream, key}) when is_bitstring(key) do
     { :ok, {:stream, key} }
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
