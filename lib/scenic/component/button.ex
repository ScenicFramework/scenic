defmodule Scenic.Component.Button do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Primitive.Style.Paint.Color
  alias Scenic.Primitive.Style.Theme
  import Scenic.Primitives, only: [{:rrect, 3}, {:text, 3}]

  # import IEx

  @default_width      80
  @default_height     30
  @default_radius     3

  @default_font       :roboto
  @default_font_size  20
  @default_alignment  :center

  #--------------------------------------------------------
  def info() do
    "#{IO.ANSI.red()}Button data must be: {text, id, opts}\r\n" <>
    IO.ANSI.yellow() <>
    "Position the button by adding a transform\r\n" <>
    "The id will be sent to you in a click event when the button is used.\r\n" <>
    "Options can be {:width, width} {:height, height}, {:radius, raidus},\r\n" <>
    "{:type, type}, and {:align, alignment}\r\n" <>
    "The theme can be one of the following presets:\r\n" <>
    ":primary, :secondary, :success, :danger, :warning, :info, :light, :dark, :text\r\n" <>
    "Or a custom color set of {text_color, button_color, pressed_color}\r\n" <>
    "Example: button({\"Something\", :id, width: 28, type: :danger}, translate: {90,0})" <>
    "The :align option sets how the text is positioned within the button. It can be one\r\n" <>
    " of :left, :right, :center. The default is :center." <>
    "\r\n" <>
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

  defp verify_option( {:theme, :primary} ), do: true
  defp verify_option( {:theme, :secondary} ), do: true
  defp verify_option( {:theme, :danger} ), do: true
  defp verify_option( {:theme, :warning} ), do: true
  defp verify_option( {:theme, :info} ), do: true
  defp verify_option( {:theme, :light} ), do: true
  defp verify_option( {:theme, :dark} ), do: true
  defp verify_option( {:theme, :text} ), do: true
  defp verify_option( {:theme, {text_color, button_color, pressed_color}} ) do
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
  def init( {text, id}, styles, viewport ), do:
    init( {text, id, []}, styles, viewport )
  def init( {text, id, opts}, styles, _viewport ) when is_list(opts) do

    # theme is passed in as an inherited style
    theme = (styles[:theme] || Theme.preset(:primary))
    |> Theme.normalize()

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
        |> rrect( {width, height, radius}, fill: theme.background, id: :btn )
        |> text( text, fill: theme.text, translate: {width/2,(height*0.7)}, text_align: :center )

      :left ->
        Graph.build( font: font, font_size: font_size )
        |> rrect( {width, height, radius}, fill: theme.background, id: :btn )
        |> text( text, fill: theme.text, translate: {8,(height*0.7)}, text_align: :left )

      :right ->
        Graph.build( font: font, font_size: font_size )
        |> rrect( {width, height, radius}, fill: theme.background, id: :btn )
        |> text( text, fill: theme.text, translate: {width - 8,(height*0.7)}, text_align: :right )
    end

    state = %{
      graph: graph,
      theme: theme,
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

  defp update_color( %{ graph: graph, theme: theme,
  pressed: false, contained: false} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:fill, theme.background)
    end)
    |> push_graph()
  end

  defp update_color( %{ graph: graph, theme: theme,
  pressed: false, contained: true} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:fill, theme.background)
    end)
    |> push_graph()
  end

  defp update_color( %{ graph: graph, theme: theme,
  pressed: true, contained: false} ) do
    Graph.modify(graph, :btn, fn(p)->
      p
      |> Primitive.put_style(:fill, theme.background)
    end)
    |> push_graph()
  end

  defp update_color( %{ graph: graph, theme: theme,
  pressed: true, contained: true} ) do
    Graph.modify(graph, :btn, fn(p)->
      Primitive.put_style(p, :fill, theme.active)
    end)
    |> push_graph()
  end

end










