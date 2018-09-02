defmodule Scenic.Component.Input.RadioGroup do
  use Scenic.Component, has_children: true

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.Component.Input.RadioButton
  import Scenic.Primitives, only: [{:group, 2}]
  
#  import IEx

  @line_height      22

#  #--------------------------------------------------------
  def info( data ) do
    """
    #{IO.ANSI.red()}RadioGroup data must be a list of items
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    Each item in the list must be valid data for Scenic.Component.Input.RadioButton

    Example:
    [
      {"Radio A", :radio_a},
      {"Radio B", :radio_b, true},
      {"Radio C", :radio_c, false}
    ]

    #{IO.ANSI.default_color()}
    """
  end

  #--------------------------------------------------------
  def verify( items ) when is_list(items) do
    items
    |> Enum.all?( fn(item) ->
      case RadioButton.verify( item ) do
        {:ok, _} -> true
        _ -> false
      end
    end)
    |> case do
      true -> {:ok, items}
      _ -> :invalid_data
    end
  end
  def verify( _ ), do: :invalid_data

  #--------------------------------------------------------
  # def valid?( _items ), do: true

  #--------------------------------------------------------
  def init( items, opts ) when is_list(items) do
    id = opts[:id]
    styles = opts[:styles]

    graph = Graph.build()
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










