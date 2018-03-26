defmodule Scenic.Component.Button do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.ViewPort.Input.Tracker

  import IEx


  @default_width      70
  @default_height     24
  @default_radius     6
  @default_type       6

  @blue_color         :steel_blue
  @text_color         :white

  @valid_types [:primary, :secondary, :success, :danger, :warning, :info, :light, :dark, :text]

  # type is {text_color, button_color, hover_color, pressed_color, border_color}
  # nil for text_color means to use whatever is inherited
  @types %{
    primary:    {:white, {72,122,252}, {60,104,214}, {58,94,201}, {164,186,253}},
    secondary:  {:white, {111,117,125}, :dark_blue, :light_blue, :clear},
    success:    {:white, {99,163,74}, :dark_blue, :light_blue, :clear},
    danger:     {:white, {191,72,71}, :dark_blue, :light_blue, :clear},
    warning:    {:white, {239,196,42}, :dark_blue, :light_blue, :clear},
    info:       {:white, {94,159,183}, :dark_blue, :light_blue, :clear},
    light:      {:white, :steel_blue, :dark_blue, :light_blue, :black},
    dark:       {:white, :steel_blue, :dark_blue, :light_blue, :clear},
    text:       {nil, :clear, :clear, :clear, :clear}
  }

  #--------------------------------------------------------
  def info() do
    "Button must be initialized with {{x,y},width,height,type}\r\n" <>
    "Type can be any of #{inspect(@valid_types)}"
  end

  #--------------------------------------------------------
  def valid?( {{x, y}, width, height, type} = data ) when
  is_number(x) and is_number(y) and
  is_number(width) and is_number(height) do
    Enum.member?(@valid_types, type)
  end
  def valid?( _ ), do: false

  #--------------------------------------------------------
  def normalize( name ) when is_atom(name),     do: normalize( {name, @default_point_size} )
  def normalize( key ) when is_bitstring(key),  do: normalize( {key, @default_point_size} )
  def normalize( {name, point_size} ) when is_integer(point_size) and
  point_size >=2 and point_size <= 80 do
    {name, point_size}
  end


  #--------------------------------------------------------
  def init( {{x, y}, w, h, r, text, type} = data ) do
IO.puts "BUTTON init --> #{inspect(self())}"
    # get the theme colors
    colors = @types[type]

    {text_color, button_color, _, _, border_color} = colors

    graph = Graph.build( font: {:roboto, 14} )
    |> Primitive.RoundedRectangle.add_to_graph( {{x,y}, w, h, r}, color: button_color,
      id: :btn )
    |> Primitive.Text.add_to_graph( {{x+8,y+17}, text}, color: text_color )

    ViewPort.put_graph( graph )

    state = %{
      graph: graph,
      colors: colors,
      pressed: false,
      contained: false
    }

    {:ok, state}
  end
#  def init( opts ) do
#IO.puts "BUTTON init generic --> #{inspect(opts)}"
#    {:ok, nil}
#  end

  def add_to_graph( graph, data ) do
    Primitive.SceneRef.add_to_graph(graph, {{__MODULE__, data}, nil})
  end


  #--------------------------------------------------------
  def handle_input( {:cursor_enter, uid}, context, state ) do
    state = Map.put(state, :contained, true)
    update_color(state)
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_exit, uid}, context, state ) do
    state = Map.put(state, :contained, false)
    update_color(state)
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :press, _, _}},
  context, state ) do
    state = Map.put(state, :pressed, true)
    update_color(state)

    ViewPort.capture_input( [:cursor_button, :cursor_pos], context)
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :release, _, _}},
  context, state ) do
    state = Map.put(state, :pressed, false)
    update_color(state)

    ViewPort.release_input( [:cursor_button, :cursor_pos])
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( event, context, state ) do
    {:noreply, state}
  end



  defp update_color( %{ graph: graph, colors: {_,color,_,_,_},
  pressed: false, contained: false} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:color, color)
    end)
    |> ViewPort.put_graph()
  end

  defp update_color( %{ graph: graph, colors: {_,_,color,_,_},
  pressed: false, contained: true} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:color, color)
    end)
    |> ViewPort.put_graph()
  end

  defp update_color( %{ graph: graph, colors: {_,color,_,_,_},
  pressed: true, contained: false} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:color, color)
    end)
    |> ViewPort.put_graph()
  end

  defp update_color( %{ graph: graph, colors: {_,_,_,color,_},
  pressed: true, contained: true} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:color, color)
    end)
    |> ViewPort.put_graph()
  end

end










