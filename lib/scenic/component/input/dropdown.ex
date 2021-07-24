#
#  Created by Boyd Multerer 2018-07-15.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Component.Input.Dropdown do
  @moduledoc """
  Add a dropdown to a graph

  ## Data

  `{items, initial_item}`

  * `items` - must be a list of items, each of which is: `{text, id}`. See below...
  * `initial_item` - the `id` of the initial selected item. It can be any term
  you want, however it must be an `item_id` in the `items` list. See below.

  Per item data:

  `{text, item_id}`

  * `text` - a string that will be shown in the dropdown.
  * `item_id` - any term you want. It will identify the item that is
  currently selected in the dropdown and will be passed back to you during
  event messages.

  ## Messages

  When the state of the checkbox, it sends an event message to the host scene
  in the form of:

  `{:value_changed, id, selected_item_id}`

  ## Options

  Dropdowns honor the following list of options.

  ## Styles

  Buttons honor the following styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ## Additional Styles

  Buttons honor the following list of additional styles.

  * `:width` - pass in a number to set the width of the button.
  * `:height` - pass in a number to set the height of the button.
  * `:direction` - what direction should the menu drop. Can be either `:down`
  or `:up`. The default is `:down`.

  ## Theme

  Dropdowns work well with the following predefined themes: `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text
  * `:background` - the background of the component
  * `:border` - the border of the component
  * `:active` - the background of selected item in the dropdown list
  * `:thumb` - the color of the item being hovered over

  ## Usage

  You should add/modify components via the helper functions in
  [`Scenic.Components`](Scenic.Components.html#dropdown/3)

  ## Examples

  The following example creates a dropdown and positions it on the screen.

      graph
      |> dropdown({[
        {"Dashboard", :dashboard},
        {"Controls", :controls},
        {"Primitives", :primitives}
      ], :controls}, id: :dropdown_id, translate: {20, 20})
  """
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.Primitive.Style.Theme
  import Scenic.Primitives
  alias Scenic.Assets.Static

  # import IEx

  @default_direction :down

  @default_font :roboto
  @default_font_size 20

  @drop_click_window_ms 400

  @caret {{0, 0}, {12, 0}, {6, 6}}
  @text_id :_dropbox_text_
  @caret_id :_caret_
  @dropbox_id :_dropbox_
  @button_id :_dropbox_btn_

  @rotate_neutral :math.pi() / 2
  @rotate_down 0
  @rotate_up :math.pi()

  @border_width 2

  # --------------------------------------------------------
  @impl Scenic.Component
  def validate({items, _} = data) when is_list(items) do
    # confirm all the entries
    Enum.reduce(items, {:ok, data}, fn
      _, {:error, _} = error -> error
      {text, _}, acc when is_bitstring(text) -> acc
      item, _ -> err_bad_item(item, data)
    end)
    |> case do
      {:error, _} = err ->
        err

      {:ok, {items, initial}} ->
        # confirm that initial is in the items list
        items
        |> Enum.any?(fn {_, id} -> id == initial end)
        |> case do
          true -> {:ok, data}
          false -> err_initial(data)
        end
    end
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Dropdown specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      Dropdown data must formed like: {[{text, id}], initial_id}

      This is a list of text/id pairs, and the id of the pair that is initially selected.#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_bad_item(item, data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Dropdown specification
      Received: #{inspect(data)}
      Invalid Item: #{inspect(item)}
      #{IO.ANSI.yellow()}
      Dropdown data must formed like: {[{text, id}], initial_id}

      This is a list of text/id pairs, and the id of the pair that is initially selected.#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_initial({_, initial} = data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Dropdown specification
      Received: #{inspect(data)}
      The initial id #{inspect(initial)} is not in the listed items
      #{IO.ANSI.yellow()}
      Dropdown data must formed like: {[{text, id}], initial_id}

      This is a list of text/id pairs, and the id of the pair that is initially selected.#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc false
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  @impl Scenic.Scene
  def init(scene, {items, initial_id}, opts) do
    id = opts[:id]

    # theme is passed in as an inherited style
    theme =
      (opts[:theme] || Theme.preset(:dark))
      |> Theme.normalize()

    # font related info
    {:ok, {Static.Font, fm}} = Static.fetch(@default_font)
    ascent = FontMetrics.ascent(@default_font_size, fm)
    descent = FontMetrics.descent(@default_font_size, fm)

    # find the width of the widest item
    fm_width =
      Enum.reduce(items, 0, fn {text, _}, w ->
        width = FontMetrics.width(text, @default_font_size, fm)

        max(w, width)
      end)

    width =
      case opts[:width] || opts[:w] do
        nil -> fm_width + ascent * 3
        :auto -> fm_width + ascent * 3
        width when is_number(width) and width > 0 -> width
      end

    height =
      case opts[:height] || opts[:h] do
        nil -> @default_font_size + ascent
        :auto -> @default_font_size + ascent
        height when is_number(height) and height > 0 -> height
      end

    # get the initial text
    initial_text =
      Enum.find_value(items, "", fn
        {text, ^initial_id} -> text
        _ -> false
      end)

    # calculate the drop box measures
    item_count = Enum.count(items)
    drop_height = item_count * height

    # get the drop direction
    direction = opts[:direction] || @default_direction

    # calculate the where to put the drop box. Depends on the direction
    translate_menu =
      case direction do
        :down -> {0, height + 1}
        :up -> {0, height * -item_count - 1}
      end

    # get the direction to rotate the caret
    rotate_caret =
      case direction do
        :down -> @rotate_down
        :up -> -@rotate_up
      end

    text_vpos = height / 2 + ascent / 2 + descent / 3

    # tune the final position
    dx = @border_width / 2
    dy = @border_width / 2

    graph =
      Graph.build(font: @default_font, font_size: @default_font_size, t: {dx, dy})
      |> rect(
        {width, height},
        fill: theme.background,
        stroke: {@border_width, theme.border},
        id: @button_id,
        input: true
      )
      |> text(initial_text,
        fill: theme.text,
        translate: {8, text_vpos},
        text_align: :left,
        id: @text_id
      )
      |> triangle(@caret,
        fill: theme.text,
        translate: {width - 18, height * 0.5},
        pin: {6, 0},
        rotate: @rotate_neutral,
        id: @caret_id
      )

      # an invisible rect for hit-test purposes
      # |> rect({width, height}, id: @button_id, input: true)

      # the drop box itself
      |> group(
        fn g ->
          g = rect(g, {width, drop_height}, fill: theme.background, stroke: {2, theme.border})

          {g, _} =
            Enum.reduce(items, {g, 0}, fn {text, id}, {g, i} ->
              g =
                group(
                  g,
                  # credo:disable-for-next-line Credo.Check.Refactor.Nesting
                  fn g ->
                    rect(
                      g,
                      {width, height},
                      fill:
                        if id == initial_id do
                          theme.active
                        else
                          theme.background
                        end,
                      id: id,
                      input: true
                    )
                    |> text(text,
                      fill: theme.text,
                      text_align: :left,
                      translate: {8, text_vpos}
                    )
                  end,
                  translate: {0, height * i}
                )

              {g, i + 1}
            end)

          g
        end,
        translate: translate_menu,
        id: @dropbox_id,
        hidden: true
      )

    scene =
      scene
      |> assign(
        graph: graph,
        selected_id: initial_id,
        theme: theme,
        id: id,
        down: false,
        hover_id: nil,
        items: items,
        drop_time: 0,
        rotate_caret: rotate_caret
      )
      |> push_graph(graph)

    {:ok, scene}
  end

  # ============================================================================
  # tracking when the dropdown is UP

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  # --------------------------------------------------------
  # mouse is moving around
  def handle_input(
        {:cursor_pos, _},
        nil,
        %Scene{
          assigns: %{
            down: true,
            items: items,
            graph: graph,
            selected_id: selected_id,
            theme: theme
          }
        } = scene
      ) do
    # set the appropriate hilighting for each of the items
    graph = update_highlighting(graph, items, selected_id, nil, theme)

    scene =
      scene
      |> assign(hover_id: nil, graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # over the @button_id
  def handle_input(
        {:cursor_pos, _},
        @button_id,
        %Scene{
          assigns: %{
            down: true,
            items: items,
            graph: graph,
            selected_id: selected_id,
            theme: theme
          }
        } = scene
      ) do
    # set the appropriate hilighting for each of the items
    graph = update_highlighting(graph, items, selected_id, nil, theme)

    scene =
      scene
      |> assign(hover_id: nil, graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # over an item
  def handle_input(
        {:cursor_pos, _},
        id,
        %Scene{
          assigns: %{
            down: true,
            items: items,
            graph: graph,
            selected_id: selected_id,
            theme: theme
          }
        } = scene
      ) do
    # set the appropriate hilighting for each of the items
    graph = update_highlighting(graph, items, selected_id, id, theme)

    scene =
      scene
      |> assign(hover_id: nil, graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_button, {0, :press, _, _}},
        @button_id,
        %Scene{assigns: %{down: false, graph: graph, rotate_caret: rotate_caret}} = scene
      ) do
    # capture input
    :ok = capture_input(scene, [:cursor_button, :cursor_pos])

    # drop the menu
    graph =
      graph
      |> Graph.modify(@caret_id, &update_opts(&1, rotate: rotate_caret))
      |> Graph.modify(@dropbox_id, &update_opts(&1, hidden: false))

    scene =
      scene
      |> assign(down: true, graph: graph, drop_time: :os.system_time(:milli_seconds))
      |> push_graph(graph)

    # IO.inspect(scene, label: "Press IN")
    {:noreply, scene}
  end

  # pressing the button when down, raises it back up without doing anything else
  def handle_input(
        {:cursor_button, {0, :press, _, _}},
        @button_id,
        %Scene{
          assigns: %{
            down: true,
            theme: theme,
            items: items,
            graph: graph,
            selected_id: selected_id
          }
        } = scene
      ) do
    # we are outside the window, raise it back up
    graph =
      graph
      |> update_highlighting(items, selected_id, nil, theme)
      |> Graph.modify(@caret_id, &update_opts(&1, rotate: @rotate_neutral))
      |> Graph.modify(@dropbox_id, &update_opts(&1, hidden: true))

    :ok = release_input(scene)

    scene =
      scene
      |> assign(down: false, hover_id: nil, graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # releasing the button when down, raises it back up without doing anything else
  def handle_input(
        {:cursor_button, {0, :release, _, _}},
        @button_id,
        %Scene{
          assigns: %{
            down: true,
            drop_time: drop_time,
            theme: theme,
            items: items,
            graph: graph,
            selected_id: selected_id
          }
        } = scene
      ) do
    if :os.system_time(:milli_seconds) - drop_time <= @drop_click_window_ms do
      # we are still in the click window, leave the menu down.
      {:noreply, scene}
    else
      # we are outside the window, raise it back up
      graph =
        graph
        |> update_highlighting(items, selected_id, nil, theme)
        |> Graph.modify(@caret_id, &update_opts(&1, rotate: @rotate_neutral))
        |> Graph.modify(@dropbox_id, &update_opts(&1, hidden: true))

      :ok = release_input(scene)

      scene =
        scene
        |> assign(down: false, hover_id: nil, graph: graph)
        |> push_graph(graph)

      {:noreply, scene}
    end
  end

  # --------------------------------------------------------
  # the button is pressed or released over an item with the drop open
  def handle_input(
        {:cursor_button, {0, _, _, _}},
        item_id,
        %Scene{
          assigns: %{
            down: true,
            id: id,
            items: items,
            theme: theme,
            graph: graph
          }
        } = scene
      )
      when item_id != nil do
    # send the value_changed message
    send_parent_event(scene, {:value_changed, id, item_id})

    # find the newly selected item's text
    {text, _} = Enum.find(items, fn {_, id} -> id == item_id end)

    graph =
      graph
      # update the main button text
      |> Graph.modify(@text_id, &text(&1, text))
      # restore standard highliting
      |> update_highlighting(items, item_id, nil, theme)
      # raise the dropdown
      |> Graph.modify(@caret_id, &update_opts(&1, rotate: @rotate_neutral))
      |> Graph.modify(@dropbox_id, &update_opts(&1, hidden: true))

    :ok = release_input(scene)

    scene =
      scene
      |> assign(down: false, graph: graph, selected_id: item_id)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # the button is pressed or released outside the dropdown space
  def handle_input(
        {:cursor_button, {0, _, _, _}},
        _,
        %Scene{
          assigns: %{
            # down: true,
            items: items,
            theme: theme,
            selected_id: selected_id,
            graph: graph
          }
        } = scene
      ) do
    graph = handle_cursor_button(graph, items, selected_id, theme)

    :ok = release_input(scene)

    scene =
      scene
      |> assign(down: false, graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # ignore other button press events
  def handle_input({:cursor_button, _}, _id, scene) do
    {:noreply, scene}
  end

  def handle_input({:cursor_pos, _}, _id, scene) do
    {:noreply, scene}
  end

  # ============================================================================
  # internal

  defp update_highlighting(graph, items, selected_id, hover_id, theme) do
    # set the appropriate hilighting for each of the items
    Enum.reduce(items, graph, fn
      # this is the item the user is hovering over
      {_, ^hover_id}, g ->
        Graph.modify(g, hover_id, &update_opts(&1, fill: theme.thumb))

      # this is the currently selected item
      {_, ^selected_id}, g ->
        Graph.modify(g, selected_id, &update_opts(&1, fill: theme.active))

      # not selected, not hovered over
      {_, regular_id}, g ->
        Graph.modify(g, regular_id, &update_opts(&1, fill: theme.background))
    end)
  end

  defp handle_cursor_button(graph, items, selected_id, theme) do
    graph
    # restore standard highliting
    |> update_highlighting(items, selected_id, nil, theme)
    # raise the dropdown
    |> Graph.modify(@caret_id, &update_opts(&1, rotate: @rotate_neutral))
    |> Graph.modify(@dropbox_id, &update_opts(&1, hidden: true))
  end

  # --------------------------------------------------------
  @impl GenServer
  @doc false
  def handle_call(:fetch, _, %{assigns: %{selected_id: selected_id}} = scene) do
    {:reply, {:ok, selected_id}, scene}
  end

  def handle_call({:put, id}, _, %{assigns: %{items: items}} = scene) do
    Enum.find(items, fn
      {_, ^id} -> true
      _ -> false
    end)
    |> case do
      {text, id} -> {:reply, :ok, do_put(text, id, scene)}
      _ -> {:reply, {:error, :invalid}, scene}
    end
  end

  defp do_put(
         text,
         item_id,
         %Scene{
           assigns: %{
             items: items,
             theme: theme,
             graph: graph,
             hover_id: hover_id
           }
         } = scene
       ) do
    graph =
      graph
      # update the main button text
      |> Graph.modify(@text_id, &text(&1, text))
      |> update_highlighting(items, item_id, hover_id, theme)

    scene
    |> assign(graph: graph, selected_id: item_id)
    |> push_graph(graph)
  end
end
