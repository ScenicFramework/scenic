defmodule Scenic.Component.Input.Toggle do
  @moduledoc """
  An on/off toggle component

  See the [Components](Scenic.Toggle.Components.html#toggle/2) module for usage
  """

  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Group
  alias Scenic.Primitive.Style.Theme
  alias Scenic.ViewPort

  import Scenic.Primitives

  @default_thumb_pressed_color :gainsboro
  @default_thumb_radius 10
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

  #  #--------------------------------------------------------
  def info(data) do
    """
    #{IO.ANSI.red()}Toggle data must be: on?
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  @spec verify(any) :: {:ok, boolean} | :invalid_data
  def verify(on? = data) when is_boolean(on?) do
    {:ok, data}
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
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
