#
#  Created by Boyd Multerer July 15, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.Input.Dropdown do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Scenic.Primitive.Style.Paint.Color
  import Scenic.Primitives

  # import IEx

  @default_width          160
  @default_height         30

  @default_font           :roboto
  @default_font_size      20

  @drop_click_window_ms   400


  # theme is {text_color, background_color, pressed_color, border_color, carat_color, hover_color}
  @themes %{
    light:    {:black, :white, {215, 215, 215}, :grey, :black, :cornflower_blue},
    dark:     {:white, :black, {40,40,40}, :grey, :white, :cornflower_blue},
  }

  @carat      {{0,0}, {12, 0}, {6, 6}}
  @text_id    :__dropbox_text__
  @carat_id   :__carat__
  @dropbox_id :__dropbox__
  @button_id  :__dropbox_btn__

  @rad        :math.pi() / 2

  #--------------------------------------------------------
  def info() do
    "#{IO.ANSI.red()}Dropdown data must be: {items, initial, id, opts \\\\ []}" <>
    IO.ANSI.yellow() <>
    "\r\n" <>
    IO.ANSI.default_color()
  end

  #--------------------------------------------------------
  def verify( {items, initial, id} ), do: verify( {items, initial, id, []} )
  def verify( {items, initial, _id, opts} = data ) when is_list(items) and is_list(opts) do
    Enum.all?( opts, &verify_option(&1) ) &&
    Enum.all?( items, &verify_item(&1) ) &&
    Enum.find_value(items, false, fn({_,id})-> id == initial end)
    |> case do
      true -> {:ok, data}
      _ -> :invalid_data
    end
  end
  def verify( _ ), do: :invalid_data

  #--------------------------------------------------------
  defp verify_item( {text, _} ) when is_bitstring(text), do: true
  defp verify_item( _ ), do: false

  #--------------------------------------------------------
  defp verify_option( {:theme, :light} ), do: true
  defp verify_option( {:theme, :dark} ), do: true
  defp verify_option( {:theme,
  {text_color, background_color, pressed_color, border_color, carat_color, hover_color}} ) do
    Color.verify( text_color ) &&
    Color.verify( background_color ) &&
    Color.verify( pressed_color ) &&
    Color.verify( border_color ) &&
    Color.verify( carat_color ) &&
    Color.verify( hover_color )
  end
  defp verify_option( _ ), do: false


  #--------------------------------------------------------
  def init( {items, initial_id, id}, args ), do: init( {items, initial_id, id, []}, args )
  def init( {items, initial_id, id, opts}, _args ) do
    theme = case opts[:theme] do
      {_,_,_,_,_,_} = theme -> theme
      type -> Map.get(@themes, type) || Map.get(@themes, :dark)
    end
    {text_color, background_color, pressed_color, border_color, carat_color,_} = theme

    width = opts[:width] || opts[:w] || @default_width
    height = opts[:height] || opts[:h] || @default_height
    # alignment = opts[:align] || opts[:a] || @default_alignment

    # get style args
    font = opts[:font] || @default_font
    font_size = opts[:font_size] || @default_font_size

    # get the initial text
    initial_text = Enum.find_value(items, "", fn
      {text,^initial_id} -> text
      _ -> false
    end)

    # calculate the drop box measures
    item_count = Enum.count(items)
    drop_height = item_count * height

    graph = Graph.build( font: font, font_size: font_size )
    |> rect( {width, height}, fill: background_color, stroke: {2, border_color} )
    |> text( initial_text, fill: text_color, translate: {8,(height*0.7)}, text_align: :left, id: @text_id )
    |> triangle( @carat, fill: carat_color, translate: {width - 18,(height*0.5)},
      pin: {6,0}, rotate: @rad, id: @carat_id )

    # an invisible rect for hit-test purposes
    |> rect( {width, height}, id: @button_id )

    # the drop box itself
    |> group(fn(g) ->
      g = rect(g, {width, drop_height}, fill: background_color, stroke: {2, border_color})
      {g,_} = Enum.reduce(items,{g,0}, fn({text,id},{g,i}) ->
        g = group(g, fn(g)->
          case id == initial_id do
            true -> rect( g, {width, height}, fill: pressed_color, id: id )
            false -> rect( g, {width, height}, fill: background_color, id: id )
          end
          |> text( text, fill: text_color, text_align: :left, translate: {8,height * 0.7} )
        end, translate: {0,height * i})
        {g, i + 1}
      end)
      g
    end, translate: {0, height + 1}, id: @dropbox_id, hidden: true)


    state = %{
      graph: graph,
      selected_id: initial_id,
      colors: theme,
      id: id,
      down: false,
      hover_id: nil,
      items: items,
      drop_time: 0
    }

    push_graph( graph )

    {:ok, state}
  end



  #============================================================================
  # tracking when the dropdown is UP

  #--------------------------------------------------------
  def handle_input( {:cursor_enter, _uid}, %{id: id}, %{down: false} = state ) do
    {:noreply, %{state | hover_id: id}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_exit, _uid}, _context, %{down: false} = state ) do
    {:noreply, %{state | hover_id: nil}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :press, _, _}},
  %{id: @button_id} = context,
  %{down: false, graph: graph} = state ) do
    # capture input
    ViewPort.capture_input( context, [:cursor_button, :cursor_pos])

    # drop the menu
    graph = graph
    |> Graph.modify( @carat_id, &update_opts(&1, rotate: 0) )
    |> Graph.modify( @dropbox_id, &update_opts(&1, hidden: false) )
    |> push_graph()

    state = state
    |> Map.put(:down, true)
    |> Map.put(:drop_time, :os.system_time(:milli_seconds))
    |> Map.put(:graph, graph)

    {:noreply, state}
  end



  #============================================================================
  # tracking when the dropdown is DOWN

  #--------------------------------------------------------
  def handle_input( {:cursor_enter, _uid}, %{id: id},
  %{down: true, items: items, graph: graph,
  selected_id: selected_id, colors: colors} = state ) do

    # set the appropriate hilighting for each of the items
    graph = update_highlighting(graph, items, selected_id, id, colors)
    |> push_graph

    {:noreply, %{state | hover_id: id, graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_exit, _uid}, _context,
  %{down: true, items: items, graph: graph, selected_id: selected_id, colors: colors} = state ) do

    # set the appropriate hilighting for each of the items
    graph = update_highlighting(graph, items, selected_id, nil, colors)
    |> push_graph

    {:noreply, %{state | hover_id: nil, graph: graph}}
  end

  #--------------------------------------------------------
  # the mouse is pressed outside of the dropdown when it is down.
  # immediately close the dropdown and allow the event to continue
  def handle_input(
    {:cursor_button, {:left, :press, _, _}},
    %{id: nil} = context,
    %{down: true, items: items, colors: colors, selected_id: selected_id} = state
  ) do
    # release the input capture
    ViewPort.release_input( context, [:cursor_button, :cursor_pos] )

    graph = state.graph
    # restore standard highliting
    |> update_highlighting( items, selected_id, nil, colors)
    # raise the dropdown
    |> Graph.modify( @carat_id, &update_opts(&1, rotate: @rad) )
    |> Graph.modify( @dropbox_id, &update_opts(&1, hidden: true) )
    # push to the viewport
    |> push_graph()

    {:continue, %{state | down: false, graph: graph}}
  end

  #--------------------------------------------------------
  # clicking the button when down, raises it back up without doing anything else
  def handle_input( {:cursor_button, {:left, :release, _, _}},
  %{id: @button_id} = context,
  %{down: true, drop_time: drop_time, colors: colors, items: items,
  graph: graph, selected_id: selected_id} = state ) do

    if :os.system_time(:milli_seconds) - drop_time <= @drop_click_window_ms do
      # we are still in the click window, leave the menu down.
      {:noreply, state}
    else
      # we are outside the window, raise it back up
      graph = graph
      |> update_highlighting( items, selected_id, nil, colors)
      |> Graph.modify( @carat_id, &update_opts(&1, rotate: @rad) )
      |> Graph.modify( @dropbox_id, &update_opts(&1, hidden: true) )
      |> push_graph()

      # release the input capture
      ViewPort.release_input( context, [:cursor_button, :cursor_pos] )

      {:noreply, %{state | down: false, hover_id: nil, graph: graph}}
    end
  end

  #--------------------------------------------------------
  # the button is released outside the dropdown space
  def handle_input( {:cursor_button, {:left, :release, _, _}},
  %{id: nil} = context,
  %{down: true, items: items,
  colors: colors, selected_id: selected_id} = state ) do

    # release the input capture
    ViewPort.release_input( context, [:cursor_button, :cursor_pos] )

    graph = state.graph
    # restore standard highliting
    |> update_highlighting( items, selected_id, nil, colors)
    # raise the dropdown
    |> Graph.modify( @carat_id, &update_opts(&1, rotate: @rad) )
    |> Graph.modify( @dropbox_id, &update_opts(&1, hidden: true) )
    # push to the viewport
    |> push_graph()

    {:noreply, %{state | down: false, graph: graph}}
  end

  #--------------------------------------------------------
  # the button is realeased over an item in dropdown
  def handle_input( {:cursor_button, {:left, :release, _, _}},
  %{id: item_id} = context,
  %{down: true, id: id, items: items, colors: colors} = state ) do

    # release the input capture
    ViewPort.release_input( context, [:cursor_button, :cursor_pos] )

    # send the value_changed message
    send_event({:value_changed, id, item_id})

    # find the newly selected item's text
    {text, _} = Enum.find(items, fn({_,id})-> id == item_id end)

    graph = state.graph
    # update the main button text
    |> Graph.modify( @text_id, &text(&1, text) )
    # restore standard highliting
    |> update_highlighting( items, item_id, nil, colors)
    # raise the dropdown
    |> Graph.modify( @carat_id, &update_opts(&1, rotate: @rad) )
    |> Graph.modify( @dropbox_id, &update_opts(&1, hidden: true) )
    # push to the viewport
    |> push_graph()

    {:noreply, %{state | down: false, graph: graph, selected_id: item_id}}
  end


  #============================================================================
  # unhandled input

  #--------------------------------------------------------
  def handle_input( _event, _context, state ) do
    {:noreply, state}
  end


  #============================================================================
  # internal

  defp update_highlighting(graph, items, selected_id, hover_id, colors) do
    {_, background_color, pressed_color, _, _, hover_color} = colors
    # set the appropriate hilighting for each of the items
    Enum.reduce(items, graph, fn
      {_, ^hover_id}, g ->           # this is the item the user is hovering over
        Graph.modify( g, hover_id, &update_opts(&1, fill: hover_color))
      {_, ^selected_id}, g ->  # this is the currently selected item
        Graph.modify( g, selected_id, &update_opts(&1, fill: pressed_color))
      {_, regular_id}, g ->    # not selected, not hovered over
        Graph.modify( g, regular_id, &update_opts(&1, fill: background_color))
    end)
  end

end










