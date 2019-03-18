#
#  Created by Boyd Multerer on 2019-03-17.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Utilities.Texture do
  alias Scenic.Primitive.Style.Paint.Color

  @app Mix.Project.config()[:app]

  # load the NIF
  @compile {:autoload, false}
  @on_load :load_nifs

  @doc false
  def load_nifs do
    :ok =
      @app
      |> :code.priv_dir()
      |> :filename.join('texture')
      |> :erlang.load_nif(0)
  end

  # --------------------------------------------------------

  def build( :g, width, height, g ) when
  is_integer(g) and g >= 0 and g <= 255 and
  is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    {:g, width, height, nif_pixels(width * height, g)}
  end

  def build( :ga, width, height, {g,a} ) when
  is_integer(g) and g >= 0 and g <= 255 and
  is_integer(a) and a >= 0 and a <= 255 and
  is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    {:ga, width, height, nif_pixels(width * height * 2, g, a)}
  end

  def build( :rgb, width, height, color ) when
  is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    {r,g,b,_} = Color.to_rgba(color)
    {:rgb, width, height, nif_pixels(width * height * 3, r, g, b)}
  end

  def build( :rgba, width, height, color ) when
  is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    {r,g,b,a} = Color.to_rgba(color)
    {:rgba, width, height, nif_pixels(width * height * 4, r, g, b, a)}
  end

  defp nif_pixels(_,_), do: :erlang.nif_error("Did not find nif_pixels_g")
  defp nif_pixels(_,_,_), do: :erlang.nif_error("Did not find nif_pixels_ga")
  defp nif_pixels(_,_,_,_), do: :erlang.nif_error("Did not find nif_pixels_rgb")
  defp nif_pixels(_,_,_,_,_), do: :erlang.nif_error("Did not find nif_pixels_rgba")

  # --------------------------------------------------------
  def get( texture, x, y )
  def get( {:g,w,h,p}, x, y ) when x <= w and y <= h, do: nif_get_g(p, y * w + x )
  def get( {:ga,w,h,p}, x, y ) when x <= w and y <= h, do: nif_get_ga(p, y * w + x )
  def get( {:rgb,w,h,p}, x, y ) when x <= w and y <= h, do: nif_get_rgb(p, y * w + x )
  def get( {:rgba,w,h,p}, x, y ) when x <= w and y <= h, do: nif_get_rgba(p, y * w + x )

  defp nif_get_g(_,_), do: :erlang.nif_error("Did not find nif_get_g")
  defp nif_get_ga(_,_), do: :erlang.nif_error("Did not find nif_get_ga")
  defp nif_get_rgb(_,_), do: :erlang.nif_error("Did not find nif_get_rgb")
  defp nif_get_rgba(_,_), do: :erlang.nif_error("Did not find nif_get_rgba")

  # --------------------------------------------------------
  def put!( texture, x, y, color )
  def put!( {:g,w,h,p}, x, y, g ) when x <= w and y <= h do
    nif_put(p, y * w + x, g )
    {:g,w,h,p}
  end
  def put!( {:ga,w,h,p}, x, y, {g,a} ) when x <= w and y <= h do
    nif_put(p, y * w + x, g, a )
    {:ga,w,h,p}
  end
  def put!( {:rgb,w,h,p}, x, y, color ) when x <= w and y <= h do
    {r,g,b,_} = Color.to_rgba(color)
    nif_put(p, y * w + x, r, g, b )
    {:rgb,w,h,p}
  end
  def put!( {:rgba,w,h,p}, x, y, color ) when x <= w and y <= h do
    {r,g,b,a} = Color.to_rgba(color)
    nif_put(p, y * w + x, r, g, b, a )
    {:rgba,w,h,p}
  end

  defp nif_put(_,_,_), do: :erlang.nif_error("Did not find nif_put_g")
  defp nif_put(_,_,_,_), do: :erlang.nif_error("Did not find nif_put_ga")
  defp nif_put(_,_,_,_,_), do: :erlang.nif_error("Did not find nif_put_rgb")
  defp nif_put(_,_,_,_,_,_), do: :erlang.nif_error("Did not find nif_put_rgba")

  # --------------------------------------------------------
  def clear!( texture, color )
  def clear!( {:g,w,h,p}, g ) do
    {:g,w,h, nif_clear(p, g )}
  end
  def clear!( {:ga,w,h,p}, {g,a} ) do
    {:ga,w,h, nif_clear(p, g, a )}
  end
  def clear!( {:rgb,w,h,p}, color ) do
    {r,g,b,_} = Color.to_rgba(color)
    {:rgb,w,h, nif_clear(p, r, g, b )}
  end
  def clear!( {:rgba,w,h,p}, color ) do
    {r,g,b,a} = Color.to_rgba(color)
    {:rgba,w,h, nif_clear(p, r, g, b, a )}
  end

  defp nif_clear(_,_), do: :erlang.nif_error("Did not find nif_clear_g")
  defp nif_clear(_,_,_), do: :erlang.nif_error("Did not find nif_clear_ga")
  defp nif_clear(_,_,_,_), do: :erlang.nif_error("Did not find nif_clear_rgb")
  defp nif_clear(_,_,_,_,_), do: :erlang.nif_error("Did not find nif_clear_rgba")

  # --------------------------------------------------------
  def to_rgba( texture )

  def to_rgba( {:g,w,h,p} ) do
    {:rgba, w, h, nif_g_to_rgba(p, w * h)}
  end
  def to_rgba( {:ga,w,h,p} ) do
    {:rgba, w, h, nif_ga_to_rgba(p, w * h)}
  end
  def to_rgba( {:rgb,w,h,p} ) do
    {:rgba, w, h, nif_rgb_to_rgba(p, w * h)}
  end
  def to_rgba( {:rgba,_,_,_} = tex ), do: tex

  defp nif_g_to_rgba(_,_), do: :erlang.nif_error("Did not find nif_g_to_rgba")
  defp nif_ga_to_rgba(_,_), do: :erlang.nif_error("Did not find nif_ga_to_rgba")
  defp nif_rgb_to_rgba(_,_), do: :erlang.nif_error("Did not find nif_rgb_to_rgba")


  # --------------------------------------------------------
  # def copy!( destination, dx, dy, source, sx, sy, w, h)

end





