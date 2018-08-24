defmodule Temp.Scene.Second do
  @moduledoc """
  Sample scene.
  """

  use Scenic.Scene
  alias Temp.Component.Nav
  alias Scenic.Graph
  import Scenic.Primitives

  @graph Graph.build()
    |> text("Second Scene", font: :roboto, font_size: 60, translate: {20, 120})
    |> Nav.add_to_graph(__MODULE__)

  def init( _, _ ) do
    push_graph(@graph)
    {:ok, @graph}
  end

end
