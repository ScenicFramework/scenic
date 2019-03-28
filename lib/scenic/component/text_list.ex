defmodule Scenic.Component.TextList do
  @moduledoc """
  Add a simple text list to a graph.

  A list is a small scene that enumerates over a list of strings.
  It creates text_specs for each item and increments the transforms
  Y by the `:font-size + 2` so each string is built below the previous
  one in the graph. There is no logic in this scene for events or updating.
  Warning, this scene builds the graph at runtime, NOT at compile time.

  ## Data

  `list`

  * `list` - a list of strings to be displayed in a horizontal list format.

  ## Styles

  Lists honor the following styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped. The default is `false`.
  * `:fill` - fill in the area of the text. Only solid colors!
  * `:font` - Name (or key) of font to use.
  * `:font_size` - Point size of the font. This is used in calculating transform for each additional line.
  * `:font_blur` - option to blur the characters
  * `:text_align` - alignment of lines of text
  * `:text_height` - spacing between lines of text
  * `:t` - Translate, used to specify where to start the list in your scene

  ## Usage

  You should add/modify components via the helper functions in
  [`Scenic.Components`](Scenic.Components.html#text_list/3)

  ### Examples

  The following example creates a simple list and adds it to the graph.

      list_of_strings = ["a", "b", "c"]

      graph
      |> text_list(list_of_strings, id: :alpha_list, fill: :green, font_size: 18, t: {0, 10})

  To remove the list use the `:id` you created the list with to delete it from the graph.

      graph
      |> Graph.delete(:alpha_list)

  """

  use Scenic.Component
  alias Scenic.Graph

  import Scenic.Primitives, only: [{:add_specs_to_graph, 2}, {:text_spec, 2}]

  @default_font :roboto
  @default_font_size 20
  @font_spacer 2

  def info(data),
    do: """
    #{IO.ANSI.red()}#{__MODULE__} data must be a list
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """

  def verify(list) when is_list(list), do: {:ok, list}
  def verify(_), do: :invalid_data

  def init(list, options) do
    styles = options[:styles]
    {tx, ty} = Map.get(styles, :t, {0, 0})
    increment = Map.get(styles, :font_size, @default_font_size) + @font_spacer

    specs =
      list
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        new_ty = increment * index + ty
        opts = Map.put(styles, :t, {tx, new_ty})
        text_spec(item, opts)
      end)

    new_graph =
      add_specs_to_graph(Graph.build(font: @default_font, font_size: @default_font_size), specs)

    {:ok, %{list: list, graph: new_graph}, push: new_graph}
  end
end
