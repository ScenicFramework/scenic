defmodule Scenic.Component.Button do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [{:rrect, 3}, {:text, 3}]

  # type is {text_color, button_color, pressed_color}
  @colors %{
    primary:    {:white, {72,122,252}, {58,94,201}},
    secondary:  {:white, {111,117,125}, {86,90,95}},
    success:    {:white, {99,163,74}, {74,123,56}},
    danger:     {:white, {191,72,71}, {164,54,51}},
    warning:    {:black, {239,196,42}, {197,160,31}},
    info:       {:white, {94,159,183}, {70,119,138}},
    light:      {:black, {248,249,250}, {220,224,229}},
    dark:       {:white, {54,58,64}, {31,33,36}},
    text:       {{72,122,252}, :clear, :clear}
  }

  @default_width      80
  @default_height     30
  @default_radius     3
  @default_font       :roboto
  @default_font_size  20

#  #--------------------------------------------------------
  def info() do
#    "#{IO.ANSI.red()}Button must be initialized with {{x,y}, text, message, opts}#{IO.ANSI.default_color()}\r\n" <>
    "#{IO.ANSI.red()}Button data must be: {text, message, opts}#{IO.ANSI.default_color()}\r\n" <>
    "Position the button with a transform\r\n" <>
    "The message will be sent to you in a click event when the button is used.\r\n" <>
    "Options can be {:width, width} {:height, height}, {:radius, raidus}, and {:color, color}\r\n" <>
    "The color can be wone of the following presets:\r\n"
    ":primary, :secondary, :success, :danger, :warning, :info, :light, :dark, :text\r\n" <>
    "Or a custom color set of {text_color, button_color, pressed_color}\r\n" <>
    "Example: button({\"Something\", :message, width: 28, type: :danger}, translate: {90,0})"
  end

  #--------------------------------------------------------
  def valid?( {text, msg} ), do: valid?( {text, msg, []} )
  def valid?( {text, _msg, opts} ) when is_atom(opts), do: valid?( {text, [opts]} )

  def valid?( {text, _msg, opts} ) when is_bitstring(text) and is_list(opts), do: true
  def valid?( _ ), do: false

  #--------------------------------------------------------
  def init( {text, msg}, args ), do: init( {text, msg, []}, args )
  def init( {text, msg, opts}, _args ) when is_list(opts) do

    # the button-specific color scheme
    colors = case opts[:type] do
      {_,_,_} = colors -> colors
      type -> Map.get(@colors, type) || Map.get(@colors, :primary)
    end

    # get the colors
    {text_color, button_color, _} = colors

    # get button specific options
    width = opts[:width] || opts[:w] || @default_width
    height = opts[:height] || opts[:h] || @default_height
    radius = opts[:radius] || opts[:r] || @default_radius

    # get style args
    font = opts[:font] || @default_font
    font_size = opts[:font_size] || @default_font_size

    graph = Graph.build( font: font, font_size: font_size )
    |> rrect( {width, height, radius}, fill: button_color, id: :btn )
    |> text( text, fill: text_color, translate: {8,(height*0.7)} )

    state = %{
      graph: graph,
      colors: colors,
      pressed: false,
      contained: false,
      msg: msg
    }

    push_graph( graph )

    {:ok, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_enter, _uid}, _context, %{
    pressed: true
  } = state ) do
# IO.puts( "handle_input :cursor_enter" )
    state = Map.put(state, :contained, true)
    update_color(state)
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_exit, _uid}, _context, %{
    pressed: true
  } = state ) do
# IO.puts( "handle_input :cursor_exit")
    state = Map.put(state, :contained, false)
    update_color(state)
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :press, _, _}},
  context, state ) do
# IO.puts( "handle_input :cursor_button :press")
    state = state
    |> Map.put( :pressed, true )
    |> Map.put( :contained, true )
    update_color(state)

    ViewPort.capture_input( context, [:cursor_button, :cursor_pos])

    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :release, _, _}},
  context, %{pressed: pressed, contained: contained, msg: msg} = state ) do
# IO.puts( "handle_input :cursor_button :release")
    state = Map.put(state, :pressed, false)
    update_color(state)

    ViewPort.release_input( context, [:cursor_button, :cursor_pos] )

    if pressed && contained do
      send_event({:click, msg})
    end

    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( _event, _context, state ) do
    {:noreply, state}
  end


  #============================================================================
  # internal utilities

  defp update_color( %{ graph: graph, colors: {_,color,_},
  pressed: false, contained: false} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:fill, color)
    end)
    |> push_graph()
  end

  defp update_color( %{ graph: graph, colors: {_,color,_},
  pressed: false, contained: true} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:fill, color)
    end)
    |> push_graph()
  end

  defp update_color( %{ graph: graph, colors: {_,color,_},
  pressed: true, contained: false} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:fill, color)
    end)
    |> push_graph()
  end

  defp update_color( %{ graph: graph, colors: {_,_,color},
  pressed: true, contained: true} ) do
    Graph.modify(graph, :btn, fn(p)->
      Primitive.put_style(p, :fill, color)
    end)
    |> push_graph()
  end

end










