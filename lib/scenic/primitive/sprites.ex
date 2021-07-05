#
#  Created by Boyd Multerer on 2021-05-29.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Sprites do
  @moduledoc """
  Draw an Image on the screen.
  """

  use Scenic.Primitive
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style
  alias Scenic.Assets.Static

  @type draw_cmd :: {
          {sx :: number, sy :: number},
          {sw :: number, sh :: number},
          {dx :: number, dy :: number},
          {dw :: number, dh :: number}
        }
  @type draw_cmds :: [draw_cmd()]

  @type t :: {image :: Static.id(), draw_cmds}
  @type styles_t :: [:hidden]

  @styles [:hidden]

  @impl Primitive
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate({image, cmds})
      when is_list(cmds) and (is_atom(image) or is_bitstring(image)) do
    with {:ok, image} <- validate_image(image),
         {:ok, cmds} <- validate_commands(cmds) do
      {:ok, {image, cmds}}
    else
      {:error, :command, cmd} -> err_bad_cmd(image, cmd)
      {:error, :alias} -> err_bad_alias(image)
      {:error, :font} -> err_is_font(image)
      {:error, :not_found} -> err_missing_image(image)
    end
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Sprites specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      Sprites data must formed like:
      {static_image_id, [{{src_x,src_y}, {src_w,src_h}, {dst_x,dst_y}, {dst_w,dst_h}}]}

      This means, given an image in the Scenic.Assets.Static library, copy a series of
      sub-images from it into the specified positions.

      The {src_x, src_y} is the upper-left location of the source sub-image to copy out.
      {src_w, src_h} is the width / height of the source sub-image.

      {dst_x, dst_y} location in local coordinate space to past into.
      {dst_w,dst_h} is the width / height of the destination image.

      {dst_w,dst_h} and {src_w, src_h} do NOT need to be the same.
      The source will be shrunk or expanded to fit the destination rectangle.#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_bad_cmd(image, cmd) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Sprites specification
      Image: #{inspect(image)}
      Invalid Command: #{inspect(cmd)}
      #{IO.ANSI.yellow()}
      Sprites data must formed like:
      {static_image_id, [{{src_x,src_y}, {src_w,src_h}, {dst_x,dst_y}, {dst_w,dst_h}}]}

      This means, given an image in the Scenic.Assets.Static library, copy a series of
      sub-images from it into the specified positions.

      The {src_x, src_y} is the upper-left location of the source sub-image to copy out.
      {src_w, src_h} is the width / height of the source sub-image.

      {dst_x, dst_y} location in local coordinate space to past into.
      {dst_w,dst_h} is the width / height of the destination image.

      {dst_w,dst_h} and {src_w, src_h} do NOT need to be the same.
      The source will be shrunk or expanded to fit the destination rectangle.#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_bad_alias(image) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Sprites specification
      Unmapped Image Alias: #{inspect(image)}
      #{IO.ANSI.yellow()}
      Sprites must use a valid image from your Scenic.Assets.Static library.

      To resolve this, make sure the alias mapped to a file path in your config.
        config :scenic, :assets,
          module: MyApplication.Assets,
          alias: [
            parrot: "images/parrot.jpg"
          ]#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_missing_image(image) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Sprites specification
      The image #{inspect(image)} could not be found.
      #{IO.ANSI.yellow()}
      Sprites must use a valid image from your Scenic.Assets.Static library.

      To resolve this do the following checks.
        1) Confirm that the file exists in your assets folder.

        2) Make sure the image file is being compiled into your asset library.
          If this file is new, you may need to "touch" your asset library module to cause it to recompile.
          Maybe somebody will help add a filesystem watcher to do this automatically. (hint hint...)

        3) Check that and that the asset module is defined in your config.
          config :scenic, :assets,
            module: MyApplication.Assets #{IO.ANSI.default_color()}
      """
    }
  end

  defp err_is_font(image) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Sprites specification
      The asset #{inspect(image)} is a font.
      #{IO.ANSI.yellow()}
      Sprites must use a valid image from your Scenic.Assets.Static library.
      """
    }
  end

  defp validate_image(id) do
    with {:ok, id_str} <- Static.resolve_id(id),
         {:ok, {Static.Image, _}} <- Static.fetch(id_str) do
      {:ok, id_str}
    else
      {:ok, {Static.Font, _}} -> {:error, :font}
      {:error, :not_mapped} -> {:error, :alias}
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  defp validate_commands(commands) do
    commands
    |> Enum.reduce({:ok, commands}, fn
      _, {:error, _} = error ->
        error

      {{src_x, src_y}, {src_w, src_h}, {dst_x, dst_y}, {dst_w, dst_h}}, acc
      when is_number(src_x) and is_number(src_y) and
             is_number(src_w) and is_number(src_h) and
             is_number(dst_x) and is_number(dst_y) and
             is_number(dst_w) and is_number(dst_h) ->
        acc

      cmd, _ ->
        {:error, :command, cmd}
    end)
  end

  # --------------------------------------------------------
  # filter and gather styles

  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @impl Primitive
  @spec valid_styles() :: styles_t()
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  # compiling a script is a special case and is handled in Scenic.ViewPort.GraphCompiler
  @doc false
  @impl Primitive
  @spec compile(primitive :: Primitive.t(), styles :: Style.m()) :: Script.t()
  def compile(%Primitive{module: __MODULE__, data: {image, cmds}}, _styles) do
    Script.draw_sprites([], image, cmds)
  end
end
