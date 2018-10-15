#
#  Re-Created by Boyd Multerer on 2017-11-30.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Font do
  @moduledoc """
  Set the font used to draw text.

  Example:

      graph
      |> text("Hello World", font: :roboto)

  ## Data
      
  You can choose one of the three named system fonts, or one you've loaded into the cache.

  * `:roboto` - The standard [Roboto](https://fonts.google.com/specimen/Roboto) sans-serif font.
  * `:roboto_slab` - The standard [Roboto Slab](https://fonts.google.com/specimen/Roboto+Slab) serifed font.
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

        push_graph(@graph)

        {:ok, @graph}
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

  # import IEx

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a cache key or an atom
      #{IO.ANSI.yellow()}Received: #{inspect(data)}

      "Examples:
      :roboto             # system font
      \"w29afwkj23ry8\"   # key of font in the cache

      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(font) do
    try do
      normalize(font)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  @doc false
  def normalize(name) when is_atom(name), do: name
  def normalize(key) when is_bitstring(key), do: key
end
