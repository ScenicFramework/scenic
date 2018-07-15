defmodule Scenic.Component.Button do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Utilities.Draw.Color
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
  @default_alignment  :center

#  #--------------------------------------------------------
  def info() do
    "#{IO.ANSI.red()}Button data must be: {text, id, opts}\r\n" <>
    IO.ANSI.yellow() <>
    "Position the button by adding a transform\r\n" <>
    "The id will be sent to you in a click event when the button is used.\r\n" <>
    "Options can be {:width, width} {:height, height}, {:radius, raidus},\r\n" <>
    "{:type, type}, and {:align, alignment}\r\n" <>
    "The type can be one of the following presets:\r\n" <>
    ":primary, :secondary, :success, :danger, :warning, :info, :light, :dark, :text\r\n" <>
    "Or a custom color set of {text_color, button_color, pressed_color}\r\n" <>
    "Example: button({\"Something\", :id, width: 28, type: :danger}, translate: {90,0})" <>
    "The :align option sets how the text is positioned within the button. It can be one\r\n" <>
    " of :left, :right, :center. The default is :center." <>
    IO.ANSI.default_color()
  end


  #--------------------------------------------------------
  def verify( {text, id} ), do: verify( {text, id, []} )
  def verify( {text, _id, opts} = data ) when is_bitstring(text) and is_list(opts) do
    opts
    |> Enum.all?( &verify_option(&1) )
    |> case do
      true -> {:ok, data}
      _ -> :invalid_data
    end
  end
  def verify( _ ), do: :invalid_data

  #--------------------------------------------------------
  defp verify_option( {:w, width} ), do: verify_option( {:width, width} )
  defp verify_option( {:width, width} ) when is_number(width), do: true

  defp verify_option( {:h, height} ), do: verify_option( {:height, height} )
  defp verify_option( {:height, height} ) when is_number(height), do: true

  defp verify_option( {:r, radius} ), do: verify_option( {:radius, radius} )
  defp verify_option( {:radius, radius} ) when is_number(radius), do: true

  defp verify_option( {:type, :primary} ), do: true
  defp verify_option( {:type, :secondary} ), do: true
  defp verify_option( {:type, :danger} ), do: true
  defp verify_option( {:type, :warning} ), do: true
  defp verify_option( {:type, :info} ), do: true
  defp verify_option( {:type, :light} ), do: true
  defp verify_option( {:type, :dark} ), do: true
  defp verify_option( {:type, :text} ), do: true
  defp verify_option( {:type, {text_color, button_color, pressed_color}} ) do
    Color.verify( text_color ) &&
    Color.verify( button_color ) &&
    Color.verify( pressed_color )
  end

  defp verify_option( {:a, align} ), do: verify_option( {:align, align} )
  defp verify_option( {:align, :left} ), do: true
  defp verify_option( {:align, :right} ), do: true
  defp verify_option( {:align, :center} ), do: true

  defp verify_option( _ ), do: false


  #--------------------------------------------------------
  def init( {text, id}, args ), do: init( {text, id, []}, args )
  def init( {text, id, opts}, _args ) when is_list(opts) do

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
    alignment = opts[:align] || opts[:a] || @default_alignment

    # get style args
    font = opts[:font] || @default_font
    font_size = opts[:font_size] || @default_font_size


    graph = case alignment do
      :center ->
        Graph.build( font: font, font_size: font_size )
        |> rrect( {width, height, radius}, fill: button_color, id: :btn )
        |> text( text, fill: text_color, translate: {width/2,(height*0.7)}, text_align: :center )

      :left ->
        Graph.build( font: font, font_size: font_size )
        |> rrect( {width, height, radius}, fill: button_color, id: :btn )
        |> text( text, fill: text_color, translate: {8,(height*0.7)}, text_align: :left )

      :right ->
        Graph.build( font: font, font_size: font_size )
        |> rrect( {width, height, radius}, fill: button_color, id: :btn )
        |> text( text, fill: text_color, translate: {width - 8,(height*0.7)}, text_align: :right )
    end

    state = %{
      graph: graph,
      colors: colors,
      pressed: false,
      contained: false,
      align: alignment,
      id: id
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
  context, %{pressed: pressed, contained: contained, id: id} = state ) do
# IO.puts( "handle_input :cursor_button :release")
    state = Map.put(state, :pressed, false)
    update_color(state)

    ViewPort.release_input( context, [:cursor_button, :cursor_pos] )

    if pressed && contained do
      send_event({:click, id})
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










