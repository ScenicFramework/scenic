#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.Image do
  alias Scenic.Assets.Static

  @moduledoc """
  Fill a primitive with an image from Scenic.Assets.Static

  ### Data Format

  `{:image, id}`

  Fill with the static image indicated by `id`

  The `id` can be either the name of the file when the static assets library was built
  or an alias that you set up in your conig. The following example has the alias
  `:parrot` pointing to the `"images/parrot.png"` file, so both fills are identical.

  ```elixir
  Graph.build()
    |> rect({100, 50}, fill: {:image, "images/parrot.jpg"})
    |> rect({100, 50}, fill: {:image, :parrot})
  ```

  Note that this is a fill, and the images will repeat automatically if the primitive
  being filled is larger than the source image.

  If you want more control, such as no repeats, a subsection of the image, or scaling
  the image up or down when you draw it, use the `Sprites` primitive.
  """

  @doc false
  def validate({:image, id}) when is_atom(id) or is_bitstring(id) do
    with {:ok, id_str} <- Static.resolve_id(id),
         {:ok, {Static.Image, _}} <- Static.fetch(id_str) do
      {:ok, {:image, id_str}}
    else
      {:ok, {Static.Font, _}} -> err_is_a_font(id)
      {:error, :not_mapped} -> err_not_mapped(id)
      {:error, :not_found} -> err_missing(id)
    end
  end

  def validate(data), do: err_invalid(data)

  defp err_is_a_font(_) do
    {
      :error,
      """
      This is a font!!
      #{IO.ANSI.yellow()}
      Image fills must be an id that names an image in your Scenic.Assets.Static library.#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_not_mapped(id) do
    {
      :error,
      """
      The alias #{inspect(id)} is not mapped to an asset path
      #{IO.ANSI.yellow()}
      Image fills must be an id that names an image in your Scenic.Assets.Static library.

      To resolve this, make sure the alias mapped to a file path in your config.
        config :scenic, :assets,
          module: MyApplication.Assets,
          alias: [
            parrot: "images/parrot.jpg"
          ]#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_missing(id) do
    {
      :error,
      """
      The asset #{inspect(id)} could not be found.
      #{IO.ANSI.yellow()}
      Image fills must be an id that names an image in your Scenic.Assets.Static library.

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

  defp err_invalid(_) do
    {
      :error,
      """
      #{IO.ANSI.yellow()}
      Image fills must be an id that names an image in your Scenic.Assets.Static library.

      Valid image ids can be the path or an alias to a file in your assets library.

      Examples:
        fill: {:image, "images/parrot.jpg"}
        fill: {:image, :parrot}#{IO.ANSI.default_color()}
      """
    }
  end
end
