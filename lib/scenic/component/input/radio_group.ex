defmodule Scenic.Component.Input.RadioGroup do
  @moduledoc """
  Add a radio group to a graph

  ## Data

  `radio_buttons`

  * `radio_buttons` must be a list of radio button data. See below.

  Radio button data:

  `{text, radio_id, checked? \\\\ false}`

  * `text` - must be a bitstring
  * `button_id` - can be any term you want. It will be passed back to you as the
  group's value.
  * `checked?` - must be a boolean and indicates if the button is selected.
  `checked?` is not required and will default to `false` if not supplied.

  ## Messages

  When the state of the radio group changes, it sends an event message to the
  host scene in the form of:

  `{:value_changed, id, radio_id}`

  ## Options

  Radio Buttons honor the following list of options.

  * `:theme` - This sets the color scheme of the button. This can be one of
  pre-defined button schemes `:light`, `:dark`, or it can be a completely custom
  scheme like this: `{text_color, box_background, border_color, pressed_color,
  checkmark_color}`.

  ## Styles

  Radio Buttons honor the following styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ## Theme

  Radio buttons work well with the following predefined themes: `:light`,
  `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text
  * `:background` - the background of the component
  * `:border` - the border of the component
  * `:active` - the background of the circle while the button is pressed
  * `:thumb` - the color of inner selected-mark

  ## Usage

  You should add/modify components via the helper functions in
  [`Scenic.Components`](Scenic.Components.html#radio_group/3)

  ## Examples

  The following example creates a radio group and positions it on the screen.

      graph
      |> radio_group([
          {"Radio A", :radio_a},
          {"Radio B", :radio_b, true},
          {"Radio C", :radio_c},
        ], id: :radio_group_id, translate: {20, 20})
  """

  use Scenic.Component, has_children: true

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.Component.Input.RadioButton
  import Scenic.Primitives, only: [{:group, 2}]

  #  import IEx

  @line_height 22

  # --------------------------------------------------------
  @doc false
  def info(data) do
    """
    #{IO.ANSI.red()}RadioGroup data must be a list of items
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    Each item in the list must be valid data for Scenic.Component.Input.RadioButton

    Example:
    [
      {"Radio A", :radio_a},
      {"Radio B", :radio_b, true},
      {"Radio C", :radio_c, false}
    ]

    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  @doc false
  def verify(items) when is_list(items) do
    items
    |> Enum.all?(fn item ->
      case RadioButton.verify(item) do
        {:ok, _} -> true
        _ -> false
      end
    end)
    |> case do
      true -> {:ok, items}
      _ -> :invalid_data
    end
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  @doc false
  def init(items, opts) when is_list(items) do
    id = opts[:id]
    styles = opts[:styles]

    graph =
      Graph.build()
      |> group(fn graph ->
        {graph, _} =
          Enum.reduce(items, {graph, 0}, fn
            {t, m}, {g, voffset} ->
              g =
                RadioButton.add_to_graph(g, {t, m, false}, translate: {0, voffset}, styles: styles)

              {g, voffset + @line_height}

            {t, m, v}, {g, voffset} ->
              g = RadioButton.add_to_graph(g, {t, m, v}, translate: {0, voffset}, styles: styles)
              {g, voffset + @line_height}
          end)

        graph
      end)

    value =
      Enum.find_value(items, fn
        {_t, _m} -> nil
        {_t, _m, false} -> nil
        {_t, m, true} -> m
      end)

    state = %{
      graph: graph,
      value: value,
      id: id
    }

    push_graph(graph)

    {:ok, state}
  end

  # # --------------------------------------------------------
  # def handle_cast({:set_value, new_value}, state) do
  #   {:noreply, %{state | value: new_value}}
  # end

  # ============================================================================

  @doc false
  def filter_event({:click, btn_id}, _from, %{id: id} = state) do
    Scene.cast_to_refs(nil, {:set_to_msg, btn_id})

    send_event({:value_changed, id, btn_id})
    {:stop, %{state | value: btn_id}}
  end

  def filter_event(msg, _from, state) do
    {:continue, msg, state}
  end
end
