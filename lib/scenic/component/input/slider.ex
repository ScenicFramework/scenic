defmodule Scenic.Component.Input.Slider do
  @moduledoc """
  Add a slider to a graph

  ## Data

  `{ extents, initial_value}`

  * `extents` gives the range of values. It can take several forms...
    * `{min, max}` If `min` and `max` are integers, then the slider value will
    be an integer.
    * `{min, max}` If `min` and `max` are floats, then the slider value will be
    an float.
    * `[a, b, c]` A list of terms. The value will be one of the terms
  * `initial_value` Sets the initial value (and position) of the slider. It
  must make sense with the extents you passed in.

  ## Messages

  When the state of the slider changes, it sends an event message to the host
  scene in the form of:

  `{:value_changed, id, value}`

  ### Options

  Sliders honor the following list of options.

  ## Styles

  Sliders honor the following styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ## Theme

  Sliders work well with the following predefined themes: `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:border` - the color of the slider line
  * `:thumb` - the color of slider thumb

  ## Usage

  You should add/modify components via the helper functions in
  [`Scenic.Components`](Scenic.Components.html#slider/3)

  ## Examples

  The following example creates a numeric slider and positions it on the screen.

      graph
      |> slider({{0,100}, 0}, id: :num_slider, translate: {20,20})

  The following example creates a list slider and positions it on the screen.

      graph
      |> slider({[
          :white,
          :cornflower_blue,
          :green,
          :chartreuse
        ], :cornflower_blue}, id: :slider_id, translate: {20,20})
  """

  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive.Style.Theme
  import Scenic.Primitives, only: [{:rect, 3}, {:line, 3}, {:rrect, 3}, {:update_opts, 2}]

  require Logger

  # import IEx

  @height 18
  @mid_height trunc(@height / 2)
  @radius 5
  @btn_size 16
  @line_width 4

  @default_width 300

  # --------------------------------------------------------
  @impl Scenic.Component

  def validate({{min, max}, initial} = data)
      when is_number(min) and is_number(max) and is_number(initial) do
    cond do
      min > max -> err_min_max(data)
      initial < min -> err_min(data)
      initial > max -> err_max(data)
      true -> {:ok, data}
    end
  end

  def validate({values, initial} = data) when is_list(values) do
    case Enum.member?(values, initial) do
      true -> {:ok, data}
      false -> err_initial_value(data)
    end
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Slider specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a Slider is {extents, initial}

      The extents can be either a list of values or a {min, max} tuple.

      If this is a numerical slider, then min <= initial <= max.

      If this is a list slider, then the initial value must be in the list of values.#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_min_max({{min, max}, _} = data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Slider specification
      Received: #{inspect(data)}
      The initial min value #{inspect(min)} is above the max of #{inspect(max)}.
      #{IO.ANSI.yellow()}
      The data for a numerical Slider is {{min, max}, initial}

      The values must follow: min <= initial <= max.#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_min({{min, _}, initial} = data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Slider specification
      Received: #{inspect(data)}
      The initial value #{inspect(initial)} is below the min of #{inspect(min)}.
      #{IO.ANSI.yellow()}
      The data for a numerical Slider is {{min, max}, initial}

      The values must follow: min <= initial <= max.#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_max({{_, max}, initial} = data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Slider specification
      Received: #{inspect(data)}
      The initial value #{inspect(initial)} is above the max of #{inspect(max)}.
      #{IO.ANSI.yellow()}
      The data for a numerical Slider is {{min, max}, initial}

      The values must follow: min <= initial <= max.#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_initial_value({_values, initial} = data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Slider specification
      Received: #{inspect(data)}
      The initial value #{inspect(initial)} is not in the list of values.
      #{IO.ANSI.yellow()}
      The data for a list of values Slider is {values, initial_value}

      The initial value must be in the list of values.#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def init(scene, {extents, value}, opts) do
    id = opts[:id]

    request_input(scene, :cursor_button)

    # theme is passed in as an inherited style
    theme =
      (opts[:theme] || Theme.preset(:primary))
      |> Theme.normalize()

    # get button specific styles
    width = opts[:width] || @default_width

    graph =
      Graph.build()
      |> rect({width, @height}, fill: :clear, t: {0, -1}, id: :hit_rect, input: :cursor_button)
      |> line({{0, @mid_height}, {width, @mid_height}}, stroke: {@line_width, theme.border})
      |> rrect({@btn_size, @btn_size, @radius}, fill: theme.thumb, id: :thumb, t: {0, 1})
      |> update_slider_position(value, extents, width)

    scene =
      scene
      |> assign(
        graph: graph,
        value: value,
        extents: extents,
        width: width,
        id: id,
        tracking: false
      )
      |> push_graph(graph)

    {:ok, scene}
  end

  @impl Scenic.Component
  def bounds(_data, opts) do
    {0, 0, opts[:width] || @default_width, @height}
  end

  # ============================================================================

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def handle_input({:cursor_button, {0, :press, _, {x, _}}}, :hit_rect, scene) do
    :ok = capture_input(scene, [:cursor_button, :cursor_pos, :viewport])

    scene =
      scene
      |> assign(:tracking, true)
      |> update_slider(x)

    {:noreply, scene}
  end

  def handle_input({:cursor_button, {0, :release, _, _xy}}, _id, scene) do
    scene = assign(scene, :tracking, false)
    release_input(scene)
    {:noreply, scene}
  end

  def handle_input({:cursor_pos, {x, _}}, _id, %{assigns: %{tracking: true}} = scene) do
    {:noreply, update_slider(scene, x)}
  end

  def handle_input({:viewport, {:exit, _}}, _id, %{assigns: %{tracking: true}} = scene) do
    scene = assign(scene, :tracking, false)
    release_input(scene)
    {:noreply, scene}
  end

  # ignore other input
  def handle_input(_input, _id, scene) do
    {:noreply, scene}
  end

  # ============================================================================
  # internal utilities
  # {text_color, box_background, border_color, pressed_color, checkmark_color}

  defp update_slider(
         %{
           assigns: %{
             graph: graph,
             value: old_value,
             extents: extents,
             width: width,
             id: id
           }
         } = scene,
         x
       ) do
    # pin x to be inside the width
    x =
      cond do
        x < 0 -> 0
        x > width -> width
        true -> x
      end

    # calc the new value based on its position across the slider
    new_value = calc_value_by_percent(extents, x / width)

    # update the slider position
    graph = update_slider_position(graph, new_value, extents, width)

    if new_value != old_value do
      send_parent_event(scene, {:value_changed, id, new_value})
    end

    scene
    |> push_graph(graph)
    |> assign(graph: graph, value: new_value)
  end

  # --------------------------------------------------------
  defp update_slider_position(graph, new_value, extents, width) do
    # calculate the slider position
    new_x = calc_slider_position(width, extents, new_value)

    # apply the x position
    Graph.modify(graph, :thumb, fn p ->
      update_opts(p, translate: {new_x, 0})
    end)
  end

  # --------------------------------------------------------
  # calculate the position if the extents are numeric
  defp calc_slider_position(width, extents, value)

  defp calc_slider_position(width, {min, max}, value) when value < min do
    calc_slider_position(width, {min, max}, min)
  end

  defp calc_slider_position(width, {min, max}, value) when value > max do
    calc_slider_position(width, {min, max}, max)
  end

  defp calc_slider_position(width, {min, max}, value) do
    width = width - @btn_size
    percent = (value - min) / (max - min)
    trunc(width * percent)
  end

  # --------------------------------------------------------
  # calculate the position if the extents is a list of arbitrary values

  defp calc_slider_position(width, ext, value) when is_list(ext) do
    max_index = Enum.count(ext) - 1

    index =
      case Enum.find_index(ext, fn v -> v == value end) do
        nil -> raise "Slider value not in extents list"
        index -> index
      end

    # calc position of slider
    width = width - @btn_size
    percent = index / max_index
    round(width * percent)
  end

  # --------------------------------------------------------
  defp calc_value_by_percent({min, max}, percent) when is_integer(min) and is_integer(max) do
    round((max - min) * percent) + min
  end

  defp calc_value_by_percent({min, max}, percent) when is_float(min) and is_float(max) do
    (max - min) * percent + min
  end

  defp calc_value_by_percent(extents, percent) when is_list(extents) do
    max_index = Enum.count(extents) - 1
    index = round(max_index * percent)
    Enum.at(extents, index)
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
            graph: graph,
            extents: extents,
            width: width,
            id: id
          }
        } = scene
      )
      when is_list(extents) do
    scene =
      case Enum.member?(extents, value) do
        false ->
          Logger.warn(
            "Attempted to put an invalid value on Slider id: #{inspect(id)}, value: #{inspect(value)}"
          )

          scene

        true ->
          send_parent_event(scene, {:value_changed, id, value})
          new_x = calc_slider_position(width, extents, value)

          graph =
            Graph.modify(graph, :thumb, fn p ->
              update_opts(p, translate: {new_x, 0})
            end)

          scene
          |> assign(graph: graph, value: value)
          |> push_graph(graph)
      end

    {:noreply, scene}
  end

  def handle_put(
        value,
        %{
          assigns: %{
            graph: graph,
            extents: {min, max} = extents,
            width: width,
            id: id
          }
        } = scene
      )
      when is_number(value) and value >= min and value <= max do
    send_parent_event(scene, {:value_changed, id, value})
    new_x = calc_slider_position(width, extents, value)

    graph =
      Graph.modify(graph, :thumb, fn p ->
        update_opts(p, translate: {new_x, 0})
      end)

    scene =
      scene
      |> assign(graph: graph, value: value)
      |> push_graph(graph)

    {:noreply, scene}
  end

  def handle_put(v, %{assigns: %{id: id}} = scene) do
    Logger.warn(
      "Attempted to put an invalid value on Slider id: #{inspect(id)}, value: #{inspect(v)}"
    )

    {:noreply, scene}
  end

  @doc false
  @impl Scenic.Scene
  def handle_fetch(_, %{assigns: %{extents: extents, value: value}} = scene) do
    {:reply, {:ok, {extents, value}}, scene}
  end
end
