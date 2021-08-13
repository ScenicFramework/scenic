#
#  Created by Boyd Multerer 2018-08-05.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
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
  alias Scenic.Component.Input.Caret
  alias Scenic.Primitive.Style.Theme
  # alias Scenic.Assets.Static

  require Logger

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
  @default_font_size 20
  @char_width 12
  @inset_x 10

  @default_type :text
  @default_filter :all

  @default_width @char_width * 24
  @default_height @default_font_size * 1.5

  @input_capture [:cursor_button, :codepoint, :key]

  @password_char '*'

  @hint_color :grey

  # --------------------------------------------------------
  @impl Scenic.Component
  def validate(text) when is_bitstring(text) do
    {:ok, text}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid TextField specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a TextField imust be a String#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def init(scene, value, opts) do
    id = opts[:id]

    # theme is passed in as an inherited style
    theme =
      (opts[:theme] || Theme.preset(:dark))
      |> Theme.normalize()

    # get the text_field specific opts
    hint = opts[:hint] || @default_hint
    width = opts[:width] || opts[:w] || @default_width
    height = opts[:height] || opts[:h] || @default_height
    type = opts[:type] || @default_type
    filter = opts[:filter] || @default_filter

    index = String.length(value)

    display = display_from_value(value, type)

    caret_v = -trunc((height - @default_font_size) / 4)

    scene =
      assign(
        scene,
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
        id: id,
        caret_v: caret_v
      )

    graph =
      Graph.build(
        font: @default_font,
        font_size: @default_font_size,
        scissor: {width, height}
      )
      |> rect(
        {width, height},
        # fill: :clear,
        fill: theme.background,
        stroke: {2, theme.border},
        id: :border,
        input: :cursor_button
      )
      |> group(
        fn g ->
          g
          |> text(
            @default_hint,
            fill: @hint_color,
            t: {0, @default_font_size},
            id: :text
          )
          |> Caret.add_to_graph(height, id: :caret)
        end,
        t: {@inset_x, 2}
      )
      |> update_text(display, scene.assigns)
      |> update_caret(display, index, caret_v)

    scene =
      scene
      |> assign(graph: graph)
      |> push_graph(graph)

    {:ok, scene}
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

  defp update_caret(graph, value, index, caret_v) do
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
    Graph.modify(graph, :caret, &update_opts(&1, t: {x, caret_v}))
  end

  # --------------------------------------------------------
  defp capture_focus(%{assigns: %{focused: false, graph: graph, theme: theme}} = scene) do
    # capture the input
    capture_input(scene, @input_capture)

    # start animating the caret
    cast_children(scene, :start_caret)

    # show the caret
    graph =
      graph
      |> Graph.modify(:caret, &update_opts(&1, hidden: false))
      |> Graph.modify(:border, &update_opts(&1, stroke: {2, theme.focus}))

    # update the state
    scene
    |> assign(focused: true, graph: graph)
    |> push_graph(graph)
  end

  # --------------------------------------------------------
  defp release_focus(%{assigns: %{focused: true, graph: graph, theme: theme}} = scene) do
    # release the input
    release_input(scene)

    # stop animating the caret
    cast_children(scene, :stop_caret)

    # hide the caret
    graph =
      graph
      |> Graph.modify(:caret, &update_opts(&1, hidden: true))
      |> Graph.modify(:border, &update_opts(&1, stroke: {2, theme.border}))

    # update the state
    scene
    |> assign(focused: false, graph: graph)
    |> push_graph(graph)
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

  defp accept_char?(_char, _filter) do
    true
  end

  # ============================================================================
  # User input handling - get the focus

  # --------------------------------------------------------
  # unfocused click in the text field
  @doc false
  @impl Scenic.Scene
  def handle_input(
        {:cursor_button, {0, :press, _, _}} = inpt,
        :border,
        %{assigns: %{focused: false}} = scene
      ) do
    handle_input(inpt, :border, capture_focus(scene))
  end

  # --------------------------------------------------------
  # focused click in the text field
  def handle_input(
        {:cursor_button, {0, :press, _, pos}},
        :border,
        %{assigns: %{focused: true, value: value, index: index, graph: graph, caret_v: caret_v}} =
          scene
      ) do
    {index, graph} =
      case index_from_cursor_pos(pos, value) do
        ^index ->
          {index, graph}

        i ->
          # reset_caret the caret blinker
          cast_children(scene, :reset_caret)

          # move the caret
          {i, update_caret(graph, value, i, caret_v)}
      end

    scene =
      scene
      |> assign(index: index, graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # focused click outside the text field
  def handle_input(
        {:cursor_button, {0, :press, _, _}},
        _id,
        %{assigns: %{focused: true}} = scene
      ) do
    {:cont, release_focus(scene)}
  end

  # ignore other button press events
  def handle_input({:cursor_button, {_, _, _, _}}, _id, scene) do
    {:noreply, scene}
  end

  # ============================================================================
  # control keys

  # --------------------------------------------------------
  # treat key repeats as a press
  def handle_input({:key, {key, :repeat, mods}}, id, scene) do
    handle_input({:key, {key, :press, mods}}, id, scene)
  end

  # --------------------------------------------------------
  def handle_input(
        {:key, {"left", :press, _}},
        _id,
        %{assigns: %{index: index, value: value, graph: graph, caret_v: caret_v}} = scene
      ) do
    # move left. clamp to 0
    {index, graph} =
      case index do
        0 ->
          {0, graph}

        i ->
          # reset_caret the caret blinker
          cast_children(scene, :reset_caret)
          # move the caret
          i = i - 1
          {i, update_caret(graph, value, i, caret_v)}
      end

    scene =
      scene
      |> assign(index: index, graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  def handle_input(
        {:key, {"right", :press, _}},
        _id,
        %{assigns: %{index: index, value: value, graph: graph, caret_v: caret_v}} = scene
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
          cast_children(scene, :reset_caret)

          # move the caret
          i = i + 1
          {i, update_caret(graph, value, i, caret_v)}
      end

    scene =
      scene
      |> assign(index: index, graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  def handle_input({:key, {"page_up", :press, mod}}, id, state) do
    handle_input({:key, {"home", :press, mod}}, id, state)
  end

  def handle_input(
        {:key, {"home", :press, _}},
        _id,
        %{assigns: %{index: index, value: value, graph: graph, caret_v: caret_v}} = scene
      ) do
    # move left. clamp to 0
    {index, graph} =
      case index do
        0 ->
          {index, graph}

        _ ->
          # reset the caret blinker
          cast_children(scene, :reset_caret)

          # move the caret
          {0, update_caret(graph, value, 0, caret_v)}
      end

    scene =
      scene
      |> assign(index: index, graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  def handle_input({:key, {"page_down", :press, mod}}, id, scene) do
    handle_input({:key, {"end", :press, mod}}, id, scene)
  end

  def handle_input(
        {:key, {"end", :press, _}},
        _id,
        %{assigns: %{index: index, value: value, graph: graph, caret_v: caret_v}} = scene
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
          cast_children(scene, :reset_caret)

          # move the caret
          {max_index, update_caret(graph, value, max_index, caret_v)}
      end

    scene =
      scene
      |> assign(index: index, graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # ignore backspace if at index 0
  def handle_input({:key, {"backspace", :press, _}}, _id, %{assigns: %{index: 0}} = scene),
    do: {:noreply, scene}

  # handle backspace
  def handle_input(
        {:key, {"backspace", :press, _}},
        _id,
        %{
          assigns: %{
            graph: graph,
            value: value,
            index: index,
            type: type,
            id: id,
            caret_v: caret_v
          }
        } = scene
      ) do
    # reset_caret the caret blinker
    cast_children(scene, :reset_caret)

    # delete the char to the left of the index
    value =
      String.to_charlist(value)
      |> List.delete_at(index - 1)
      |> to_string()

    display = display_from_value(value, type)

    # send the value changed event
    send_parent_event(scene, {:value_changed, id, value})

    # move the index
    index = index - 1

    # update the graph
    graph =
      graph
      |> update_text(display, scene.assigns)
      |> update_caret(display, index, caret_v)

    scene =
      scene
      |> assign(
        graph: graph,
        value: value,
        display: display,
        index: index
      )
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  def handle_input(
        {:key, {"delete", :press, _}},
        _id,
        %{
          assigns: %{
            graph: graph,
            value: value,
            index: index,
            type: type,
            id: id
          }
        } = scene
      ) do
    # ignore delete if at end of the field
    case index < String.length(value) do
      false ->
        {:noreply, scene}

      true ->
        # reset the caret blinker
        cast_children(scene, :reset_caret)

        # delete the char at the index
        value =
          String.to_charlist(value)
          |> List.delete_at(index)
          |> to_string()

        display = display_from_value(value, type)

        # send the value changed event
        send_parent_event(scene, {:value_changed, id, value})

        # update the graph (the caret doesn't move)
        graph = update_text(graph, display, scene.assigns)

        scene =
          scene
          |> assign(
            graph: graph,
            value: value,
            display: display,
            index: index
          )
          |> push_graph(graph)

        {:noreply, scene}
    end
  end

  # --------------------------------------------------------
  def handle_input({:key, {"enter", :press, _}}, _id, scene) do
    {:noreply, scene}
  end

  # --------------------------------------------------------
  def handle_input({:key, {"escape", :press, _}}, _id, scene) do
    {:noreply, scene}
  end

  # ============================================================================
  # text entry

  # --------------------------------------------------------
  def handle_input({:codepoint, {char, _}}, _id, %{assigns: %{filter: filter}} = scene) do
    case accept_char?(char, filter) do
      true -> do_handle_codepoint(char, scene)
      false -> {:noreply, scene}
    end
  end

  # --------------------------------------------------------
  def handle_input(_input, _id, scene) do
    {:noreply, scene}
  end

  # --------------------------------------------------------
  defp do_handle_codepoint(
         char,
         %{
           assigns: %{
             graph: graph,
             value: value,
             index: index,
             type: type,
             id: id,
             caret_v: caret_v
           }
         } = scene
       ) do
    # reset the caret blinker
    cast_children(scene, :reset_caret)

    # insert the char into the string at the index location
    {left, right} = String.split_at(value, index)
    value = Enum.join([left, char, right])
    display = display_from_value(value, type)

    # send the value changed event
    send_parent_event(scene, {:value_changed, id, value})

    # advance the index
    index = index + String.length(char)

    # update the graph
    graph =
      graph
      |> update_text(display, scene.assigns)
      |> update_caret(display, index, caret_v)

    scene =
      scene
      |> assign(
        graph: graph,
        value: value,
        display: display,
        index: index
      )
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def handle_get(_, %{assigns: %{value: value}} = scene) do
    {:reply, value, scene}
  end

  @doc false
  @impl Scenic.Scene
  def handle_put(v, %{assigns: %{value: value}} = scene) when v == value do
    # no change
    {:noreply, scene}
  end

  def handle_put(text, %{assigns: %{
    graph: graph,
    id: id,
    index: index,
    caret_v: caret_v,
    type: type
  }} = scene) when is_bitstring(text) do
    send_parent_event(scene, {:value_changed, id, text})

    display = display_from_value(text, type)

    # if the index is beyond the end of the string, move it back into range
    max_index = String.length(display)
    index = case index > max_index do
      true -> max_index
      false ->  index
    end

    graph =
      graph
      |> update_text(display, scene.assigns)
      |> update_caret(display, index, caret_v)

    scene =
      scene
      |> assign(graph: graph, value: text)
      |> push_graph(graph)

    {:noreply, scene}
  end

  def handle_put(v, %{assigns: %{id: id}} = scene) do
    Logger.warn( "Attempted to put an invalid value on TextField id: #{inspect(id)}, value: #{inspect(v)}")
    {:noreply, scene}
  end

  @doc false
  @impl Scenic.Scene
  def handle_fetch(_, %{assigns: %{value: value}} = scene) do
    {:reply, {:ok, value}, scene}
  end
end
