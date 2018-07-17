defmodule Scenic.Component.Input.Checkbox do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Primitive.Style.Paint.Color
  import Scenic.Primitives

 # import IEx


  # type is {text_color, box_background, border_color, pressed_color, checkmark_color}
  # nil for text_color means to use whatever is inherited
  @colors %{
    light:    {:black, :white, :grey, {215, 215, 215}, :cornflower_blue},
    dark:     {:white, :black, :grey, {40,40,40}, :cornflower_blue},
  }

  @default_font       :roboto
  @default_font_size  20


#  #--------------------------------------------------------
  def info() do
    "#{IO.ANSI.red()}Checkbox data must be:  {text, id, checked?, opts}\r\n" <>
    IO.ANSI.yellow() <>
    "Position the checkbox by adding a transform\r\n" <>
    "The id will be sent to you in a :value_changed event when the checkbox is used.\r\n" <>
    "The only option for now is {:type, type}\r\n" <>
    "The type can be one of the following presets: :dark or :light.\r\n" <>
    "Or a custom color set of: \r\n" <>
    "{text_color, box_background, border_color, pressed_color, checkmark_color}\r\n" <>
    "The default is :dark.\r\n"<>
    "Examples:\r\n"<>
    "checkbox({\"Something\", :id, true}, translate: {90,0})" <>
    "checkbox({\"Something\", :id, true, type: :light}, translate: {90,0})" <>
    "\r\n" <>
    IO.ANSI.default_color()
  end

  #--------------------------------------------------------
  def verify( {text, id, checked} ), do: verify( {text, id, checked, []} )
  def verify( {text, _id, checked, opts} = data ) when is_bitstring(text) and
  is_boolean(checked) and is_list(opts) do
    opts
    |> Enum.all?( &verify_option(&1) )
    |> case do
      true -> {:ok, data}
      _ -> :invalid_data
    end
  end
  def verify( _ ), do: :invalid_data

  #--------------------------------------------------------
  defp verify_option( {:type, :light} ), do: true
  defp verify_option( {:type, :dark} ), do: true
  defp verify_option( {:type, {text_color, box_background, border_color,
  pressed_color, checkmark_color}} ) do
    Color.verify( text_color ) &&
    Color.verify( box_background ) &&
    Color.verify( border_color ) &&
    Color.verify( pressed_color ) &&
    Color.verify( checkmark_color )
  end

  defp verify_option( _ ), do: false


  #--------------------------------------------------------
  def init( {text, id, checked?}, i_opts ), do: init( {text, id, checked?, []}, i_opts )
  def init( {text, id, checked?, opt}, i_opts ) when is_atom(opt) do
      init( {text, id, checked?, [opt]}, i_opts )
    end
  def init( {text, id, checked?, opts}, _ ) when is_list(opts) do

    # the color scheme
    colors = case opts[:type] do
      {_,_,_,_,_} = colors -> colors
      type -> Map.get(@colors, type) || Map.get(@colors, :dark)
    end
    {text_color, box_background, border_color, _, checkmark_color} = colors


    graph = Graph.build( font: @default_font, font_size: @default_font_size )
    |> group(fn(graph) ->
      graph
      |> rect({140, 16}, fill: :clear, translate: {-2,-2})
      |> rrect({16, 16, 3},
        fill: box_background,
        stroke: {2, border_color},
        id: :box,
        translate: {-2,-2}
      )

      |> group(fn(graph) ->
        graph
        |> path([                 # this is the checkmark
            {:move_to, 1, 7},
            {:line_to, 5, 10},
            {:line_to, 10,1}
          ], stroke: {2, checkmark_color}, join: :round)
      end, id: :chx, hidden: !checked?)
    end, translate: {0, -11})
    |> text(text, fill: text_color, translate: {20,0} )

    state = %{
      graph: graph,
      colors: colors,
      pressed: false,
      contained: false,
      checked: checked?,
      id: id
    }

#IO.puts "Checkbox.init"
    push_graph( graph )

    {:ok, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_enter, _uid}, _, state ) do
    state = Map.put(state, :contained, true)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_exit, _uid}, _, state ) do
    state = Map.put(state, :contained, false)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :press, _, _}}, context, state ) do
    state = state
    |> Map.put( :pressed, true )
    |> Map.put( :contained, true )
    graph = update_graph(state)

    ViewPort.capture_input( context, [:cursor_button, :cursor_pos] )

    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :release, _, _}}, context,
  %{contained: contained, id: id, pressed: pressed, checked: checked} = state ) do
    state = Map.put(state, :pressed, false)

    ViewPort.release_input( context, [:cursor_button, :cursor_pos])

    # only do the action if the cursor is still contained in the target
    state = case pressed && contained do
      true ->
        checked = !checked
        send_event({:value_changed, id, checked})
        Map.put(state, :checked, checked)

      false ->
        state
    end

    graph = update_graph(state)

    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( _event, _context, state ) do
    {:noreply, state}
  end


  #============================================================================
  # internal utilities
  # {text_color, box_background, border_color, pressed_color, checkmark_color}

  defp update_graph( %{
    graph: graph,
    colors: {_, box_background, _, pressed_color, _},
    pressed: pressed,
    contained: contained,
    checked: checked
  } ) do
    graph = case pressed && contained do
      true ->
        Graph.modify( graph, :box, &Primitive.put_style(&1, :color, pressed_color) )
      false ->
        Graph.modify( graph, :box, &Primitive.put_style(&1, :color, box_background) )
    end
    case checked do
      true ->
        Graph.modify( graph, :chx, &Primitive.put_style(&1, :hidden, false) )
      false ->
        Graph.modify( graph, :chx, &Primitive.put_style(&1, :hidden, true) )
    end
    |> push_graph()
  end


end










