defmodule Scenic.Component.Button do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [{:rrect, 3}, {:text, 3}]


#  @default_width      80
#  @default_height     32
#  @default_radius     2
#  @default_type       6

#  @blue_color         :steel_blue
#  @text_color         :white

  # @valid_sizes [:small, :normal, :large]
  @valid_colors [:primary, :secondary, :success, :danger, :warning, :info, :light, :dark, :text]
#  @valid_other [:outline]

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

  # # {width, hieght, radius, font_size}
  # @sizes %{
  #   small:      {80, 24, 2, 16},
  #   normal:     {80, 30, 3, 18},
  #   large:      {80, 40, 4, 20}
  # }

  @default_width      80
  @default_height     30
  @default_radius     3
  @default_font_size  18

#  #--------------------------------------------------------
  def info() do
#    "#{IO.ANSI.red()}Button must be initialized with {{x,y}, text, message, opts}#{IO.ANSI.default_color()}\r\n" <>
    "#{IO.ANSI.red()}Button must be initialized with {text, message, opts}#{IO.ANSI.default_color()}\r\n" <>
    "Position the button with a transform\r\n" <>
    "The message will be sent to you in a click event when the button is used.\r\n" <>
    "Opts either a single or a list of option atoms\r\n" <>
    "One size indicator: :small, :normal, :large. :normal is the default\r\n" <>
    "One color indicator: :primary, :secondary, :success, :danger, :warning, :info, :light, :dark, :text\r\n" <>
    "Other modifiers: :outline\r\n" <>
    "#{IO.ANSI.yellow()}Example: {\"Button\", :primary}\r\n" <>
    "Example: { \"Outline\", [:danger, :outline]}\r\n" <>
    "Example: {\"Large\", [:warning, :large]}\r\n" <>
    "Example: {\"Small Outline\", [:info, :small, :outline]}#{IO.ANSI.default_color()}\r\n"
  end

  #--------------------------------------------------------
  def valid?( {text, msg} ), do: valid?( {text, msg, []} )
  def valid?( {text, _msg, opts} ) when is_atom(opts), do: valid?( {text, [opts]} )

  def valid?( {text, _msg, opts} ) when is_bitstring(text) and is_list(opts), do: true
  def valid?( _ ), do: false

  #--------------------------------------------------------
  def init( {text, msg}, opts ) when is_list(opts) do
    IO.puts "Button opts: #{inspect(opts)}"
    
    # get the size
    color_opt = opts[:button_type] || :primary
    case opts[:button_type] do
      nil -> :primary
      type ->
        case Enum.member?(@valid_colors, type) do
          true -> type
          false -> :primary
        end
    end

    colors = @colors[color_opt]
    {text_color, button_color, _, _, _border_color} = colors

    # get the dimentions
    width = opts[:width] || @default_width
    height = opts[:height] || @default_height
    radius = opts[:radius] || @default_radius
    font_size = opts[:font_size] || @default_font_size

    graph = Graph.build( font: {:roboto, font_size} )
    |> rrect( {{0,0}, width, height, radius},
      color: button_color, id: :btn )
    |> text( {{8,(height*0.7)}, text}, color: text_color )

    state = %{
      graph: graph,
      colors: colors,
      pressed: false,
      contained: false,
      msg: msg
    }
#IO.puts "============> Button.init"

push_graph( graph )

    {:ok, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_enter, _uid}, _context, state ) do
#IO.puts( "handle_input :cursor_enter")
    state = Map.put(state, :contained, true)
    update_color(state)
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_exit, _uid}, _context, state ) do
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

    ViewPort.capture_input( context, [:cursor_button, :cursor_pos])
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :release, _, _}},
  context, %{pressed: pressed, contained: contained, msg: msg} = state ) do
#IO.puts( "handle_input :cursor_button :release")
    state = Map.put(state, :pressed, false)
    update_color(state)

    ViewPort.release_input( context, [:cursor_button, :cursor_pos] )

    if pressed && contained, do: send_event({:click, msg})  

    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( _event, _context, state ) do
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
    |> push_graph()
  end

  defp update_color( %{ graph: graph, colors: {_,_,color,_,_},
  pressed: false, contained: true} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:color, color)
    end)
    |> push_graph()
  end

  defp update_color( %{ graph: graph, colors: {_,color,_,_,_},
  pressed: true, contained: false} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:color, color)
    end)
    |> push_graph()
  end

  defp update_color( %{ graph: graph, colors: {_,_,_,color,_},
  pressed: true, contained: true} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:color, color)
    end)
    |> push_graph()
  end

end










