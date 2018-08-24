defmodule Temp.Scene.First do
  @moduledoc """
  Sample scene.
  """

  use Scenic.Scene
  alias Temp.Component.Nav
  alias Scenic.Graph
  import Scenic.Primitives

  import IEx

  @parrot         "/static/images/parrot.jpeg"
  @parrot_hash    "Qmsw7J3-WGB4eIn0oJmfORY4zqk"

  @graph Graph.build()
    |> text("First Scene", font: :roboto, font_size: 60, translate: {20, 120})
    # |> rect({100, 200}, fill: {:image, @parrot_hash}, translate: {20, 200} )
    # |> Nav.add_to_graph(__MODULE__)

  def init( _, _ ) do

    push_graph(@graph)
    send( self(), :post_init )

    {:ok, @graph}
  end


  def handle_info( :post_init, state ) do
    # load the parrot texture
    path = :code.priv_dir(:temp)
    |> Path.join( @parrot )
    Scenic.Cache.Texture.load(path, hash: @parrot_hash)
    |> IO.inspect()

    pry()

    {:noreply, state}
  end

end
