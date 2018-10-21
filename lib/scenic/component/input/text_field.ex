#
#  Created by Boyd Multerer 2018-08-05.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.Input.TextField do
  @moduledoc """
  Add a text field input to a graph

  ## Data

  `initial_value`

  * `initial_value` - is the string that will be the starting value

  ## Messages

  When the text in the field changes, it sends an event message to the host
  scene in the form of:

  `{:value_changed, id, value}`

  ## Styles

  Text fields honor the following styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ## Additional Styles

  Text fields honor the following list of additional styles.

  * `:filter` - Adding a filter option restricts which characters can be
  entered into the text_field component. The value of filter can be one of:
    * `:all` - Accept all characters. This is the default
    * `:number` - Any characters from "0123456789.,"
    * `"filter_string"` - Pass in a string containing all the characters you
    will accept
    * `function/1` - Pass in an anonymous function. The single parameter will
    be the character to be filtered. Return `true` or `false` to keep or reject
    it.
  * `:hint` - A string that will be shown (greyed out) when the entered value
  of the component is empty.
  * `:type` - Can be one of the following options:
    * `:all` - Show all characters. This is the default.
    * `:password` - Display a string of '*' characters instead of the value.
  * `:width` - set the width of the control.

  ## Theme

  Text fields work well with the following predefined themes: `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text
  * `:background` - the background of the component
  * `:border` - the border of the component
  * `:focus` - the border while the component has focus

  ## Usage

  You should add/modify components via the helper functions in
  [`Scenic.Components`](Scenic.Components.html#text_field/3)

  ## Examples

      graph
      |> text_field("Sample Text", id: :text_id, translate: {20,20})

      graph
      |> text_field(
        "", id: :pass_id, type: :password, hint: "Enter password", translate: {20,20}
      )
  """

  use Scenic.Component, has_children: true

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort
  alias Scenic.Component.Input.Caret
  alias Scenic.Primitive.Style.Theme

  import Scenic.Primitives,
    only: [
      {:rect, 3},
      {:text, 3},
      {:update_opts, 2},
      {:group, 3}
    ]

  # import IEx

  @default_hint ""
  @default_font :roboto_mono
  @default_font_size 22
  @char_width 10
  @inset_x 10

  @default_type :text
  @default_filter :all

  @default_width @char_width * 24
  @default_height @default_font_size * 1.5

  @input_capture [:cursor_button, :cursor_pos, :codepoint, :key]

  @password_char '*'

  @hint_color :grey

  # --------------------------------------------------------
  @doc false
  def info(data) do
    """
    #{IO.ANSI.red()}TextField data must be a bitstring: initial_text
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  @doc false
  def verify(initial_text) when is_bitstring(initial_text) do
    {:ok, initial_text}
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  @doc false
  def init(value, opts) do
    id = opts[:id]
    styles = opts[:styles]

    # theme is passed in as an inherited style
    theme =
      (styles[:theme] || Theme.preset(:dark))
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

    graph =
      Graph.build(
        font: @default_font,
        font_size: @default_font_size,
        scissor: {width, height}
      )
      |> rect({width, height}, fill: theme.background)
      |> group(
        fn g ->
          g
          |> text(
            @default_hint,
            fill: @hint_color,
            t: {0, @default_font_size},
            id: :text
          )
          |> Caret.add_to_graph({height, theme.text}, id: :caret)
        end,
        t: {@inset_x, 0}
      )
      |> rect(
        {width, height},
        fill: :clear,
        stroke: {2, theme.border},
        id: :border
      )
      |> update_text(display, state)
      |> update_caret(display, index)
      |> push_graph()

    {:ok, %{state | graph: graph}}
  end

  # ============================================================================

  # --------------------------------------------------------
  # to be called when the value has changed
  defp update_text(graph, "", %{hint: hint}) do
    Graph.modify(graph, :text, &text(&1, hint, fill: @hint_color))
  end

  defp update_text(graph, value, %{theme: theme}) do
    Graph.modify(graph, :text, &text(&1, value, fill: theme.text))
  end

  # ============================================================================

  # --------------------------------------------------------
  # current value string is empty. show the hint string
  # defp update_caret( graph, state ) do
  #   x = calc_caret_x( state )
  #   Graph.modify( graph, :caret, &update_opts(&1, t: {x,0}) )
  # end

  defp update_caret(graph, value, index) do
    str_len = String.length(value)

    # double check the postition
    index =
      cond do
        index < 0 -> 0
        index > str_len -> str_len
        true -> index
      end

    # calc the caret position
    x = index * @char_width

    # move the caret
    Graph.modify(graph, :caret, &update_opts(&1, t: {x, 0}))
  end

  # --------------------------------------------------------
  defp capture_focus(context, %{focused: false, graph: graph, theme: theme} = state) do
    # capture the input
    ViewPort.capture_input(context, @input_capture)

    # start animating the caret
    Scene.cast_to_refs(nil, :start_caret)

    # show the caret
    graph =
      graph
      |> Graph.modify(:caret, &update_opts(&1, hidden: false))
      |> Graph.modify(:border, &update_opts(&1, stroke: {2, theme.focus}))
      |> push_graph()

    # record the state
    state
    |> Map.put(:focused, true)
    |> Map.put(:graph, graph)
  end

  # --------------------------------------------------------
  defp release_focus(context, %{focused: true, graph: graph, theme: theme} = state) do
    # release the input
    ViewPort.release_input(context, @input_capture)

    # stop animating the caret
    Scene.cast_to_refs(nil, :stop_caret)

    # hide the caret
    graph =
      graph
      |> Graph.modify(:caret, &update_opts(&1, hidden: true))
      |> Graph.modify(:border, &update_opts(&1, stroke: {2, theme.border}))
      |> push_graph()

    # record the state
    state
    |> Map.put(:focused, false)
    |> Map.put(:graph, graph)
  end

  # --------------------------------------------------------
  # get the text index from a mouse position. clap to the
  # beginning and end of the string
  defp index_from_cursor_pos({x, _}, value) do
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

  # --------------------------------------------------------
  defp display_from_value(value, :password) do
    String.to_charlist(value)
    |> Enum.map(fn _ -> @password_char end)
    |> to_string()
  end

  defp display_from_value(value, _), do: value

  # --------------------------------------------------------
  defp accept_char?(char, :number) do
    "0123456789.," =~ char
  end

  defp accept_char?(char, :integer) do
    "0123456789" =~ char
  end

  defp accept_char?(char, filter) when is_bitstring(filter) do
    filter =~ char
  end

  defp accept_char?(char, filter) when is_function(filter, 1) do
    # note: the !! forces the response to be a boolean
    !!filter.(char)
  end

  defp accept_char?(_, _), do: true

  # ============================================================================
  # User input handling - get the focus

  # --------------------------------------------------------
  @doc false
  # unfocused click in the text field
  def handle_input(
        {:cursor_button, {:left, :press, _, _}},
        context,
        %{focused: false} = state
      ) do
    {:noreply, capture_focus(context, state)}
  end

  # --------------------------------------------------------
  # focused click in the text field
  def handle_input(
        {:cursor_button, {:left, :press, _, pos}},
        %ViewPort.Context{id: :border},
        %{focused: true, value: value, index: index, graph: graph} = state
      ) do
    {index, graph} =
      case index_from_cursor_pos(pos, value) do
        ^index ->
          {index, graph}

        i ->
          # reset_caret the caret blinker
          Scene.cast_to_refs(nil, :reset_caret)
          # move the caret
          graph =
            update_caret(graph, value, i)
            |> push_graph()

          {i, graph}
      end

    {:noreply, %{state | index: index, graph: graph}}
  end

  # --------------------------------------------------------
  # focused click outside the text field
  def handle_input(
        {:cursor_button, {:left, :press, _, _}},
        context,
        %{focused: true} = state
      ) do
    {:continue, release_focus(context, state)}
  end

  # ============================================================================
  # control keys

  # --------------------------------------------------------
  # treat key repeats as a press
  def handle_input({:key, {key, :repeat, mods}}, context, state) do
    handle_input({:key, {key, :press, mods}}, context, state)
  end

  # --------------------------------------------------------
  def handle_input(
        {:key, {"left", :press, _}},
        _context,
        %{index: index, value: value, graph: graph} = state
      ) do
    # move left. clamp to 0
    {index, graph} =
      case index do
        0 ->
          {0, graph}

        i ->
          # reset_caret the caret blinker
          Scene.cast_to_refs(nil, :reset_caret)
          # move the caret
          i = i - 1

          graph =
            update_caret(graph, value, i)
            |> push_graph()

          {i, graph}
      end

    {:noreply, %{state | index: index, graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input(
        {:key, {"right", :press, _}},
        _context,
        %{index: index, value: value, graph: graph} = state
      ) do
    # the max position for the caret
    max_index = String.length(value)

    # move left. clamp to 0
    {index, graph} =
      case index do
        ^max_index ->
          {index, graph}

        i ->
          # reset the caret blinker
          Scene.cast_to_refs(nil, :reset_caret_caret)
          # move the caret
          i = i + 1

          graph =
            update_caret(graph, value, i)
            |> push_graph()

          {i, graph}
      end

    {:noreply, %{state | index: index, graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input({:key, {"page_up", :press, mod}}, context, state) do
    handle_input({:key, {"home", :press, mod}}, context, state)
  end

  def handle_input(
        {:key, {"home", :press, _}},
        _context,
        %{index: index, value: value, graph: graph} = state
      ) do
    # move left. clamp to 0
    {index, graph} =
      case index do
        0 ->
          {index, graph}

        _ ->
          # reset the caret blinker
          Scene.cast_to_refs(nil, :reset_caret)
          # move the caret
          graph =
            update_caret(graph, value, 0)
            |> push_graph()

          {0, graph}
      end

    {:noreply, %{state | index: index, graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input({:key, {"page_down", :press, mod}}, context, state) do
    handle_input({:key, {"end", :press, mod}}, context, state)
  end

  def handle_input(
        {:key, {"end", :press, _}},
        _context,
        %{index: index, value: value, graph: graph} = state
      ) do
    # the max position for the caret
    max_index = String.length(value)

    # move left. clamp to 0
    {index, graph} =
      case index do
        ^max_index ->
          {index, graph}

        _ ->
          # reset the caret blinker
          Scene.cast_to_refs(nil, :reset_caret)
          # move the caret
          graph =
            update_caret(graph, value, max_index)
            |> push_graph()

          {max_index, graph}
      end

    {:noreply, %{state | index: index, graph: graph}}
  end

  # --------------------------------------------------------
  # ignore backspace if at index 0
  def handle_input({:key, {"backspace", :press, _}}, _context, %{index: 0} = state),
    do: {:noreply, state}

  # handle backspace
  def handle_input(
        {:key, {"backspace", :press, _}},
        _context,
        %{
          graph: graph,
          value: value,
          index: index,
          type: type,
          id: id
        } = state
      ) do
    # reset_caret the caret blinker
    Scene.cast_to_refs(nil, :reset_caret)

    # delete the char to the left of the index
    value =
      String.to_charlist(value)
      |> List.delete_at(index - 1)
      |> to_string()

    display = display_from_value(value, type)

    # send the value changed event
    send_event({:value_changed, id, value})

    # move the index
    index = index - 1

    # update the graph
    graph =
      graph
      |> update_text(display, state)
      |> update_caret(display, index)
      |> push_graph()

    state =
      state
      |> Map.put(:graph, graph)
      |> Map.put(:value, value)
      |> Map.put(:display, display)
      |> Map.put(:index, index)

    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_input(
        {:key, {"delete", :press, _}},
        _context,
        %{
          graph: graph,
          value: value,
          index: index,
          type: type,
          id: id
        } = state
      ) do
    # reset the caret blinker
    Scene.cast_to_refs(nil, :reset_caret)

    # delete the char at the index
    value =
      String.to_charlist(value)
      |> List.delete_at(index)
      |> to_string()

    display = display_from_value(value, type)

    # send the value changed event
    send_event({:value_changed, id, value})

    # update the graph (the caret doesn't move)
    graph =
      graph
      |> update_text(display, state)
      |> push_graph()

    state =
      state
      |> Map.put(:graph, graph)
      |> Map.put(:value, value)
      |> Map.put(:display, display)
      |> Map.put(:index, index)

    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_input({:key, {"enter", :press, _}}, _context, state) do
    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_input({:key, {"escape", :press, _}}, _context, state) do
    {:noreply, state}
  end

  # ============================================================================
  # text entry

  # --------------------------------------------------------
  def handle_input({:codepoint, {char, _}}, _, %{filter: filter} = state) do
    char
    |> accept_char?(filter)
    |> do_handle_codepoint(char, state)
  end

  # --------------------------------------------------------
  def handle_input(_msg, _context, state) do
    # IO.puts "TextField msg: #{inspect(_msg)}"
    {:noreply, state}
  end

  # --------------------------------------------------------
  defp do_handle_codepoint(
         true,
         char,
         %{
           graph: graph,
           value: value,
           index: index,
           type: type,
           id: id
         } = state
       ) do
    # reset the caret blinker
    Scene.cast_to_refs(nil, :reset_caret)

    # insert the char into the string at the index location
    {left, right} = String.split_at(value, index)
    value = Enum.join([left, char, right])
    display = display_from_value(value, type)

    # send the value changed event
    send_event({:value_changed, id, value})

    # advance the index
    index = index + String.length(char)

    # update the graph
    graph =
      graph
      |> update_text(display, state)
      |> update_caret(display, index)
      |> push_graph()

    state =
      state
      |> Map.put(:graph, graph)
      |> Map.put(:value, value)
      |> Map.put(:display, display)
      |> Map.put(:index, index)

    {:noreply, state}
  end

  # ignore the char
  defp do_handle_codepoint(_, _, state), do: {:noreply, state}
end
