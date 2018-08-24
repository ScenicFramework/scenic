defmodule Temp.Component.Nav do
  @moduledoc """
  Sample componentized nav bar.
  """

  use Scenic.Component
  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives, only: [{:text, 3}, {:scene_ref, 3}]
  import Scenic.Components, only: [{:dropdown, 3}]

  #--------------------------------------------------------
  def verify( scene ) when is_atom(scene), do: {:ok, scene}
  def verify( {scene,_} = data ) when is_atom(scene), do: {:ok, data}
  def verify( _ ), do: :invalid_data

  #--------------------------------------------------------
  def init( current_scene, opts ) do

    # get the viewport width to position the clock
    vp = opts[:viewport]
    {:ok, %ViewPort.Status{size: {width,_}}} = ViewPort.info(vp)

    graph = Graph.build(font_size: 20)
    |> text("Scene:", translate: {14, 40}, align: :right)
    |> dropdown({[
        {"First Scene", Temp.Scene.First},
        {"Second Scene", Temp.Scene.Second},
      ], current_scene, :nav}, translate: {70, 20})

    # the clock is statically supervised as an example on how to do that.
    # You could also use it dynamically
    |> scene_ref(:clock, translate: {width - 20, 10})

    |> push_graph()

    {:ok, %{graph: graph, viewport: opts[:viewport]}}
  end

  #--------------------------------------------------------
  def filter_event( {:value_changed, :nav, scene}, _, %{viewport: vp} = state )
  when is_atom(scene) do
     Scenic.ViewPort.set_root( vp, {scene, nil} )
    {:stop, state }
  end

  #--------------------------------------------------------
  def filter_event( {:value_changed, :nav, scene}, _, %{viewport: vp} = state ) do
     Scenic.ViewPort.set_root( vp, scene )
    {:stop, state }
  end

end
