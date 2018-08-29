#
#  Created by Boyd Multerer August 5, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#


defmodule Scenic.Component.Input.TextField do
  use Scenic.Component, has_children: true

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort
  alias Scenic.Component.Input.Carat
  alias Scenic.Primitive.Style.Theme

  import Scenic.Primitives, only: [
    {:rect, 3}, {:text, 3},
    {:update_opts,2}, {:group, 3}
  ]

  # import IEx

  @default_hint           ""
  @default_font           :roboto_mono
  @default_font_size      22
  @char_width             10
  @inset_x                10

  @default_type           :text
  @default_filter         :all

  @default_width          @char_width * 24
  @default_height         @default_font_size * 1.5

  @input_capture          [:cursor_button, :cursor_pos, :codepoint, :key]

  @password_char          '*'

  @hint_color           :grey


  #--------------------------------------------------------
  def info() do
    "#{IO.ANSI.red()}TextField data must be: initial_text" <>
    IO.ANSI.yellow() <>
    "\r\n" <>
    IO.ANSI.default_color()
  end

  #--------------------------------------------------------
  def verify( initial_text ) when is_bitstring(initial_text) do
    {:ok, initial_text}
  end
  def verify( _ ), do: :invalid_data

  # #--------------------------------------------------------
  # defp verify_option( {:w, w} ) when is_number(w) and w > 0, do: true
  # defp verify_option( {:width, w} )when is_number(w) and w > 0, do: true
  # defp verify_option( {:hint, hint} ) when is_bitstring(hint), do: true
  # defp verify_option( {:theme, :light} ), do: true
  # defp verify_option( {:theme, :dark} ), do: true
  # defp verify_option( {:theme,
  # {text_color, hint_color, background_color, border_color, focused_color}} ) do
  #   Color.verify( text_color ) &&
  #   Color.verify( hint_color ) &&
  #   Color.verify( background_color ) &&
  #   Color.verify( border_color ) &&
  #   Color.verify( focused_color )
  # end
  # defp verify_option( {:type, :text} ), do: true
  # defp verify_option( {:type, :password} ), do: true
  # defp verify_option( {:filter, :number} ), do: true
  # defp verify_option( {:filter, :integer} ), do: true
  # defp verify_option( {:filter, filter} ) when is_bitstring(filter), do: true
  # defp verify_option( {:filter, filter} ) when is_function(filter,1), do: true
  # defp verify_option( _ ), do: false



  #--------------------------------------------------------
  def init( value, opts ) do
    id = opts[:id]
    styles = opts[:styles]

    # theme is passed in as an inherited style
    theme = (styles[:theme] || Theme.preset(:dark))
    |> Theme.normalize()

    # get the text_field specific styles
    hint = styles[:hint] || @default_hint
    width = opts[:width] || opts[:w] || @default_width
    height = styles[:height] || opts[:h] || @default_height
    type = styles[:type] || @default_type
    filter = styles[:filter] || @default_filter

    index = String.length(value)

    display = display_from_value(value, type)

    state = %{
      graph: nil,
      theme: theme,
      width: width,
      height: height,
      value: value,
      display: display,
      hint: hint,
      index: index,
      char_width: @char_width,
      focused: false,
      type: type,
      filter: filter,
      id: id
    }

    graph = Graph.build(
      font: @default_font, font_size: @default_font_size,
      scissor: {width, height}
    )
    |> rect({width, height}, fill: theme.background)
    |> group( fn(g) ->
      g
      |> text(
        @default_hint, fill: @hint_color,
        t: {0, @default_font_size}, id: :text
        )
      |> Carat.add_to_graph({height, theme.text}, id: :carat)
    end, t: {@inset_x, 0})
    |> rect(
      {width, height},
      fill: :clear, stroke: {2, theme.border}, id: :border
      )
    |> update_text( display, state )
    |> update_carat( display, index )
    |> push_graph()

    {:ok, %{state | graph: graph}}
  end

  #============================================================================

  #--------------------------------------------------------
  # to be called when the value has changed
  defp update_text( graph, "", %{hint: hint} ) do
    Graph.modify( graph, :text, &text(&1, hint, fill: @hint_color) )
  end
  defp update_text( graph, value, %{theme: theme} ) do
    Graph.modify( graph, :text, &text(&1, value, fill: theme.text) )
  end

  #============================================================================

  #--------------------------------------------------------
  # current value string is empty. show the hint string
  # defp update_carat( graph, state ) do
  #   x = calc_carat_x( state )
  #   Graph.modify( graph, :carat, &update_opts(&1, t: {x,0}) )
  # end

  defp update_carat( graph, value, index ) do
    str_len = String.length(value)

    # double check the postition
    index = cond do
      index < 0 -> 0
      index > str_len -> str_len
      true -> index
    end

    # calc the carat position
    x = index * @char_width

    # move the carat
    Graph.modify(graph, :carat, &update_opts(&1, t: {x, 0}) )
  end

  #--------------------------------------------------------
  defp capture_focus( context, %{focused: false, graph: graph, theme: theme} = state ) do
    # capture the input
    ViewPort.capture_input( context, @input_capture)

    # start animating the carat
    Scene.cast_to_refs( nil, :gain_focus )

    # show the carat
    graph = graph
    |> Graph.modify( :carat, &update_opts(&1, hidden: false) )
    |> Graph.modify( :border, &update_opts(&1, stroke: {2, theme.focus}) )
    |> push_graph()

    # record the state
    state
    |> Map.put( :focused, true )
    |> Map.put( :graph, graph )
  end

  #--------------------------------------------------------
  defp release_focus( context, %{focused: true, graph: graph, theme: theme} = state ) do
    # release the input
    ViewPort.release_input( context, @input_capture)

    # stop animating the carat
    Scene.cast_to_refs( nil, :lose_focus )

    # hide the carat
    graph = graph
    |> Graph.modify( :carat, &update_opts(&1, hidden: true) )
    |> Graph.modify( :border, &update_opts(&1, stroke: {2, theme.border}) )
    |> push_graph()

    # record the state
    state
    |> Map.put( :focused, false )
    |> Map.put( :graph, graph )
  end

  #--------------------------------------------------------
  # get the text index from a mouse position. clap to the
  # beginning and end of the string
  defp index_from_cursor_pos( {x,_}, value ) do
    # account for the text inset
    x = x - @inset_x

    # get the max index
    max_index = String.length(value)

    # calc the new index
    d = x / @char_width
    i = trunc(d)
    i = i + round(d - i)
    # clamp the result
    cond do
      i < 0 -> 0
      i > max_index -> max_index
      true -> i
    end
  end

  #--------------------------------------------------------
  defp display_from_value(value, :password) do
    String.to_charlist(value)
    |> Enum.map(fn(_)-> @password_char end)
    |> to_string()
  end
  defp display_from_value(value, _), do: value

  #--------------------------------------------------------
  defp accept_char?(char, :number) do
    "0123456789.," =~ char
  end
  defp accept_char?(char, :integer) do
    "0123456789" =~ char
  end
  defp accept_char?(char, filter) when is_bitstring(filter) do
    filter =~ char
  end
  defp accept_char?(char, filter) when is_function(filter,1) do
    # note: the !! forces the response to be a boolean
    !!filter.(char)
  end
  defp accept_char?(_,_), do: true

  #============================================================================
  # User input handling - get the focus

  #--------------------------------------------------------
  # unfocused click in the text field
  def handle_input(
    {:cursor_button, {:left, :press, _, _}},
    context, %{focused: false} = state
  ) do
    { :noreply, capture_focus(context, state) }
  end


  #--------------------------------------------------------
  # focused click in the text field
  def handle_input(
    {:cursor_button, {:left, :press, _, pos}},
    %ViewPort.Context{id: :border},
    %{focused: true, value: value, index: index, graph: graph} = state
  ) do

    {index, graph} = case index_from_cursor_pos( pos, value ) do
      ^index -> {index, graph}
      i ->
        # reset the carat blinker
        Scene.cast_to_refs( nil, :reset_carat )
        # move the carat
        graph = update_carat( graph, value, i )
        |> push_graph()
        {i, graph}
    end

    { :noreply, %{state| index: index, graph: graph} }
  end

  #--------------------------------------------------------
  # focused click outside the text field
  def handle_input(
    {:cursor_button, {:left, :press, _, _}},
    context, %{focused: true} = state
  ) do
    { :continue, release_focus(context, state) }
  end


  #============================================================================
  # control keys

  #--------------------------------------------------------
  # treat key repeats as a press
  def handle_input( {:key, {key, :repeat, mods}}, context, state ) do
    handle_input( {:key, {key, :press, mods}}, context, state )
  end

  #--------------------------------------------------------
  def handle_input( {:key, {"left", :press, _}}, _context,
    %{index: index, value: value, graph: graph} = state
  ) do
    # move left. clamp to 0
    {index, graph} = case index do
      0 -> {0, graph}
      i ->
        # reset the carat blinker
        Scene.cast_to_refs( nil, :reset_carat )
        # move the carat
        i = i - 1
        graph = update_carat( graph, value, i )
        |> push_graph()
        {i, graph}
    end

    { :noreply, %{state| index: index, graph: graph} }
  end

  #--------------------------------------------------------
  def handle_input( {:key, {"right", :press, _}}, _context, 
    %{index: index, value: value, graph: graph} = state
  ) do
    # the max position for the carat
    max_index = String.length(value)

    # move left. clamp to 0
    {index, graph} = case index do
      ^max_index -> {index, graph}
      i ->
        # reset the carat blinker
        Scene.cast_to_refs( nil, :reset_carat )
        # move the carat
        i = i + 1
        graph = update_carat( graph, value, i )
        |> push_graph()
        {i, graph}
    end

    { :noreply, %{state| index: index, graph: graph} }
  end

  #--------------------------------------------------------
  def handle_input( {:key, {"page_up", :press, mod}}, context, state ) do
    handle_input( {:key, {"home", :press, mod}}, context, state )
  end
  def handle_input( {:key, {"home", :press, _}}, _context,
    %{index: index, value: value, graph: graph} = state
  ) do
    # move left. clamp to 0
    {index, graph} = case index do
      0 -> {index, graph}
      _ ->
        # reset the carat blinker
        Scene.cast_to_refs( nil, :reset_carat )
        # move the carat
        graph = update_carat( graph, value, 0 )
        |> push_graph()
        {0, graph}
    end

    { :noreply, %{state| index: index, graph: graph} }
  end

  #--------------------------------------------------------
  def handle_input( {:key, {"page_down", :press, mod}}, context, state ) do
    handle_input( {:key, {"end", :press, mod}}, context, state )
  end
  def handle_input( {:key, {"end", :press, _}}, _context,
    %{index: index, value: value, graph: graph} = state
  ) do
    # the max position for the carat
    max_index = String.length(value)

    # move left. clamp to 0
    {index, graph} = case index do
      ^max_index -> {index, graph}
      _ ->
        # reset the carat blinker
        Scene.cast_to_refs( nil, :reset_carat )
        # move the carat
        graph = update_carat( graph, value, max_index )
        |> push_graph()
        {max_index, graph}
    end

    { :noreply, %{state| index: index, graph: graph} }
  end


  #--------------------------------------------------------
  # ignore backspace if at index 0
  def handle_input( {:key, {"backspace", :press, _}}, _context, %{index: 0} = state), do:
    { :noreply, state }
  # handle backspace
  def handle_input( {:key, {"backspace", :press, _}}, _context, %{
    graph: graph,
    value: value,
    index: index,
    type: type,
    id: id
  } = state ) do
    # reset the carat blinker
    Scene.cast_to_refs( nil, :reset_carat )

    # delete the char to the left of the index
    value = String.to_charlist(value)
    |> List.delete_at( index - 1 )
    |> to_string()
    display = display_from_value(value, type)

    # send the value changed event
    send_event({:value_changed, id, value})

    # move the index
    index = index - 1

    # update the graph
    graph = graph
    |> update_text( display, state )
    |> update_carat( display, index )
    |> push_graph()

    state = state
    |> Map.put( :graph, graph )
    |> Map.put( :value, value )
    |> Map.put( :display, display )
    |> Map.put( :index, index )

    { :noreply, state }
  end


  #--------------------------------------------------------
  def handle_input( {:key, {"delete", :press, _}}, _context,%{
    graph: graph,
    value: value,
    index: index,
    type: type,
    id: id
  } = state ) do
    # reset the carat blinker
    Scene.cast_to_refs( nil, :reset_carat )

    # delete the char at the index
    value = String.to_charlist(value)
    |> List.delete_at( index )
    |> to_string()
    display = display_from_value(value, type)

    # send the value changed event
    send_event({:value_changed, id, value})

    # update the graph (the carat doesn't move)
    graph = graph
    |> update_text( display, state )
    |> push_graph()

    state = state
    |> Map.put( :graph, graph )
    |> Map.put( :value, value )
    |> Map.put( :display, display )
    |> Map.put( :index, index )

    { :noreply, state }
  end

  #--------------------------------------------------------
  def handle_input( {:key, {"enter", :press, _}}, _context, state ) do
    IO.puts "enter"
    { :noreply, state }
  end

  #--------------------------------------------------------
  def handle_input( {:key, {"escape", :press, _}}, _context, state ) do
    IO.puts "escape"
    { :noreply, state }
  end

  #============================================================================
  # text entry

  #--------------------------------------------------------
  def handle_input( {:codepoint, {char, _}}, _, %{filter: filter} = state ) do
    char
    |> accept_char?( filter )
    |> do_handle_codepoint( char, state )
  end

  #--------------------------------------------------------
  def handle_input( _msg, _context, state ) do
    # IO.puts "TextField msg: #{inspect(_msg)}"
    {:noreply, state }
  end


  #--------------------------------------------------------
  defp do_handle_codepoint( true, char, %{
    graph: graph,
    value: value,
    index: index,
    type: type,
    id: id
  } = state) do
    # reset the carat blinker
    Scene.cast_to_refs( nil, :reset_carat )

    #insert the char into the string at the index location
    {left, right} = String.split_at(value, index)
    value = Enum.join([left, char, right])
    display = display_from_value(value, type)

    # send the value changed event
    send_event({:value_changed, id, value})

    # advance the index
    index = index + 1

    # update the graph
    graph = graph
    |> update_text( display, state )
    |> update_carat( display, index )
    |> push_graph()

    state = state
    |> Map.put( :graph, graph )
    |> Map.put( :value, value )
    |> Map.put( :display, display )
    |> Map.put( :index, index )

    { :noreply, state }
  end
  # ignore the char
  defp do_handle_codepoint( _, _, state), do: { :noreply, state }

end
























