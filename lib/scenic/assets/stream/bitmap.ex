#
#  Created by Boyd Multerer on 2021-04-19.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Stream.Bitmap do
  @moduledoc """
  This module helps you to prepare images, in the form of a bitmap, that are to be streamed
  and displayed through the `Scenic.Assets.Stream` module.

  A bitmap is a rectangular field of pixels. Each pixel can be addressed and assigned a color.
  When the bitmap is put into `Scenic.Assets.Stream` it becomes an image that can be displayed
  in a scene via `Scenic.Primitive.Style.Paint.Stream`.

  ### Committed vs. Mutable

  Bitmaps are interesting because a typical pattern is to change the color of many pixels in
  a rapid burst, then send the image up. The bitmaps can become quite large tho, so if we
  were to make a copy of it every time a single pixel was changed, that could become quite
  slow.

  Unfortunately, writing a NIF that manipulates individual pixels quickly and without making
  a copy, breaks the immutable, functional model of Erlang/Elixir.

  The compromise is that a Bitmap can be either in a "commited" state, which can be put
  into `Scenic.Assets.Stream`, but not changed, or in a "mutable" state, which can be
  manipulated rapidly, but not streamed to scenes.

  When a new bitmap is built, it starts in the mutable state, unless the `commit: true` option is set.

  ```elixir
  alias Scenic.Assets.Stream.Bitmap

  bitmap = Bitmap.build( :rgb, 20, 10, clear: :blue )
    |> Bitmap.put( 2, 3, :red )
    |> Bitmap.put( 9, 10, :yellow )
    |> Bitmap.commit()

  Scenic.Assets.Stream.put( "stream_id", bitmap )
  ```

  In the above example, a new bitmap is created, that can hold an rgb color in every pixel,
  is 20 pixels wide, 10 pixels high, and starts with the entire image set to the color `:blue`.
  The `:commit` option is not set, so it is mutable.

  Then two of the pixels are set to other colors. One `:red` and the other `:yellow`.

  Finally, the image is committed, making it usable, but no longer mutable. After the image is
  completed, it is sent to `Scenic.Assets.Stream`, which makes it available for use in a scene.

  ### Color Depth

  Bitmaps can be one of four depths. Each consumes a different amount of memory per pixel.
  If you are running on a constrained memory device, or are worried about bandwidth when remoting
  the UI, then you should choose the depth that you actually use. If you have lots of memory,
  then `:rgba` is usually the fastest format.

  | Depth          | Bytes per pixel        | Notes   |
  |---------------|------------------------|-----------|
  |  `:g` | 1 | Simple Greyscale. 256 shades of grey |
  |  `:ga` | 2 | Greyscale plus an alhpa channel |
  |  `:rgb` | 3 | Red/Green/Blue Millions of colors |
  |  `:rgba` | 4 | Red/Green/Blue/Alpha |

  """

  alias Scenic.Assets.Stream.Bitmap
  alias Scenic.Color

  @app Mix.Project.config()[:app]

  # load the NIF
  @compile {:autoload, false}
  @on_load :load_nifs

  @doc false
  def load_nifs do
    :ok =
      @app
      |> :code.priv_dir()
      |> :filename.join('bitmap')
      |> :erlang.load_nif(0)
  end

  @type depth ::
          :g
          | :ga
          | :rgb
          | :rgba

  @type meta :: {width :: pos_integer, height :: pos_integer, depth :: depth()}

  @bitmap __MODULE__
  @mutable :mutable_bitmap

  @type t :: {__MODULE__, meta :: meta(), data :: binary}
  @type m :: {:mutable_bitmap, meta :: meta(), data :: binary}

  # --------------------------------------------------------
  @doc """
  Build a new bitmap with a given depth, width and height.

  Build creates a new bitmap in memory. It begins in a mutable state
  and will be set to transparent black unless the :clear option is specified.

  The valid depths are :g, :ga, :rgb, :rgba as explained in the following table

  | Depth          | Bytes per pixel        | Notes   |
  |---------------|------------------------|-----------|
  |  `:g` | 1 | Simple Greyscale. 256 shades of grey |
  |  `:ga` | 2 | Greyscale plus an alhpa channel |
  |  `:rgb` | 3 | Red/Green/Blue Millions of colors |
  |  `:rgba` | 4 | Red/Green/Blue/Alpha |

  ### Options

  * `:clear` Set the new bitmap so that every pixel is the specified color.
  * `:commit` Set to true to start the bitmap committed. Set to false for mutable. The default if not specified is mutable.
  """

  @spec build(
          depth :: Bitmap.depth(),
          width :: pos_integer,
          height :: pos_integer,
          opts :: Keyword.t()
        ) :: t()

  def build(format, width, height, opts \\ [])

  def build(format, width, height, opts) do
    bits =
      case format do
        :g -> 8 * width * height
        :ga -> 8 * width * height * 2
        :rgb -> 8 * width * height * 3
        :rgba -> 8 * width * height * 4
      end

    m = {@mutable, {width, height, format}, <<0::size(bits)>>}

    m =
      case opts[:clear] do
        nil -> m
        color -> clear(m, color)
      end

    case opts[:commit] do
      nil -> m
      false -> m
      true -> commit(m)
    end
  end

  # --------------------------------------------------------
  @doc """
  Change a bitmap from committed to mutable.

  This makes a copy of the bitmap's memory to preserve the Erlang model.

  Mutable bitmaps are not usable by `Scenic.Assets.Stream`.
  """
  @spec mutable(texture :: t()) :: mutable :: m()
  def mutable({@bitmap, meta, bin}), do: {@mutable, meta, :binary.copy(bin)}

  # --------------------------------------------------------
  @doc """
  Change a bitmap from mutable to committed.

  Committed bitmaps can be used by `Scenic.Assets.Stream`. They will not
  work with the `put` and `clear` functions in this module.
  """
  @spec commit(mutable :: m()) :: texture :: t()
  def commit({@mutable, meta, bin}), do: {@bitmap, meta, bin}

  # --------------------------------------------------------
  @doc """
  Get the color value of a single pixel in a bitmap.

  Works with either committed or mutable bitmaps.
  """
  @spec get(t_or_m :: t() | m(), x :: pos_integer, y :: pos_integer) :: Color.explicit()
  def get(texture, x, y)
  def get({@mutable, meta, bin}, x, y), do: do_get(meta, bin, x, y)
  def get({@bitmap, meta, bin}, x, y), do: do_get(meta, bin, x, y)

  defp do_get({w, h, :g}, p, x, y)
       when is_integer(x) and x >= 0 and x <= w and
              is_integer(y) and y >= 0 and y <= h do
    skip = y * w + x
    <<_::binary-size(skip), g::8, _::binary>> = p
    Color.to_g(g)
  end

  defp do_get({w, h, :ga}, p, x, y)
       when is_integer(x) and x >= 0 and x <= w and
              is_integer(y) and y >= 0 and y <= h do
    skip = y * w * 2 + x * 2
    <<_::binary-size(skip), g::8, a::8, _::binary>> = p
    Color.to_ga({g, a})
  end

  defp do_get({w, h, :rgb}, p, x, y)
       when is_integer(x) and x >= 0 and x <= w and
              is_integer(y) and y >= 0 and y <= h do
    skip = y * w * 3 + x * 3
    <<_::binary-size(skip), r::8, g::8, b::8, _::binary>> = p
    Color.to_rgb({r, g, b})
  end

  defp do_get({w, h, :rgba}, p, x, y)
       when is_integer(x) and x >= 0 and x <= w and
              is_integer(y) and y >= 0 and y <= h do
    skip = y * w * 4 + x * 4
    <<_::binary-size(skip), r::8, g::8, b::8, a::8, _::binary>> = p
    Color.to_rgba({r, g, b, a})
  end

  # --------------------------------------------------------
  @doc """
  Set the color value of a single pixel in a bitmap.

  Only works with mutable bitmaps.

  The color you provide can be any valid value from the `Scenic.Color` module.

  If the color you provide doesn't match the depth of the bitmap, this will
  transform the color as appropriate to fit. For example, putting an `:rgb`
  color into a `:g` (greyscale) bit map, will set the level of grey to be the average
  value of the red, green, and blue channels of the supplied color
  """

  @spec put(mutable :: m(), x :: pos_integer, y :: pos_integer, color :: Color.t()) ::
          mutable :: m()
  def put(mutable, x, y, color)

  def put({@mutable, {w, h, :g}, p}, x, y, color)
      when is_integer(x) and x >= 0 and x <= w and
             is_integer(y) and y >= 0 and y <= h do
    {:color_g, g} = Color.to_g(color)
    nif_put(p, y * w + x, g)
    {@mutable, {w, h, :g}, p}
  end

  def put({@mutable, {w, h, :ga}, p}, x, y, color)
      when is_integer(x) and x >= 0 and x <= w and
             is_integer(y) and y >= 0 and y <= h do
    {:color_ga, {g, a}} = Color.to_ga(color)
    nif_put(p, y * w + x, g, a)
    {@mutable, {w, h, :ga}, p}
  end

  def put({@mutable, {w, h, :rgb}, p}, x, y, color)
      when is_integer(x) and x >= 0 and x <= w and
             is_integer(y) and y >= 0 and y <= h do
    {:color_rgb, {r, g, b}} = Color.to_rgb(color)
    nif_put(p, y * w + x, r, g, b)
    {@mutable, {w, h, :rgb}, p}
  end

  def put({@mutable, {w, h, :rgba}, p}, x, y, color)
      when is_integer(x) and x >= 0 and x <= w and
             is_integer(y) and y >= 0 and y <= h do
    {:color_rgba, {r, g, b, a}} = Color.to_rgba(color)
    nif_put(p, y * w + x, r, g, b, a)
    {@mutable, {w, h, :rgba}, p}
  end

  # --------------------------------------------------------
  @doc """
  Set the color value of a single pixel in a bitmap using an offset from the start.

  Only works with mutable bitmaps.

  The color you provide can be any valid value from the `Scenic.Color` module.

  Unlike the `put` function, which specifies the pixel by `x` and `y` position,
  `put_offset` takes an offset directly into the data.

  The offset would be the same as y * width + x.
  """

  @spec put_offset(mutable :: m(), offset :: pos_integer, color :: Color.t()) ::
          mutable :: m()
  def put_offset(mutable, offset, color)

  def put_offset({@mutable, {w, h, :g}, p}, offset, color) when is_integer(offset) do
    if offset > w * h, do: raise "Offset is out of bounds"
    {:color_g, g} = Color.to_g(color)
    nif_put(p, offset, g)
    {@mutable, {w, h, :g}, p}
  end

  def put_offset({@mutable, {w, h, :ga}, p}, offset, color) when is_integer(offset) do
    if offset > w * h, do: raise "Offset is out of bounds"
    {:color_ga, {g, a}} = Color.to_ga(color)
    nif_put(p, offset, g, a)
    {@mutable, {w, h, :ga}, p}
  end

  def put_offset({@mutable, {w, h, :rgb}, p}, offset, color) when is_integer(offset) do
    if offset > w * h, do: raise "Offset is out of bounds"
    {:color_rgb, {r, g, b}} = Color.to_rgb(color)
    nif_put(p, offset, r, g, b)
    {@mutable, {w, h, :rgb}, p}
  end

  def put_offset({@mutable, {w, h, :rgba}, p}, offset, color) when is_integer(offset) do
    if offset > w * h, do: raise "Offset is out of bounds"
    {:color_rgba, {r, g, b, a}} = Color.to_rgba(color)
    nif_put(p, offset, r, g, b, a)
    {@mutable, {w, h, :rgba}, p}
  end

  defp nif_put(_, _, _), do: :erlang.nif_error("Did not find nif_put_g")
  defp nif_put(_, _, _, _), do: :erlang.nif_error("Did not find nif_put_ga")
  defp nif_put(_, _, _, _, _), do: :erlang.nif_error("Did not find nif_put_rgb")
  defp nif_put(_, _, _, _, _, _), do: :erlang.nif_error("Did not find nif_put_rgba")

  # --------------------------------------------------------
  @doc """
  Set the color value of all pixels in a bitmap. This effectively erases the bitmap,
  replacing it with a solid field of the supplied color.

  Only works with mutable bitmaps.

  The color you provide can be any valid value from the `Scenic.Color` module.

  If the color you provide doesn't match the depth of the bitmap, this will
  transform the color as appropriate to fit. For example, putting an `:rgb`
  color into a `:g` (greyscale) bit map, will set the level of grey to be the average
  value of the red, green, and blue channels of the supplied color
  """

  @spec clear(mutable :: m(), color :: Color.t()) :: mutable :: m()

  def clear(mutable, color)

  def clear({@mutable, {w, h, :g}, p}, color) do
    {:color_g, g} = Color.to_g(color)
    nif_clear(p, g)
    {@mutable, {w, h, :g}, p}
  end

  def clear({@mutable, {w, h, :ga}, p}, color) do
    {:color_ga, {g, a}} = Color.to_ga(color)
    nif_clear(p, g, a)
    {@mutable, {w, h, :ga}, p}
  end

  def clear({@mutable, {w, h, :rgb}, p}, color) do
    {:color_rgb, {r, g, b}} = Color.to_rgb(color)
    nif_clear(p, r, g, b)
    {@mutable, {w, h, :rgb}, p}
  end

  def clear({@mutable, {w, h, :rgba}, p}, color) do
    {:color_rgba, {r, g, b, a}} = Color.to_rgba(color)
    nif_clear(p, r, g, b, a)
    {@mutable, {w, h, :rgba}, p}
  end

  def clear({@mutable, {_, _, :file}, _p}, _c) do
    raise "Texture.clear(...) is not supported for file encoded data"
  end

  defp nif_clear(_, _), do: :erlang.nif_error("Did not find nif_clear_g")
  defp nif_clear(_, _, _), do: :erlang.nif_error("Did not find nif_clear_ga")
  defp nif_clear(_, _, _, _), do: :erlang.nif_error("Did not find nif_clear_rgb")
  defp nif_clear(_, _, _, _, _), do: :erlang.nif_error("Did not find nif_clear_rgba")

  # --------------------------------------------------------
  @doc false
  # @impl Scenic.Assets.Stream
  @spec valid?(bitmap :: t()) :: boolean
  def valid?(bitmap)
  def valid?({@bitmap, {w, h, :g}, p}), do: byte_size(p) == w * h
  def valid?({@bitmap, {w, h, :ga}, p}), do: byte_size(p) == w * h * 2
  def valid?({@bitmap, {w, h, :rgb}, p}), do: byte_size(p) == w * h * 3
  def valid?({@bitmap, {w, h, :rgba}, p}), do: byte_size(p) == w * h * 4
  def valid?(_), do: false
end
