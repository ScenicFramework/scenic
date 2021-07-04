#
#  Created by Boyd Multerer on 2021-04-19.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Stream.Image do
  @moduledoc """
  This module helps you to prepare images, in the form of a compressed blob such as 
  a jpg or png file, that are to be streamed and displayed through the
  `Scenic.Assets.Stream` module.

  A typical use case is receiving pre-compressed images from a physical camera, then
  streaming them as the fill of a rect in a scene.

  This module is very simple. The only function is from_binary/1, where you supply a
  binary that is a valid compressed image format. That format is verified and the
  metadata is parsed out of it.

  The result is a term that can be supplied to the Scenic.Assets.Stream module.

  Example:

  ```elixir
  alias Scenic.Assets.Stream

  def handle_info( {:camera_frame, bin}, state ) do
    # If the supplied bin is not a valid image, let it crash
    {:ok, img} = Stream.Image.from_binary( bin )
    Stream.put( "camera", img )
    { :noreply, state }
  end
  ```
  """

  @type meta :: {width :: pos_integer, height :: pos_integer, mime :: String.t()}

  @type t :: {__MODULE__, meta :: meta(), data :: binary}

  @doc """
  Create a streamable image resource from a compressed image binary.

  On success, this returns `{:ok, img}`

  The supplied binary must be a valid jpeg or png format. If it is either invalid or an
  unrecognized format, this will return `{:error, :invalid}`
  """
  @spec from_binary(bin :: binary) :: t() | {:error, :invalid}
  def from_binary(bin) when is_binary(bin) do
    case ExImageInfo.info(bin) do
      {mime, width, height, _type} -> {:ok, {__MODULE__, {width, height, mime}, bin}}
      _ -> {:error, :invalid}
    end
  end

  # # --------------------------------------------------------
  @doc false
  # @impl Scenic.Assets.Stream
  @spec valid?(bitmap :: t()) :: boolean
  # def valid?( bitmap )
  def valid?({__MODULE__, {w, h, mime}, b})
      when is_integer(w) and is_integer(h) and is_binary(b) and is_bitstring(mime) do
    true
  end

  def valid?(_), do: false
end
