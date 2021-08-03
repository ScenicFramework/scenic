#
#  Re-Created by Boyd Multerer on 2017-11-30.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Font do
  @moduledoc """
  Set the font used to draw text.

  Example:

  ```elixir
  graph
    |> text( "Hello World", font: "fonts/my_fancy_font.ttf" )
  ```

  ### Data Format
      
  You can use any font loaded into your static assets library. You can also
  refer to the font by either it's library file name, or an alias that you
  have configured.

  The following example shows both ways to identify a font.
  ```elixir
  Graph.build()
    |> text( "By name", font: "fonts/roboto.ttf" )
    |> text( "By alias", font: :roboto )
  ```

  # Standard Fonts

  You are highly encouraged to use Roboto and Roboto Mono as the standard system
  fonts for Scenic. Aliases are automatically set up for them.

  | Alias          | Font  |
  |---------------|------------------------|
  |  `:roboto` | "fonts/roboto.ttf" |
  |  `:roboto_mono` | "fonts/roboto_mono.ttf" |

  It is expected that you will include the roboto.ttf and roboto_mono.ttf files
  in your asset source folder. You don't technically need to, but if you don't
  then those aliases won't work.
  """

  use Scenic.Primitive.Style

  alias Scenic.Assets.Static

  # import IEx

  # ============================================================================
  # data verification and serialization

  @doc false
  def validate(id) do
    case Static.meta(id) do
      {:ok, {Static.Font, _}} -> {:ok, id}
      {:ok, {Static.Image, _}} -> err_is_an_image(id)
      _ -> err_missing(id)
    end
  end

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
