#
#  Created by Boyd Multerer on 2021-04-19.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Stream.Image do
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

  @type meta :: {width :: pos_integer, height :: pos_integer, mime :: String.t()}

  @type t :: {__MODULE__, meta :: meta(), data :: binary}

  @spec from_binary(bin :: binary) :: t() | {:error, :invalid}
  def from_binary(bin) when is_binary(bin) do
    case ExImageInfo.info(bin) do
      {mime, width, height, _type} -> {__MODULE__, {width, height, mime}, bin}
      _ -> {:error, :invalid}
    end
  end

  # # --------------------------------------------------------
  # @impl Scenic.Assets.Stream
  @spec valid?(bitmap :: t()) :: boolean
  # def valid?( bitmap )
  def valid?({__MODULE__, {w, h, mime}, b})
      when is_integer(w) and is_integer(h) and is_binary(b) and is_bitstring(mime) do
    true
  end

  def valid?(_), do: false
end
