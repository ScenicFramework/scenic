#
#  Created by Boyd Multerer on 2021-04-19.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Stream.Bitmap do
  @moduledoc """
  This module helps you to prepare images that are to be streamed, and displayed
  through the Scenic.Assets.Stream module.

  Typical textures are frames captured from a camera on a device, or bitmaps that
  you render to directly in your own code.

  In either case, the image being displayed in a Scene is not known in advance. Or,
  in other words, it cannot be cached using the Scenic.Assets.Static mechanism,
  which is preferred for things that don't change.

  It doesn't really matter if the image is obtained and displayed once, or captured
  from a camera and updated ten times per second. A _texture_ is effectively a type
  of image that is more ephemeral than something that lives with the device forever.
  """

  alias Scenic.Assets
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

  @type format ::
          :g
          | :ga
          | :rgb
          | :rgba

  @type meta :: {width :: pos_integer, height :: pos_integer, format :: format()}

  @bitmap __MODULE__
  @mutable :mutable_bitmap

  @type t :: {__MODULE__, meta :: meta(), data :: binary}
  @type m :: {:mutable_bitmap, meta :: meta(), data :: binary}

  # --------------------------------------------------------
  @spec build(
          format :: Assets.image_format(),
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
  @spec mutable(texture :: t()) :: mutable :: m()
  def mutable({@bitmap, meta, bin}), do: {@mutable, meta, :binary.copy(bin)}

  # --------------------------------------------------------
  @spec commit(mutable :: m()) :: texture :: t()
  def commit({@mutable, meta, bin}), do: {@bitmap, meta, bin}

  # --------------------------------------------------------
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

  defp nif_put(_, _, _), do: :erlang.nif_error("Did not find nif_put_g")
  defp nif_put(_, _, _, _), do: :erlang.nif_error("Did not find nif_put_ga")
  defp nif_put(_, _, _, _, _), do: :erlang.nif_error("Did not find nif_put_rgb")
  defp nif_put(_, _, _, _, _, _), do: :erlang.nif_error("Did not find nif_put_rgba")

  # --------------------------------------------------------
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
  # @impl Scenic.Assets.Stream
  @spec valid?(bitmap :: t()) :: boolean
  def valid?(bitmap)
  def valid?({@bitmap, {w, h, :g}, p}), do: byte_size(p) == w * h
  def valid?({@bitmap, {w, h, :ga}, p}), do: byte_size(p) == w * h * 2
  def valid?({@bitmap, {w, h, :rgb}, p}), do: byte_size(p) == w * h * 3
  def valid?({@bitmap, {w, h, :rgba}, p}), do: byte_size(p) == w * h * 4
  def valid?(_), do: false
end
