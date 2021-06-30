#
#  Re-Created by Boyd Multerer on 2017-11-30.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Font do
  @moduledoc """
  Set the font used to draw text.

  Example:

      graph
      |> text("Hello World", font: :roboto)

  ## Data
      
  You can choose one of the named system fonts, or one you've loaded into the cache.

  * `:roboto` - The standard [Roboto](https://fonts.google.com/specimen/Roboto) sans-serif font.
  * `:roboto_mono` - The standard [Roboto Mono](https://fonts.google.com/specimen/Roboto+Mono) mono-spaced font.

  To use a font from the cache, set it's hash into the font style.


  Example:
      @my_font_path :code.priv_dir(:my_app)
                 |> Path.join("/static/fonts/my_font.ttf")
      @my_font_hash Scenic.Cache.Hash.file!( @my_font_path, :sha )

      @graph Graph.build()
      |> text("Hello World", font: @my_font_hash)

      def init(_, _opts) do
        # load the font into the cache
        Scenic.Cache.File.load(@my_font_path, @my_font_hash)

        {:ok, :some_state, push: @graph}
      end

  __Note 1:__ The font renderer used by Scenic is the fantastic
  [stb_truetype](https://github.com/nothings/stb/blob/master/stb_truetype.h) library.
  This renderer was developed for games, which is another way of saying it is not trying to
  be the all-renderer for all fonts. Don't be surprised if you find a TrueType font
  that doesn't work as expected.

  __Note 2:__ Other font renderers might become available in the future. The named system
  fonts should keep working, but custom TrueType fonts might need to be ported.

  It is up to you to test your custom font choices to see if they work for your application.
  """

  use Scenic.Primitive.Style

  alias Scenic.Assets.Static

  # import IEx

  # ============================================================================
  # data verification and serialization

  def validate(id) when is_atom(id) or is_bitstring(id) do
    with {:ok, id_str} <- Static.resolve_alias(id),
         {:ok, {:font, _}} <- Static.fetch(id_str) do
      {:ok, id_str}
    else
      {:ok, {:image, _}} -> err_is_an_image(id)
      {:error, :not_mapped} -> err_not_mapped(id)
      :error -> err_missing(id)
    end
  end

  def validate(invalid), do: err_invalid(invalid)

  defp err_is_an_image(id) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Font specification
      Received: #{inspect(id)}
      This is an image!!
      #{IO.ANSI.yellow()}
      The :font style must be an id that names an font in your Scenic.Assets.Static library#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_not_mapped(id) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Font specification
      Received: #{inspect(id)}
      The alias #{inspect(id)} is not mapped to an asset path
      #{IO.ANSI.yellow()}
      The :font style must be an id that names an font in your Scenic.Assets.Static library

      To resolve this, make sure the alias mapped to a file path in your config.
        config :scenic, :assets,
          module: MyApplication.Assets,
          alias: [
            my_font: "fonts/my_font.ttf"
          ]#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_missing(id) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Font specification
      Received: #{inspect(id)}
      The asset #{inspect(id)} could not be found.
      #{IO.ANSI.yellow()}
      The :font style must be an id that names an font in your Scenic.Assets.Static library

      To resolve this do the following checks.
        1) Confirm that the file exists in your assets folder.

        2) Make sure the font file is being compiled into your asset library.
          If this file is new, you may need to "touch" your asset library module to cause it to recompile.
          Maybe somebody will help add a filesystem watcher to do this automatically. (hint hint...)

        3) Check that and that the asset module is defined in your config.
          config :scenic, :assets,
            module: MyApplication.Assets #{IO.ANSI.default_color()}
      """
    }
  end

  def err_invalid(invalid) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Font specification
      Received: #{inspect(invalid)}
      #{IO.ANSI.yellow()}
      The :font style must be an id that names an font in your Scenic.Assets.Static library

      Examples:
        font: "fonts/my_font.ttf"
        font: :my_font{IO.ANSI.default_color()}
      """
    }
  end
end
