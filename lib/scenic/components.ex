#
#  Created by Boyd Multerer April 30, 2018.
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
  A set of helper functions to make it easy to add, or modify, components
  to a graph.


  In general, each helper function is of the form
      def name_of_component( graph, data, options \\\\ [] )

  Unlike primitives, components are scenes in themselves. Each component
  is is run by a GenServer and adding a basic component does two things.

    1) A new component GenServer is started and supervised by the owning
    scene's dynamic scene supervisor.
    2) A reference to the new scene is added to the graph.

  This doesn't happen all at once. These helper functions simply add
  a reference to a to-be-started component to your graph. When you call
  push_graph/1 to send this graph to be rendered, these components are
  picked up, mapped to the host scene and started.

  You can also supervise components yourself, but then you should add
  the scene_ref yourself via the scene_ref/3 function, which is in the
  Scenice.Primitives module.

  When adding components to a graph, each helper function accepts a
  graph as the first parameter and returns the transformed graph. This
  makes is very easy to buid a complex graph by piping helper functions
  together.

      @graph Graph.build()
      |> button( {"Press Me", :btn_pressed}, id: :btn_id )

  When modifying a graph, you can again use the helpers by passing
  in the component to be modified. The transformed component will
  be returned.

      Graph.modify(graph, :btn_id, fn(p) ->
        button(p, {"Continue", :btn_pressed})
      end)

      # or, more compactly...

      Graph.modify(graph, :btn_id, &button(&1, {"Continue", :btn_pressed}) )

  In each case, the second parameter is a data term that is specific
  to the component being acted on. See the documentation below. If you
  pass in invalid data for the second parameter an error will be 
  thrown along with some explanation of what it expected.

  The third parameter is a keyword list of options that are to be
  applied to the component. This includes setting the id, styles,
  transforms and such.

      @graph Graph.build()
      |> button( {"Press Me", :btn_pressed}, id: :btn_id, rotate: 0.4)


  ### Event messages

  Most basic or input components exist to collect data and/or send
  messages to the host scene that references.

  For example, when a button scene decides that it has been "clicked",
  the generic button component doesn't know how to do anything with that
  information. So it sends a `{:click, button_id}` to the host scene
  that referenced it.

  That scene can intercept the message, act on it, transform it, and/or
  send it up to the host scene that references it. (Components can be
  nested many layers deep)

  To do this, the **host scene** should implement the `filter_event` callback.

  examples:

        def filter_event( {:click, :example_id}, _, state ) do
          {:stop, state }
        end

        def filter_event( {:click, :example_id}, _, state ) do
          {:continue, {:click, :transformed}, state }
        end

  Inside a filter_event callback you can modify a graph, change state,
  send messages, transform the event, stop the event, and much more.


  ### Style options

  Because components are seperate scenes, they generally do not inherit
  the styles set by the host scene that references them. This makes sense
  as most components should have a consistent look and feel regardless
  of the font style or fill set by the host.

  If you want to stylize a component, check the docs for that module.
  Most of them have options allowing you to do that as appropriate.

  ### Transform options

  Transform options set on the host do affect any components they refernce.

  These options affect the size, position and rotation of elements in the
  graph. Any transform you can express as a 4x4 matrix of floats, you can apply
  to any component in the graph, including groups and scene_refs.

  This is done mathematically as a "stack" of transforms. As the renderer
  traverses up and down the graph, transforms are pushed and popped from the
  matrix stack as appropriate. Transform inheritence does cross SceneRef
  boundaries.

  ## Draw Order
  
  Primitives will be drawn in the order you add them to the graph.
  For example, the graph below draws a buttonon top of a filled rectangle.
  If the order of the text and rectangle were reversed, they would both
  still be rendered, but the buuton would not be visible because the
  rectangle would cover it up.

      @graph Graph.build( font: {:roboto, 20} )
      |> rect( {100, 200}, color: :blue )
      |> button( {"Press Me", :btn_pressed})
  """


  #--------------------------------------------------------
  @doc """
  Add a button to a graph

  A button is a small scene that is pretty much just some text
  drawn over a rounded rectangle. The button scene contains logic to detect
  when the button is pressed, tracks it as the pointer moves around, and
  when it is released.

  Data:

      {text, button_id, options \\\\ []}

  * `text` must be a bitstring
  * `id` can be any term you want. It will be passed back to you during event messages.
  * `options` should be a list of options (see below). It is not required.

  ### Messages

  If a button press is successful, it sends an event message to the host
  scene in the form of:

      {:click, button_id}


  ### Options

  Buttons honor the following list of options.

  * `:theme` - This sets the color scheme of the button. This can be one of
  pre-defined button schemes `:primary`, `:secondary`, `:success`, `:danger`,
  `:warning`, `:info`, `:light`, `:dark`, `:text` or it can be a completly custom
  scheme like this:

      {text_color, button_color, pressed_color}

  * `:width` - pass in a number to set the width of the button.
  * `:height` - pass in a number to set the height of the button.
  * `:radius` - pass in a number to set the radius of the button's rounded rectangle.
  * `:align` - set the aligment of the text inside the button. Can be one of
  `:left, :right, :center`. The default is `:center`.


  ### Styles

  Buttons honor the following styles
  
  * `:hidden` - If true the button is rendered. If false, it is skipped. The default
    is true.

  ### Examples

  The following example creates a simple button and positions it on the screen.

      graph
      |> button( {"Example", :button_id}, translate: {20, 20} )

  The next example makes the same button as before, but colors it as a warning button. See
  the options list above for more details.

      graph
      |> button( {"Example", :button_id, type: :warning}, translate: {20, 20} )


  """
  def button( graph, data, options \\ [] )

  def button( %Graph{} = g, data, options ) do
    add_to_graph( g, Component.Button, data, options )
  end

  def button( %Primitive{module: SceneRef} = p, data, options ) do
    modify( p, Component.Button, data, options )
  end

  #--------------------------------------------------------
  @doc """
  Add a checkbox to a graph

  Data:

      {text, id, checked?, options \\\\ []}

  * `text` must be a bitstring
  * `id` can be any term you want. It will be passed back to you during event messages.
  * `checked?` must be a boolean and indicates if the checkbox is set.
  * `options` should be a list of options (see below). It is not required


  ### Messages

  When the state of the checkbox, it sends an event message to the host
  scene in the form of:

      {:value_changed, checkbox_id, checked?}

  ### Options

  Checkboxes honor the following list of options.

  * `:theme` - This sets the color scheme of the button. This can be one of
  pre-defined button schemes `:light`, `:dark`, or it can be a completly custom
  scheme like this:

      {text_color, background_color, border_color, pressed_color, checkmark_color}

  ### Styles

  Buttons honor the following styles
  
  * `:hidden` - If true the button is rendered. If false, it is skipped. The default
    is true.

  ### Examples

  The following example creates a checkbox and positions it on the screen.

      graph
      |> checkbox( {"Example", :checkbox_id, true}, translate: {20, 20} )

  """
  def checkbox( graph, data, options \\ [] )

  def checkbox( %Graph{} = g, data, options ) do
    add_to_graph( g, Component.Input.Checkbox, data, options )
  end

  def checkbox( %Primitive{module: SceneRef} = p, data, options ) do
    modify( p, Component.Input.Checkbox, data, options )
  end

  #--------------------------------------------------------
  @doc """
  Add a dropdown to a graph

  Data:

      {items, initial_item, id, options \\\\ []}

  * `items` must be a list of items, each of which is: {text, id}. See below...
  * `initial_item` is the id of the initial selected item. It can be any term you want.
  * `id` can be any term you want. It will be passed back to you during event messages.
  * `options` should be a list of options (see below). It is not required

  Item data:
    
      {text, id}

  * `text` is a string that will be shown in the dropdown.
  * `id` can be any term you want. It will identify the item that is currently selected
  in the dropdown and will be passed back to you during event messages.


  ### Messages

  When the state of the checkbox, it sends an event message to the host
  scene in the form of:

      {:value_changed, dropdown_id, selected_item_id}


  ### Options

  Dropdowns honor the following list of options.

  * `:theme` - This sets the color scheme of the button. This can be one of
  pre-defined button schemes `:light`, `:dark`, or it can be a completly custom
  scheme like this:

      {text_color, background_color, pressed_color, border_color, carat_color, hover_color}

  ### Styles

  Buttons honor the following styles
  
  * `:hidden` - If true the button is rendered. If false, it is skipped. The default
    is true.

  ### Examples

  The following example creates a dropdown and positions it on the screen.

      graph
      |> dropdown({[
        {"Dashboard", :dashboard},
        {"Controls", :controls},
        {"Primitives", :primitives},
      ], :controls, :dropdown_id }, translate: {20, 20} )

  """
  def dropdown( graph, data, options \\ [] )

  def dropdown( %Graph{} = g, data, options ) do
    add_to_graph( g, Component.Input.Dropdown, data, options )
  end

  def dropdown( %Primitive{module: SceneRef} = p, data, options ) do
    modify( p, Component.Input.Dropdown, data, options )
  end

  #--------------------------------------------------------
  @doc """
  Add a radio group to a graph

  Data:

      {radio_buttons, group_id}

  * `radio_buttons` must be a list of radio button data. See below.
  * `id` can be any term you want. It will be passed back to you during event messages.

  The `items` term must be a list of RadioButton init data.

  Radio button data:

      {text, button_id, checked? \\\\ false, options \\\\ []}

  * `text` must be a bitstring
  * `button_id` can be any term you want. It will be passed back to you as the group's value.
  * `checked?` must be a boolean and indicates if the button is selected. `checked?` is not
  required and will default to `false` if not supplied.
  * `options` should be a list of options (see below). It is not required


  ### Messages

  When the state of the radio group changes, it sends an event message to the host
  scene in the form of:

      {:value_changed, group_id, button_id}


  ### Options

  Buttons honor the following list of options.

  * `:theme` - This sets the color scheme of the button. This can be one of
  pre-defined button schemes `:light`, `:dark`, or it can be a completly custom
  scheme like this: `{text_color, box_background, border_color, pressed_color, checkmark_color}`.

  ### Styles

  Buttons honor the following styles
  
  * `:hidden` - If true the button is rendered. If false, it is skipped. The default
    is true.

  ### Examples

  The following example creates a radio group and positions it on the screen.

      graph
      |> radio_group({[
          {"Radio A", :radio_a},
          {"Radio B", :radio_b, true},
          {"Radio C", :radio_c},
        ], :radio_group_id },
        translate: {20, 20} )

  """
  def radio_group( graph, data, options \\ [] )

  def radio_group( %Graph{} = g, data, options ) do
    add_to_graph( g, Component.Input.RadioGroup, data, options )
  end

  def radio_group( %Primitive{module: SceneRef} = p, data, options ) do
    modify( p, Component.Input.RadioGroup, data, options )
  end

  #--------------------------------------------------------
  @doc """
  Add a slider to a graph

  Data:

      { extents, initial_value, id, options \\\\ [] }

  * `extents` gives the range of values. It can take several forms...
    * `{min,max}` If min and max are integers, then the slider value will be an integer.
    * `{min,max}` If min and max are floats, then the slider value will be an float.
    * `[a, b, c]` A list of terms. The value will be one of the terms
  * `initial_value` Sets the intial value (and position) of the slider. It must make
  sense with the extents you passed in.
  * `id` can be any term you want. It will be passed back to you during event messages.
  * `options` should be a list of options (see below). It is not required

  ### Messages

  When the state of the slider changes, it sends an event message to the host
  scene in the form of:

      {:value_changed, id, value}


  ### Options

  Sliders honor the following list of options.

  * `:theme` - This sets the color scheme of the button. This can be one of
  pre-defined button schemes `:light`, `:dark`, or it can be a completly custom
  scheme like this: `{line_color, thumb_color}`.

  ### Styles

  Sliders honor the following styles
  
  * `:hidden` - If true the button is rendered. If false, it is skipped. The default
    is true.

  ### Examples

  The following example creates a numeric sliderand positions it on the screen.

      graph
      |> Component.Input.Slider.add_to_graph( {{0,100}, 0, :num_slider}, translate: {20,20} )

  The following example creates a list slider and positions it on the screen.

      graph
      |> slider( {[
          :white,
          :cornflower_blue,
          :green,
          :chartreuse
        ], :cornflower_blue, :slider_id}, translate: {20,20} )

  """
  def slider( graph, data, options \\ [] )

  def slider( %Graph{} = g, data, options ) do
    add_to_graph( g, Component.Input.Slider, data, options )
  end

  def slider( %Primitive{module: SceneRef} = p, data, options ) do
    modify( p, Component.Input.Slider, data, options )
  end
  #--------------------------------------------------------
  @doc """
  Add a text field input to a graph

  Data: {initial_value, id, options \\\\ []}

  * `initial_value` is the string that will be the starting value
  * `id` can be any term you want. It will be passed back to you during event messages.
  * `options` should be a list of options (see below). It is not required


  ### Options

  Text fields honor the following list of options.
  
  * `:filter` - Adding a filter option restricts which characters can be entered
    into the text_field component. The value of filter can be one of:
    * `:all` - Accept all characters. This is the default
    * `:number` - Any characters from "0123456789.,"
    * `"filter_string"` - Pass in a string containing all the characters you will accept
    * `function/1` - Pass in an anonymous function. The single parameter will be
      the character to be filtered. Return true or false to keep or reject it.
  * `:hint` - A string that will be shown (greyed out) when the entered value
    of the componenet is empty.
  * `:type` - Can be one of the following options:
    * `:all` - Show all characters. This is the default.
    * `:password` - Display a string of '*' characters instead of the value.
  * `:theme` - Choose the color scheme of the component. Can be one of:
    * `:light` - Dark text on a light background
    * `:dark` - Light text on a dark background. This is the default.
    * `custom` - A custom set of colors in the form of:
      `{text_color, background_color, border_color, focused_color}`
  * `:width` - set the width of the control.


  ### Messages

  When the text in the field changes, it sends an event message to the host
  scene in the form of:

      {:value_changed, id, value}


  ### Styles

  Text fields honor the following styles
  
  * `:hidden` - If true the button is rendered. If false, it is skipped. The default
    is true.

  ### Examples

      graph
      |> text_field( {"Sample Text", :text_id}, translate: {20,20} )

      graph
      |> text_field(
        {"", :pass_id, [type: :password, hint: "Enter password"]},
        translate: {20,20}
      )
  """
  def text_field( graph, data, options \\ [] )

  def text_field( %Graph{} = g, data, options ) do
    add_to_graph( g, Component.Input.TextField, data, options )
  end

  def text_field( %Primitive{module: SceneRef} = p, data, options ) do
    modify( p, Component.Input.TextField, data, options )
  end


  #============================================================================
  # generic workhorse versions

  defp add_to_graph( %Graph{} = g, mod, data, options ) do
    mod.verify!(data)
    mod.add_to_graph(g, data, options)
  end

  defp modify( %Primitive{module: SceneRef} = p, mod, data, options ) do
    mod.verify!(data)
    Primitive.put( p, {mod, data}, options )
  end


end






