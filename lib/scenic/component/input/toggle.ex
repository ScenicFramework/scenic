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

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Group
  alias Scenic.Primitive.Style.Theme
  alias Scenic.ViewPort

  import Scenic.Primitives

  @default_thumb_pressed_color :gainsboro
  @default_thumb_radius 8
  @default_padding 2
  @default_border_width 2

  defmodule State do
    @moduledoc false

    defstruct graph: nil,
              contained?: false,
              id: nil,
              on?: false,
              pressed?: false,
              theme: nil,
              thumb_translate: nil,
              color: nil

    @type t :: %__MODULE__{
            graph: Graph.t(),
            contained?: boolean,
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
  @doc false
  def info(data) do
    """
    #{IO.ANSI.red()}Toggle data must be: on?
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  @doc false
  @spec verify(any) :: {:ok, boolean} | :invalid_data
  def verify(on? = data) when is_boolean(on?) do
    {:ok, data}
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  @doc false
  @spec init(any, Keyword.t() | map | nil) :: {:ok, State.t()}
  def init(on?, opts) do
    id = opts[:id]

    styles = opts[:styles]

    # theme is passed in as an inherited style
    theme =
      (styles[:theme] || Theme.preset(:primary))
      |> Theme.normalize()

    # get toggle specific styles
    thumb_radius = Map.get(styles, :thumb_radius, @default_thumb_radius)
    padding = Map.get(styles, :padding, @default_padding)
    border_width = Map.get(styles, :border_width, @default_border_width)

    # calculate the dimensions of the track
    track_height = thumb_radius * 2 + 2 * padding + 2 * border_width
    track_width = thumb_radius * 4 + 2 * padding + 2 * border_width
    track_border_radius = thumb_radius + padding + border_width

    color = %{
      thumb: %{
        default: theme.text,
        pressed: Map.get(theme, :thumb_pressed, @default_thumb_pressed_color)
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
            id: :track
          )
          |> circle(thumb_radius,
            fill: color.thumb.default,
            id: :thumb,
            translate: initial_thumb_translate
          )
        end,
        translate: {border_width, -(thumb_radius + padding + border_width)}
      )

    # |> text(text, fill: theme.text, translate: {20, 0})

    state = %State{
      contained?: false,
      id: id,
      graph: graph,
      on?: on?,
      pressed?: false,
      theme: theme,
      thumb_translate: thumb_translate,
      color: color
    }

    push_graph(graph)

    {:ok, state}
  end

  # --------------------------------------------------------
  @doc false
  def handle_input({:cursor_enter, _uid}, _, %{pressed?: true} = state) do
    state = Map.put(state, :contained?, true)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_exit, _uid}, _, %{pressed?: true} = state) do
    state = Map.put(state, :contained?, false)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_button, {:left, :press, _, _}}, context, state) do
    state =
      state
      |> Map.put(:pressed?, true)
      |> Map.put(:contained?, true)

    graph = update_graph(state)

    ViewPort.capture_input(context, [:cursor_button, :cursor_pos])

    {:noreply, %{state | graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_button, {:left, :release, _, _}},
        context,
        %{contained?: contained?, id: id, on?: on?, pressed?: pressed?} = state
      ) do
    state = Map.put(state, :pressed?, false)

    ViewPort.release_input(context, [:cursor_button, :cursor_pos])

    # only do the action if the cursor is still contained in the target
    state =
      case pressed? && contained? do
        true ->
          on? = !on?
          send_event({:value_changed, id, on?})
          Map.put(state, :on?, on?)

        false ->
          state
      end

    graph = update_graph(state)

    {:noreply, %{state | graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  @spec update_graph(State.t()) :: Graph.t()
  defp update_graph(%{
         color: color,
         contained?: contained?,
         graph: graph,
         on?: on?,
         pressed?: pressed?,
         thumb_translate: thumb_translate
       }) do
    graph =
      case pressed? && contained? do
        true ->
          Graph.modify(graph, :thumb, &Primitive.put_style(&1, :fill, color.thumb.pressed))

        false ->
          Graph.modify(graph, :thumb, &Primitive.put_style(&1, :fill, color.thumb.default))
      end

    graph =
      case on? do
        true ->
          graph
          |> Graph.modify(:track, &Primitive.put_style(&1, :fill, color.track.on))
          |> Graph.modify(:thumb, &Primitive.put_transform(&1, :translate, thumb_translate.on))

        false ->
          graph
          |> Graph.modify(:track, &Primitive.put_style(&1, :fill, color.track.off))
          |> Graph.modify(:thumb, &Primitive.put_transform(&1, :translate, thumb_translate.off))
      end

    push_graph(graph)
  end
end
