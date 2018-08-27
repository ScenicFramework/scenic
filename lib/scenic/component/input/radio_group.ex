defmodule Scenic.Component.Input.RadioGroup do
  use Scenic.Component, has_children: true

  alias Scenic.Graph
  alias Scenic.Scene
  # alias Scenic.Primitive
  alias Scenic.Component.Input.RadioButton
  # alias Scenic.Primitive.Style.Paint.Color
  import Scenic.Primitives, only: [{:group, 2}]
#  import IEx

  @line_height      22

#  #--------------------------------------------------------
  def info() do
    "#{IO.ANSI.red()}RadioGroup data must be: {items, id}\r\n" <>
    IO.ANSI.yellow() <>
    "Position the radio group by adding a transform\r\n" <>
    "The message will be sent to you in a :value_changed event when the state" <>
    "of the radio buttons changes.\r\n" <>
    "Each item in the items list must be a valid init data for a radio button.\r\n" <>
    "Info for a radio button is below...\r\n" <>
    "\r\n" <>
    RadioButton.info() <>
    IO.ANSI.default_color()
  end

  #--------------------------------------------------------
  def verify( {items, _msg} = data) when is_list(items) do
    items
    |> Enum.all?( fn(item) ->
      case RadioButton.verify( item ) do
        {:ok, _} -> true
        _ -> false
      end
    end)
    |> case do
      true -> {:ok, data}
      _ -> :invalid_data
    end
  end
  def verify( _ ), do: :invalid_data

  #--------------------------------------------------------
  # def valid?( _items ), do: true

  #--------------------------------------------------------
  def init( {items, id}, styles, _viewport ) when is_list(items) do
    graph = Graph.build(font: :roboto, font_size: 16)
    |> group(fn(graph) ->
      {graph, _} = Enum.reduce(items, {graph, 0}, fn
        {t,m}, {g, voffset} ->
          g = RadioButton.add_to_graph(g, {t, m, false}, 
            translate: {0,voffset}, styles: styles
          )
          {g, voffset + @line_height}

        {t,m,v}, {g, voffset} ->
          g = RadioButton.add_to_graph(g, {t, m, v},
            translate: {0,voffset}, styles: styles
          )
          {g, voffset + @line_height}
      end)
      graph
    end)

    value = Enum.find_value(items, fn
      {_t,_m} -> nil
      {_t,_m, false} -> nil
      {_t,m, true} -> m
    end)

    state = %{
      graph: graph,
      value: value,
      id: id
    }

    push_graph( graph )

    {:ok, state}
  end

  #--------------------------------------------------------
  def handle_cast({:set_value, new_value}, state) do
    {:noreply, %{state | value: new_value}}
  end


  #============================================================================

  def filter_event( {:click, btn_id}, _from, %{id: id} = state ) do

    Scene.cast_to_refs( nil, {:set_to_msg, btn_id} )
    
    send_event({:value_changed, id, btn_id})
    {:stop, %{state | value: btn_id}}
  end

  def filter_event( msg, _from,  state ) do
    {:continue, msg, state}
  end

end










