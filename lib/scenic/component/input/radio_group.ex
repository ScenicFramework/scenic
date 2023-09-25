defmodule Scenic.Component.Input.RadioGroup do
  @moduledoc """
  Add a radio group to a graph

  The data format for RadioGroup has changed since v0.10!

  ## Data

  `{radio_buttons, checked_id}`

  * `radio_buttons` must be a list of radio button data. See below.
  * `checked_id` Is the id of the currently selected radio from the list.

  radio_buttons list:

  `{text, radio_id}`

  * `text` - must be a bitstring
  * `button_id` - can be any term you want. It will be passed back to you as the
  group's value.
  * `checked?` - must be a boolean and indicates if the button is selected.
  `checked?` is not required and will default to `false` if not supplied.

  Example showing the full data format
  ```elixir
  {[{"One", :one}, {"Two", :two}, {"Three", :three}], :two}
  ```

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
      |> radio_group({[
          {"Radio A", :radio_a},
          {"Radio B", :radio_b},
          {"Radio C", :radio_c},
        ], :radio_b}, 
        id: :radio_group_id, translate: {20, 20})
  """

  use Scenic.Component, has_children: true

  alias Scenic.Graph
  alias Scenic.Assets.Static
  alias Scenic.Component.Input.RadioButton
  import Scenic.Primitives, only: [{:group, 2}]

  require Logger

  # import IEx

  @default_font :roboto
  @default_font_size 20
  @border_width 2
  @line_height @default_font_size + @border_width + @border_width

  # --------------------------------------------------------
  @impl Scenic.Component
  def validate({items, _} = data) when is_list(items) do
    # confirm all the entries
    Enum.reduce(items, {:ok, data}, fn
      _, {:error, _} = error -> error
      {text, _}, acc when is_bitstring(text) -> acc
      item, _ -> err_bad_item(item, data)
    end)
    |> case do
      {:error, _} = err ->
        err

      {:ok, {items, initial}} ->
        # confirm that initial is in the items list
        items
        |> Enum.any?(fn {_, id} -> id == initial end)
        |> case do
          true -> {:ok, data}
          false -> err_initial(data)
        end
    end
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid RadioGroup specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      RadioGroup data must formed like: {[{text, id}], initial_id}

      This is a list of text/id pairs, and the id of the pair that is initially selected.

      NOTE: This has changed from v.10 and prior. You used to specify the selected radio inside
      the list, but now the current id has moved out into a tuple.
      #{IO.ANSI.default_color()}
      """
    }
  end

  defp err_bad_item(item, data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid RadioGroup specification
      Received: #{inspect(data)}
      Invalid Item: #{inspect(item)}
      #{IO.ANSI.yellow()}
      RadioGroup data must formed like: {[{text, id}], initial_id}

      This is a list of text/id pairs, and the id of the pair that is initially selected.#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_initial({_, initial} = data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid RadioGroup specification
      Received: #{inspect(data)}
      The initial id #{inspect(initial)} is not in the listed items
      #{IO.ANSI.yellow()}
      RadioGroup data must formed like: {[{text, id}], initial_id}

      This is a list of text/id pairs, and the id of the pair that is initially selected.#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def init(scene, {items, initial_id}, opts) when is_list(items) do
    id = opts[:id]

    graph =
      Graph.build()
      |> group(fn graph ->
        {graph, _} =
          Enum.reduce(items, {graph, 0}, fn
            {t, i}, {g, voffset} ->
              g =
                RadioButton.add_to_graph(
                  g,
                  {t, i, i == initial_id},
                  opts
                  |> Keyword.put(:translate, {0, voffset})
                  |> Keyword.put(:id, i)
                )

              {g, voffset + @line_height}
          end)

        graph
      end)

    scene =
      scene
      |> push_graph(graph)
      |> assign(
        value: initial_id,
        items: items,
        id: id
      )

    {:ok, scene}
  end

  @impl Scenic.Component
  def bounds({items, _id}, _opts) do
    {:ok, {Static.Font, fm}} = Static.meta(@default_font)
    ascent = FontMetrics.ascent(@default_font_size, fm)

    # find the longest text width
    fm_width =
      Enum.reduce(items, 0, fn {text, _}, w ->
        tw = FontMetrics.width(text, @default_font_size, fm)

        case tw > w do
          true -> tw
          false -> w
        end
      end)

    space_width = FontMetrics.width(~c" ", @default_font_size, fm)
    box_width = fm_width + ascent + space_width + @border_width
    {0, 0, box_width, @line_height * Enum.count(items)}
  end

  # ============================================================================

  @doc false
  @impl Scenic.Scene
  def handle_event({:click, btn_id}, _from, %{assigns: %{id: id}} = scene) do
    :ok = cast_children(scene, {:set_to_msg, btn_id})
    :ok = send_parent_event(scene, {:value_changed, id, btn_id})
    {:halt, assign(scene, value: btn_id)}
  end

  # --------------------------------------------------------

  @doc false
  @impl Scenic.Scene
  def handle_get(_, %{assigns: %{value: value}} = scene) do
    {:reply, value, scene}
  end

  @doc false
  @impl Scenic.Scene
  def handle_put(v, %{assigns: %{value: value}} = scene) when v == value do
    # no change
    {:noreply, scene}
  end

  def handle_put(
        value,
        %{
          assigns: %{
            items: items,
            id: id
          }
        } = scene
      ) do
    # find the newly selected item's text
    scene =
      case Enum.find(items, fn {_, id} -> id == value end) do
        nil ->
          Logger.warning(
            "Attempted to put an invalid value on Radio Group id: #{inspect(id)}, value: #{inspect(value)}"
          )

          scene

        {_, _} ->
          # send the value_changed message
          send_parent_event(scene, {:value_changed, id, value})
          :ok = cast_children(scene, {:set_to_msg, value})
          assign(scene, value: value)
      end

    {:noreply, scene}
  end

  def handle_put(v, %{assigns: %{id: id}} = scene) do
    Logger.warning(
      "Attempted to put an invalid value on Dropdown id: #{inspect(id)}, value: #{inspect(v)}"
    )

    {:noreply, scene}
  end

  @doc false
  @impl Scenic.Scene
  def handle_fetch(_, %{assigns: %{items: items, value: value}} = scene) do
    {:reply, {:ok, {items, value}}, scene}
  end
end
