defmodule Scenic.Template.Input.RadioGroup do
  use Scenic.Template.Input

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Template.Input
  alias Scenic.Template.Input.RadioButton
  alias Scenic.Template.Input.RadioGroup

#  import IEx

  @v_spacing          16


  #----------------------------------------------------------------------------
  def build(buttons, opts \\ [] )

  def build(btns, opts ) when is_list(btns) do
    # build the radio group. Start with a empty graph
    # then add each radio button in the list    
    Input.build( opts )
    |> add_radio_buttons( btns )
    |> Graph.put_event_filter(0, {RadioGroup, :filter_input})
  end

  defp add_radio_buttons( graph, buttons, counter \\ 0)
  defp add_radio_buttons( graph, [], _), do: graph
  defp add_radio_buttons( graph, [btn | tail], c) do
    graph
    |> add_radio_button( btn, c )
    |> add_radio_buttons( tail, c + 1 )
  end

  defp add_radio_button( graph, {t,v}, c), do: add_radio_button( graph, {t,v,false}, c)
  defp add_radio_button( graph, {t,v,false}, {x,y}) do
    # no need to modify the parent group as this button is not selected
    RadioButton.add_to_graph(graph, {false, t}, input_value: v, translate: {x,y})
  end
  defp add_radio_button( graph, {t,v,true}, {x,y}) do
    # this radio button is selected. Default the parent group to it's value...
    # fortunately, the parent group is at uid 0, which makes this easy
    graph
    # this radio is set, use it's value as the group's value
    |> Graph.get( 0 )
    |> Input.put_value( v )
    |> ( &Graph.put(graph, 0, &1) ).()
    # add the radio button itself
    |> RadioButton.add_to_graph( {true, t}, input_value: v, translate: {x,y} )
  end
  # calculate the x,y position from the button count
  defp add_radio_button( graph, btn_info, c) when is_integer(c) do
    add_radio_button( graph, btn_info, {0, trunc(c * @v_spacing)})
  end



  #----------------------------------------------------------------------------
  # get the currently selected value in the radio group
  # which is stored in the top level group's state field
  def get( radio_group )
  def get( radio_group ) do
    # enforce that this is actually a radio group before responding
    case Primitive.get_event_filter(radio_group) do
      {RadioGroup, :filter_input} -> Primitive.get_state( radio_group )
    end
  end

  #----------------------------------------------------------------------------
  def filter_input(event, %Primitive{uid: group_uid} = radio_group, graph) do
    case event do

      {:click, radio_button, _pos } ->
        # get the new and old values
        old_value = Input.get_value(radio_group)
        new_value = Input.get_value(radio_button)

        # if the value changed, update the group
        if old_value == new_value do
          # no change, do nothing
          {:stop,  graph}
        else
          # did change, update the group
          # set the value of the selected radio button into the radio group
          # not using modify so as to not add to the update list here - maybe wants a flag?
          graph = Graph.get( graph, group_uid )
            |> Input.put_value( new_value )
            |> ( &Graph.put(graph, group_uid, &1) ).()

          graph = graph
          # uncheck all the radio buttons in the group
          |> Graph.find_modify( group_uid, [tag: :checkmark], fn(p) ->
            Primitive.put_style(p, :hidden, true)
          end)
          # check only the selected button
          |> Graph.find_modify( Primitive.get_uid(radio_button), [tag: :checkmark], fn(p) ->
            Primitive.put_style(p, :hidden, false)
          end)

          # create a new value_changed to send up the chain instead of click
          event = {:value_changed, radio_group, new_value}

          # send it up the chain
          {:continue, event, graph}
        end

      event ->
        {:continue, event, graph}
    end
  end

end






























