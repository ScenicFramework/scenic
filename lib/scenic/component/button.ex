defmodule Scenic.Component.Button do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.Primitive
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
    primary:    {:white, :steel_blue, :dark_blue, :light_blue, :clear},
    secondary:  {:white, :steel_blue, :dark_blue, :light_blue, :clear},
    success:    {:white, :steel_blue, :dark_blue, :light_blue, :clear},
    danger:     {:white, :steel_blue, :dark_blue, :light_blue, :clear},
    warning:    {:white, :steel_blue, :dark_blue, :light_blue, :clear},
    info:       {:white, :steel_blue, :dark_blue, :light_blue, :clear},
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
  def init( {{x, y}, w, h, r, text, type} ) do
    # get the theme colors
    colors = @types[type]

    {text_color, button_color, _, _, _} = colors

    graph = Graph.build( font: {:roboto, 14} )
    |> Primitive.RoundedRectangle.add_to_graph( {{x,y}, w, h, r}, color: button_color )
    |> Primitive.Text.add_to_graph( {{x+8,y+17}, text}, color: text_color )

#pry()
#    GenServer.cast( self(), :after_init )

IO.puts "--------> init Button"

    {:ok, {graph, colors}}
  end
  def init( opts ) do
    pry()
  end

  #--------------------------------------------------------
  def handle_cast(:after_init, {graph, colors}) do
pry()
    ViewPort.put_graph( graph )
pry()
    {:noreply, {graph, colors}}
  end


  def add_to_graph( graph, data ) do
    Primitive.SceneRef.add_to_graph(graph, {{__MODULE__, data}, nil})
  end


  #--------------------------------------------------------
  def handle_input( {:cursor_enter, uid}, context, {graph, {_,_,color,_,_} = colors} ) do
    graph = Graph.modify(graph, uid, fn(p)->
      Primitive.put_style(p, :color, color)
    end)
    Scenic.ViewPort.set_graph( graph )
    {:noreply, {graph, colors}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_exit, uid}, context, {graph, {_,color,_,_,_}} = state ) do
    graph = Graph.modify(graph, uid, fn(p)->
      Primitive.put_style(p, :color, color)
    end)
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( event, context, state ) do
    IO.puts "BUTTON #{inspect(event)}"
    {:noreply, state}
  end

end










