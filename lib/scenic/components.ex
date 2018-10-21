#
#  Created by Boyd Multerer 2018-04-30.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# convenience functions for adding basic components to a graph.
# this module should be updated as new base components are added

defmodule Scenic.Components do
  alias Scenic.Component
  alias Scenic.Primitive
  alias Scenic.Primitive.SceneRef
  alias Scenic.Graph

  # import IEx

  @moduledoc """

  ## About Components

  Components are small scenes that are referenced, and managed, by another
  scene.  They are useful for reusing bits of UI and containing the logic that
  runs them.

  ## Helper Functions

  This module contains a set of helper functions to make it easy to add, or
  modify, the standard components in a graph.

  In general, each helper function is of the form:

      def name_of_component(graph, data, options \\\\ [])

  Unlike primitives, components are scenes in themselves. Each component is
  run by a `GenServer` and adding a basic component does two things.

  1. A new component `GenServer` is started and supervised by the owning scene's
  dynamic scene supervisor.
  1. A reference to the new scene is added to the graph.

  This doesn't happen all at once. These helper functions simply add a
  reference to a to-be-started component to your graph. When you call
  `push_graph/1` to the ViewPort then manages the life cycle of the components.

  You can also supervise components yourself, but then you should add the scene
  reference yourself via the `scene_ref/3` function, which is in the
  `Scenic.Primitives` module.

  When adding components to a graph, each helper function accepts a graph as
  the first parameter and returns the transformed graph. This makes is very
  easy to build a complex graph by piping helper functions together.

      @graph Graph.build()
      |> button("Press Me", id: :sample_button)

  When modifying a graph, you can again use the helpers by passing in the
  component to be modified. The transformed component will be returned.

      Graph.modify(graph, :sample_button, fn(p) ->
        button(p, "Continue")
      end)

      # or, more compactly...

      Graph.modify(graph, :sample_button, &button(&1, "Continue"))

  In each case, the second parameter is a data term that is specific to the
  component being acted on. See the documentation below. If you pass in invalid
  data for the second parameter an error will be thrown along with some
  explanation of what it expected.

  The third parameter is a keyword list of options that are to be applied to
  the component. This includes setting the id, styles, transforms and such.

      @graph Graph.build()
      |> button("Press Me", id: :sample_button, rotate: 0.4)

  ### Event messages

  Most basic or input components exist to collect data and/or send messages to
  the host scene that references.

  For example, when a button scene decides that it has been "clicked", the
  generic button component doesn't know how to do anything with that
  information. So it sends a `{:click, id}` to the host scene that referenced
  it.

  That scene can intercept the message, act on it, transform it, and/or send it
  up to the host scene that references it. (Components can be nested many
  layers deep)

  To do this, the **host scene** should implement the `filter_event` callback.

  ## Examples:

        def filter_event({:click, :sample_button}, _, state) do
          {:stop, state}
        end

        def filter_event({:click, :sample_button}, _, state) do
          {:continue, {:click, :transformed}, state}
        end

  Inside a `filter_event` callback you can modify a graph, change state, send
  messages, transform the event, stop the event, and much more.
  """

  # --------------------------------------------------------
  @doc """
  Add a [`Button`](Scenic.Component.Button.html) to a graph

  A button is a small scene that is pretty much just some text drawn over a
  rounded rectangle. The button scene contains logic to detect when the button
  is pressed, tracks it as the pointer moves around, and when it is released.

  ### Data

  `title`

  * `title` - a bitstring describing the text to show in the button

  ### Messages

  If a button press is successful, it sends an event message to the host scene
  in the form of:

      {:click, id}

  ### Styles

  Buttons honor the following standard styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:primary`

  ### Additional Styles

  Buttons honor the following list of additional styles.

  * `:width` - pass in a number to set the width of the button.
  * `:height` - pass in a number to set the height of the button.
  * `:radius` - pass in a number to set the radius of the button's rounded
  rectangle.
  * `:alignment` - set the alignment of the text inside the button. Can be one
  of `:left, :right, :center`. The default is `:center`.
  * `:button_font_size` - the size of the font in the button

  Buttons do not use the inherited `:font_size` style as they should look
  consistent regardless of what size the surrounding text is.

  ### Theme

  Buttons work well with the following predefined themes:
  `:primary`, `:secondary`, `:success`, `:danger`, `:warning`, `:info`,
  `:text`, `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text in the button
  * `:background` - the normal background of the button
  * `:active` - the background while the button is pressed

  ### Examples

  The following example creates a simple button and positions it on the screen.

      graph
      |> button("Example", id: :button_id, translate: {20, 20})

  The next example makes the same button as before, but colors it as a warning
  button. See the options list above for more details.

      graph
      |> button("Example", id: :button_id, translate: {20, 20}, theme: :warning)

  """
  @spec button(
          source :: Graph.t() | Primitive.t(),
          title :: String.t(),
          options :: list
        ) :: Graph.t() | Primitive.t()

  def button(graph, title, options \\ [])

  def button(%Graph{} = g, data, options) do
    add_to_graph(g, Component.Button, data, options)
  end

  def button(%Primitive{module: SceneRef} = p, data, options) do
    modify(p, Component.Button, data, options)
  end

  # --------------------------------------------------------
  @doc """
  Add a [`Checkbox`](Scenic.Component.Input.Checkbox.html) to a graph

  ### Data

  `{text, checked?}`

  * `text` - must be a bitstring
  * `checked?` - must be a boolean and indicates if the checkbox is set.

  ### Messages

  When the state of the checkbox, it sends an event message to the host scene
  in the form of:

  `{:value_changed, id, checked?}`

  ### Styles

  Buttons honor the following standard styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ### Theme

  Checkboxes work well with the following predefined themes: `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text in the button
  * `:background` - the background of the box
  * `:border` - the border of the box
  * `:active` - the border of the box while the button is pressed
  * `:thumb` - the color of the check mark itself

  ### Examples

  The following example creates a checkbox and positions it on the screen.

      graph
      |> checkbox({"Example", true}, id: :checkbox_id, translate: {20, 20})

  """
  @spec checkbox(
          source :: Graph.t() | Primitive.t(),
          data :: {String.t(), boolean},
          options :: list
        ) :: Graph.t() | Primitive.t()

  def checkbox(graph, data, options \\ [])

  def checkbox(%Graph{} = g, data, options) do
    add_to_graph(g, Component.Input.Checkbox, data, options)
  end

  def checkbox(%Primitive{module: SceneRef} = p, data, options) do
    modify(p, Component.Input.Checkbox, data, options)
  end

  # --------------------------------------------------------
  @doc """
  Add a [`Dropdown`](Scenic.Component.Input.Dropdown.html) to a graph

  ### Data

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

  ### Messages

  When the state of the checkbox, it sends an event message to the host scene
  in the form of:

  `{:value_changed, id, selected_item_id}`

  ### Options

  Dropdowns honor the following list of options.

  ### Styles

  Buttons honor the following styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ### Additional Styles

  Buttons honor the following list of additional styles.

  * `:width` - pass in a number to set the width of the button.
  * `:height` - pass in a number to set the height of the button.
  * `:direction` - what direction should the menu drop. Can be either `:down`
  or `:up`. The default is `:down`.

  ### Theme

  Dropdowns work well with the following predefined themes: `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text
  * `:background` - the background of the component
  * `:border` - the border of the component
  * `:active` - the background of selected item in the dropdown list
  * `:thumb` - the color of the item being hovered over

  ### Examples

  The following example creates a dropdown and positions it on the screen.

      graph
      |> dropdown({[
        {"Dashboard", :dashboard},
        {"Controls", :controls},
        {"Primitives", :primitives}
      ], :controls}, id: :dropdown_id, translate: {20, 20})

  """
  @spec dropdown(
          source :: Graph.t() | Primitive.t(),
          data :: {list({String.t(), any}), any},
          options :: list
        ) :: Graph.t() | Primitive.t()

  def dropdown(graph, data, options \\ [])

  def dropdown(%Graph{} = g, data, options) do
    add_to_graph(g, Component.Input.Dropdown, data, options)
  end

  def dropdown(%Primitive{module: SceneRef} = p, data, options) do
    modify(p, Component.Input.Dropdown, data, options)
  end

  # --------------------------------------------------------
  @doc """
  Add a [`RadioGroup`](Scenic.Component.Input.RadioGroup.html) to a graph

  ### Data

  `radio_buttons`

  * `radio_buttons` must be a list of radio button data. See below.

  Radio button data:

  `{text, radio_id, checked? \\\\ false}`

  * `text` - must be a bitstring
  * `button_id` - can be any term you want. It will be passed back to you as the
  group's value.
  * `checked?` - must be a boolean and indicates if the button is selected.
  `checked?` is not required and will default to `false` if not supplied.

  ### Messages

  When the state of the radio group changes, it sends an event message to the
  host scene in the form of:

  `{:value_changed, id, radio_id}`

  ### Options

  Radio Buttons honor the following list of options.

  * `:theme` - This sets the color scheme of the button. This can be one of
  pre-defined button schemes `:light`, `:dark`, or it can be a completely custom
  scheme like this: `{text_color, box_background, border_color, pressed_color,
  checkmark_color}`.

  ### Styles

  Radio Buttons honor the following styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ### Theme

  Radio buttons work well with the following predefined themes: `:light`,
  `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text
  * `:background` - the background of the component
  * `:border` - the border of the component
  * `:active` - the background of the circle while the button is pressed
  * `:thumb` - the color of inner selected-mark

  ### Examples

  The following example creates a radio group and positions it on the screen.

      graph
      |> radio_group([
          {"Radio A", :radio_a},
          {"Radio B", :radio_b, true},
          {"Radio C", :radio_c},
        ], id: :radio_group_id, translate: {20, 20})
  """
  @spec radio_group(
          source :: Graph.t() | Primitive.t(),
          data :: list({String.t(), any} | {String.t(), any, boolean}),
          options :: list
        ) :: Graph.t() | Primitive.t()
  def radio_group(graph, data, options \\ [])

  def radio_group(%Graph{} = g, data, options) do
    add_to_graph(g, Component.Input.RadioGroup, data, options)
  end

  def radio_group(%Primitive{module: SceneRef} = p, data, options) do
    modify(p, Component.Input.RadioGroup, data, options)
  end

  # --------------------------------------------------------
  @doc """
  Add a [`Slider`](Scenic.Component.Input.Slider.html) to a graph

  ### Data

  `{ extents, initial_value}`

  * `extents` gives the range of values. It can take several forms...
    * `{min, max}` If `min` and `max` are integers, then the slider value will
    be an integer.
    * `{min, max}` If `min` and `max` are floats, then the slider value will be
    an float.
    * `[a, b, c]` A list of terms. The value will be one of the terms
  * `initial_value` Sets the initial value (and position) of the slider. It
  must make sense with the extents you passed in.

  ### Messages

  When the state of the slider changes, it sends an event message to the host
  scene in the form of:

  `{:value_changed, id, value}`

  ### Options

  Sliders honor the following list of options.

  ### Styles

  Sliders honor the following styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ### Theme

  Sliders work well with the following predefined themes: `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:border` - the color of the slider line
  * `:thumb` - the color of slider thumb

  ### Examples

  The following example creates a numeric slider and positions it on the screen.

      graph
      |> slider({{0,100}, 0}, id: :num_slider, translate: {20,20})

  The following example creates a list slider and positions it on the screen.

      graph
      |> slider({[
          :white,
          :cornflower_blue,
          :green,
          :chartreuse
        ], :cornflower_blue}, id: :slider_id, translate: {20,20})

  """
  @spec slider(
          source :: Graph.t() | Primitive.t(),
          data :: {{number, number}, number} | list,
          options :: list
        ) :: Graph.t() | Primitive.t()

  def slider(graph, data, options \\ [])

  def slider(%Graph{} = g, data, options) do
    add_to_graph(g, Component.Input.Slider, data, options)
  end

  def slider(%Primitive{module: SceneRef} = p, data, options) do
    modify(p, Component.Input.Slider, data, options)
  end

  # --------------------------------------------------------
  @doc """
  Add a [`TextField`](Scenic.Component.Input.TextField.html) input to a graph

  ### Data

  `initial_value`

  * `initial_value` - is the string that will be the starting value

  ### Messages

  When the text in the field changes, it sends an event message to the host
  scene in the form of:

  `{:value_changed, id, value}`

  ### Styles

  Text fields honor the following styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ### Additional Styles

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

  ### Theme

  Text fields work well with the following predefined themes: `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text
  * `:background` - the background of the component
  * `:border` - the border of the component
  * `:focus` - the border while the component has focus

  ### Examples

      graph
      |> text_field("Sample Text", id: :text_id, translate: {20,20})

      graph
      |> text_field(
        "", id: :pass_id, type: :password, hint: "Enter password", translate: {20,20}
      )
  """
  @spec text_field(
          source :: Graph.t() | Primitive.t(),
          data :: String.t(),
          options :: list
        ) :: Graph.t() | Primitive.t()

  def text_field(graph, data, options \\ [])

  def text_field(%Graph{} = g, data, options) do
    add_to_graph(g, Component.Input.TextField, data, options)
  end

  def text_field(%Primitive{module: SceneRef} = p, data, options) do
    modify(p, Component.Input.TextField, data, options)
  end

  @doc """
  Add [`Toggle`](Scenic.Component.Input.Toggle.html) to a Scenic graph.

  ### Data

  `on?`

  * `on?` - `true` if the toggle is on, pass `false` if not.

  ### Styles

  Toggles honor the following styles. The `:light` and `:dark` styles look nice. The other bundled themes...not so much. You can also [supply your own theme](Scenic.Toggle.Components.html#toggle/3-theme).

  * `:hidden` - If `false` the toggle is rendered. If true, it is skipped. The default
    is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ### Additional Styles

  Toggles also honor the following additional styles.

  * `:border_width` - the border width. Defaults to `2`.
  * `:padding` - the space between the border and the thumb. Defaults to `2`
  * `:thumb_radius` - the radius of the thumb. This determines the size of the entire toggle. Defaults to `10`.

  ### Theme

  To pass in a custom theme, supply a map with at least the following entries:

  * `:border` - the color of the border around the toggle
  * `:background` - the color of the track when the toggle is `off`.
  * `:text` - the color of the thumb.
  * `:thumb` - the color of the track when the toggle is `on`.

  Optionally, you can supply the following entries:

  * `:thumb_pressed` - the color of the thumb when pressed. Defaults to `:gainsboro`.

  ### Examples

  The following example creates a toggle.
      graph
      |> toggle(true, translate: {20, 20})

  The next example makes a larger toggle.
      graph
      |> toggle(true, translate: {20, 20}, thumb_radius: 14)
  """
  @spec toggle(Graph.t() | Primitive.t(), boolean, Keyword.t() | nil) :: Graph.t()
  def toggle(graph, data, options \\ [])

  def toggle(%Graph{} = g, data, options) do
    add_to_graph(g, Component.Input.Toggle, data, options)
  end

  def toggle(%Primitive{module: SceneRef} = p, data, options) do
    modify(p, Component.Input.Toggle, data, options)
  end

  # ============================================================================
  # generic workhorse versions

  defp add_to_graph(%Graph{} = g, mod, data, options) do
    mod.verify!(data)
    mod.add_to_graph(g, data, options)
  end

  defp modify(%Primitive{module: SceneRef} = p, mod, data, options) do
    mod.verify!(data)
    Primitive.put(p, {mod, data}, options)
  end
end
