defmodule Scenic.Component.Button do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.ViewPort.Input.Tracker

  import IEx


  @default_width      80
  @default_height     32
  @default_radius     6
  @default_type       6

  @blue_color         :steel_blue
  @text_color         :white

  @valid_sizes [:small, :normal, :large]
  @valid_colors [:primary, :secondary, :success, :danger, :warning, :info, :light, :dark, :text]
  @valid_other [:outline]

  # type is {text_color, button_color, hover_color, pressed_color, border_color}
  # nil for text_color means to use whatever is inherited
  @colors %{
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

  # {width, hieght, radius, font_size}
  @sizes %{
    small:      {80, 24, 4, 16},
    normal:     {80, 30, 6, 18},
    large:      {80, 40, 8, 20}
  }

#  #--------------------------------------------------------
  def info() do
    "#{IO.ANSI.red()}Button must be initialized with {{x,y}, text, message, opts}#{IO.ANSI.default_color()}\r\n" <>
    "The message will be sent to you in a click event when the button is used.\r\n" <>
    "Opts either a single or a list of option atoms\r\n" <>
    "One size indicator: :small, :normal, :large. :normal is the default\r\n" <>
    "One color indicator: :primary, :secondary, :success, :danger, :warning, :info, :light, :dark, :text\r\n" <>
    "Other modifiers: :outline\r\n" <>
    "#{IO.ANSI.yellow()}Example: {{20,20}, \"Button\", :primary}\r\n" <>
    "Example: {{20,20}, \"Outline\", [:danger, :outline]}\r\n" <>
    "Example: {{20,20}, \"Large\", [:warning, :large]}\r\n" <>
    "Example: {{20,20}, \"Small Outline\", [:info, :small, :outline]}#{IO.ANSI.default_color()}\r\n"
  end

  #--------------------------------------------------------
  def valid?( {point, text, msg} ), do: valid?( {point, text, msg, []} )
  def valid?( {point, text, msg, opts} ) when is_atom(opts), do: valid?( {point, text, [opts]} )

  def valid?( {{x, y}, text, msg, opts} ) when
  is_number(x) and is_number(y) and
  is_bitstring(text) and is_list(opts), do: true
  def valid?( d ), do: false


  #--------------------------------------------------------
  def init( {{x, y}, text, msg} ), do: init( {{x, y}, text, msg, []} )
  def init( {{x, y}, text, msg, opt} ) when is_atom(opt), do: init( {{x, y}, text, msg, [opt]} )
  def init( {{x, y}, text, msg, opts} ) when is_list(opts) do
    # get the size
    size_opt = Enum.find(opts, &Enum.member?(@valid_sizes, &1) ) || :normal
    color_opt = Enum.find(opts, &Enum.member?(@valid_colors, &1) ) || :primary
    outline_opt = Enum.member?(opts, :outline)

    colors = @colors[color_opt]
    {text_color, button_color, _, _, border_color} = colors

    {width, hieght, radius, font_size} = @sizes[size_opt]

    graph = Graph.build( font: {:roboto, font_size} )
    |> Primitive.RoundedRectangle.add_to_graph( {{x,y}, width, hieght, radius},
      color: button_color, id: :btn )
    |> Primitive.Text.add_to_graph( {{x+8,y+(hieght*0.7)}, text}, color: text_color )

    state = %{
      graph: graph,
      colors: colors,
      pressed: false,
      contained: false,
      msg: msg
    }

    {:ok, state}
  end


  #--------------------------------------------------------
  def handle_activate(_args, %{graph: graph} = state ) do
    ViewPort.put_graph( graph )
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_enter, uid}, context, state ) do
#IO.puts( "handle_input :cursor_enter")
    state = Map.put(state, :contained, true)
    update_color(state)
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_exit, uid}, context, state ) do
#IO.puts( "handle_input :cursor_exit")
    state = Map.put(state, :contained, false)
    update_color(state)
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :press, _, _}},
  context, state ) do
#IO.puts( "handle_input :cursor_button :press")
    state = state
    |> Map.put( :pressed, true )
    |> Map.put( :contained, true )
    update_color(state)

    ViewPort.capture_input( [:cursor_button, :cursor_pos], context)
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :release, _, _}},
  context, %{pressed: pressed, contained: contained, msg: msg} = state ) do
#IO.puts( "handle_input :cursor_button :release")
    state = Map.put(state, :pressed, false)
    update_color(state)

    ViewPort.release_input( [:cursor_button, :cursor_pos])

    if pressed && contained, do: send_event({:click, msg})  

    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( event, context, state ) do
    {:noreply, state}
  end


  #============================================================================
  # internal utilities

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










