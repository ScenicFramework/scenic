#
#  Created by Boyd Multerer on 2019-03-04.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Dynamic.Texture do
  use Scenic.Cache.Base, name: "texture", static: false
  # alias Scenic.Cache.Support

  # import IEx

  # --------------------------------------------------------
  def put( key, data, opts ) do
    case validate( data ) do
      :ok -> super(key, data, opts)
      err -> err
    end
  end

  # --------------------------------------------------------
  defp validate( {:g, w, h, pix, _} ), do: do_validate(w * h, byte_size(pix))
  defp validate( {:ga, w, h, pix, _} ), do: do_validate(w * h * 2, byte_size(pix))
  defp validate( {:rgb, w, h, pix, _} ), do: do_validate(w * h * 3, byte_size(pix))
  defp validate( {:rgba, w, h, pix, _} ), do: do_validate(w * h * 4, byte_size(pix))
  defp validate( _ ), do: {:error, :pixels_format}

  defp do_validate(expected, actual) when expected == actual, do: :ok
  defp do_validate(_, _), do: {:error, :pixels_size}
end
