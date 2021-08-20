defmodule Scenic.Component.Input.Toggle do
  @moduledoc """
  Add toggle to a Scenic graph.

  ## Data

  `on?`

  * `on?` - `true` if the toggle is on, pass `false` if not.

  ## Styles

  Toggles honor the following styles. The `:light` and `:dark` styles look nice. The other bundled themes...not so much. You can also [supply your own theme](Scenic.Toggle.Components.html#toggle/3-theme).

  * `:hidden` - If `false` the toggle is rendered. If true, it is skipped. The default
    is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ## Additional Styles

  Toggles also honor the following additional styles.

  * `:border_width` - the border width. Defaults to `2`.
  * `:padding` - the space between the border and the thumb. Defaults to `2`
  * `:thumb_radius` - the radius of the thumb. This determines the size of the entire toggle. Defaults to `10`.
  * `:compat` - use the pre-v0.11 positioning. The default is `false`

  ## Theme

  To pass in a custom theme, supply a map with at least the following entries:

  * `:border` - the color of the border around the toggle
  * `:background` - the color of the track when the toggle is `off`.
  * `:text` - the color of the thumb.
  * `:thumb` - the color of the track when the toggle is `on`.

  Optionally, you can supply the following entries:

  * `:thumb_pressed` - the color of the thumb when pressed. Defaults to `:gainsboro`.

  ## Usage

  You should add/modify components via the helper functions in
  [`Scenic.Components`](Scenic.Components.html#toggle/3)

  ## Examples

  The following example creates a toggle.
      graph
      |> toggle(true, translate: {20, 20})

  The next example makes a larger toggle.
      graph
      |> toggle(true, translate: {20, 20}, thumb_radius: 14)
  """
  use Scenic.Component, has_children: false

  alias Scenic.Scene
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Group
  alias Scenic.Primitive.Style.Theme
  alias Scenic.ViewPort

  import Scenic.Primitives

  require Logger

  # import IEx

  @default_thumb_pressed_color :gainsboro
  @default_thumb_radius 8
  @default_padding 2
  @default_border_width 2

  defmodule State do
    @moduledoc false

    defstruct graph: nil,
              # contained?: false,
              id: nil,
              on?: false,
              pressed?: false,
              theme: nil,
              thumb_translate: nil,
              color: nil,
              viewport: nil

    @type t :: %__MODULE__{
            viewport: ViewPort.t(),
            graph: Graph.t(),
            # contained?: boolean,
            id: atom,
            on?: boolean,
            pressed?: boolean,
            theme: map,
            thumb_translate: %{on: {number, number}, off: {number, number}},
            color: %{
              thumb: %{default: term, active: term},
              border: term,
              track: %{off: term, on: term}
            }
          }
  end

  # --------------------------------------------------------
  @impl Scenic.Component
  def validate(on?) when is_boolean(on?) do
    {:ok, on?}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Toggle specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a Toggle imust be a true or false#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  @spec init(scene :: Scene.t(), param :: any, Keyword.t()) :: {:ok, Scene.t()}
  def init(scene, on?, opts) do
    id = opts[:id]

    # theme is passed in as an inherited style
    theme =
      opts[:theme]
      |> Theme.normalize()

    # get toggle specific opts
    thumb_radius = Keyword.get(opts, :thumb_radius, @default_thumb_radius)
    padding = Keyword.get(opts, :padding, @default_padding)
    border_width = Keyword.get(opts, :border_width, @default_border_width)

    # calculate the dimensions of the track
    track_height = thumb_radius * 2 + 2 * padding + 2 * border_width
    track_width = thumb_radius * 4 + 2 * padding + 2 * border_width
    track_border_radius = thumb_radius + padding + border_width

    # tune final position
    # original behavior had the toggle higher up, use :compat for that mode
    dx = border_width / 2
    dy = border_width / 2

    color = %{
      thumb: %{
        default: theme.text,
        pressed?: Map.get(theme, :thumb_pressed, @default_thumb_pressed_color)
      },
      border: theme.border,
      track: %{
        off: theme.background,
        on: theme.thumb
      }
    }

    thumb_translate = %{
      off: {thumb_radius + padding + border_width, thumb_radius + padding + border_width},
      on: {thumb_radius * 3 + padding + border_width, thumb_radius + padding + border_width}
    }

    {initial_track_fill, initial_thumb_translate} =
      case on? do
        true -> {color.track.on, thumb_translate.on}
        false -> {color.track.off, thumb_translate.off}
      end

    graph =
      Graph.build()
      |> Group.add_to_graph(
        fn graph ->
          graph
          |> rrect({track_width, track_height, track_border_radius},
            fill: initial_track_fill,
            stroke: {border_width, theme.border},
            id: :track,
            input: :cursor_button
          )
          |> circle(thumb_radius,
            fill: color.thumb.default,
            id: :thumb,
            translate: initial_thumb_translate
          )
        end,
        translate: {dx, dy}
      )

    scene =
      scene
      |> assign(
        id: id,
        graph: graph,
        on?: on?,
        pressed?: false,
        theme: theme,
        thumb_translate: thumb_translate,
        color: color
      )
      |> push_graph(graph)

    {:ok, scene}
  end

  @impl Scenic.Component
  def bounds(_data, styles) do
    # get toggle specific styles
    thumb_radius = Map.get(styles, :thumb_radius, @default_thumb_radius)
    padding = Map.get(styles, :padding, @default_padding)
    border_width = Map.get(styles, :border_width, @default_border_width)

    # calculate the dimensions of the track
    track_height = thumb_radius * 2 + 2 * padding + 2 * border_width
    track_width = thumb_radius * 4 + 2 * padding + 2 * border_width

    {0, 0, track_width, track_height}
  end

  # --------------------------------------------------------
  # pressed in the button
  @doc false
  @impl Scenic.Scene
  def handle_input(
        {:cursor_button, {0, :press, _, _}},
        :track,
        %{assigns: %{graph: graph, color: color}} = scene
      ) do
    graph = update_highlight(graph, true, true, color)

    :ok = capture_input(scene, :cursor_button)

    scene =
      scene
      |> assign(pressed?: true)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # pressed outside the button
  # only happens when input is captured
  # could happen when reconnecting to a driver...
  def handle_input(
        {:cursor_button, {0, :press, _, _}},
        _id,
        %{assigns: %{graph: graph, color: color}} = scene
      ) do
    graph = update_highlight(graph, true, false, color)

    :ok = release_input(scene)

    scene =
      scene
      |> assign(pressed?: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # released inside the button
  def handle_input(
        {:cursor_button, {0, :release, _, _}},
        :track,
        %{
          assigns: %{
            pressed?: true,
            id: id,
            graph: graph,
            on?: on?,
            color: color
          }
        } = scene
      ) do
    send_parent_event(scene, {:value_changed, id, !on?})

    :ok = release_input(scene)

    graph =
      graph
      |> update_check(!on?, scene.assigns)
      |> update_highlight(false, true, color)

    scene =
      scene
      |> assign(graph: graph, on?: !on?, pressed?: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # released, but not in the button
  def handle_input(
        {:cursor_button, {0, :release, _, _}},
        _id,
        %{assigns: %{graph: graph, color: color}} = scene
      ) do
    graph = update_highlight(graph, false, false, color)

    :ok = release_input(scene)

    scene =
      scene
      |> assign(pressed?: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # ignore other button press events
  def handle_input({:cursor_button, {_, _, _, _}}, _id, scene) do
    {:noreply, scene}
  end

  # --------------------------------------------------------
  defp update_highlight(graph, pressed?, contained, color)

  defp update_highlight(graph, true, true, color) do
    Graph.modify(graph, :thumb, &Primitive.put_style(&1, :fill, color.thumb.pressed?))
  end

  defp update_highlight(graph, _, _, color) do
    Graph.modify(graph, :thumb, &Primitive.put_style(&1, :fill, color.thumb.default))
  end

  defp update_check(graph, true, %{color: color, thumb_translate: thumb}) do
    graph
    |> Graph.modify(:track, &Primitive.put_style(&1, :fill, color.track.on))
    |> Graph.modify(:thumb, &Primitive.put_transform(&1, :translate, thumb.on))
  end

  defp update_check(graph, false, %{color: color, thumb_translate: thumb}) do
    graph
    |> Graph.modify(:track, &Primitive.put_style(&1, :fill, color.track.off))
    |> Graph.modify(:thumb, &Primitive.put_transform(&1, :translate, thumb.off))
  end

  # --------------------------------------------------------
  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def handle_get(_, %{assigns: %{on?: on?}} = scene) do
    {:reply, on?, scene}
  end

  @doc false
  @impl Scenic.Scene
  def handle_put(v, %{assigns: %{on?: on?}} = scene) when v == on? do
    # no change
    {:noreply, scene}
  end

  def handle_put(on?, %{assigns: %{graph: graph, id: id}} = scene) when is_boolean(on?) do
    send_parent_event(scene, {:value_changed, id, on?})

    graph =
      graph
      |> update_check(on?, scene.assigns)

    scene =
      scene
      |> assign(graph: graph, on?: on?)
      |> push_graph(graph)

    {:noreply, scene}
  end

  def handle_put(v, %{assigns: %{id: id}} = scene) do
    Logger.warn(
      "Attempted to put an invalid value on Toggle id: #{inspect(id)}, value: #{inspect(v)}"
    )

    {:noreply, scene}
  end

  @doc false
  @impl Scenic.Scene
  def handle_fetch(_, %{assigns: %{on?: on?}} = scene) do
    {:reply, {:ok, on?}, scene}
  end
end
