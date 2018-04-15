defmodule Scenic.Component.Input.RadioGroup do
  use Scenic.Component, has_children: true

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.ViewPort
  alias Scenic.Component.Input.RadioButton

  import IEx

  @line_height      22

#  #--------------------------------------------------------
  def info() do
#    "#{IO.ANSI.red()}RadioGroup must be initialized with" <>
#    "{text, message, value, opts}#{IO.ANSI.default_color()}\r\n"
    "help goes here"
  end

  #--------------------------------------------------------
  def valid?( items ), do: true

  #--------------------------------------------------------
  def init( {items, id} ) when is_list(items) do
    graph = Graph.build(font: {:roboto, 16})
    |> Primitive.Group.add_to_graph(fn(graph) ->
      {graph, _} = Enum.reduce(items, {graph, 0}, fn
        {t,m}, {g, voffset} ->
          g = RadioButton.add_to_graph(g, {t, m, false}, translate: {0,voffset} )
          {g, voffset + @line_height}

        {t,m,v}, {g, voffset} ->
          g = RadioButton.add_to_graph(g, {t, m, v}, translate: {0,voffset} )
          {g, voffset + @line_height}
      end)
      graph
    end)

    value = Enum.find_value(items, fn
      {t,m} -> nil
      {t,m, false} -> nil
      {t,m, true} -> m
    end)

    state = %{
      graph: graph,
      value: value,
      id: id
    }

#IO.puts "RadioGroup.init"
    push_graph( graph )

    {:ok, state}
  end

  #--------------------------------------------------------
  def handle_cast({:set_value, new_value}, %{checked: value} = state) do
    {:noreply, %{state | value: new_value}}
  end


  #============================================================================

  def filter_event( {:click, msg}, _from, %{id: id} = state ) do
    Scene.broadcast_children({:set_to_msg, msg})
    send_event({:value_changed, id, msg})
    {:stop, %{state | value: msg}}
  end

  def filter_event( msg, from,  state ) do
    {:continue, msg, state}
  end

# {:set_to_msg, set_msg}

end










