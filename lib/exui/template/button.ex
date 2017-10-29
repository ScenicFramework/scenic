defmodule Scenic.Template.Button do
  use Scenic.Template

  alias Scenic.Graph
  alias Scenic.Primitive
#  alias Scenic.Primitive.Group
  alias Scenic.Primitive.RoundedRectangle
  alias Scenic.Primitive.Text
#  alias Scenic.Primitive.Style.Color
  alias Scenic.Template.Input
  alias Scenic.Template.Button
  alias Scenic.Viewport.Input.Tracker

#  import IEx

  # default button width and height
  @default_width      70
  @default_height     24
  @default_radius     6

#  @blue_color         Color.build( {0x34, 0x7c, 0xbb} )
  @blue_color         :steel_blue
  @text_color         :white

  #----------------------------------------------------------------------------
  def build( text, opts \\ [])
  def build( text, opts ) when is_bitstring(text) do
    w = opts[:width]  || opts[:w] || @default_width
    h = opts[:height] || opts[:h] || @default_height
    r = opts[:radius] || opts[:r] || @default_radius

    # build the button graph
    Input.build( opts )
    |> Graph.add( RoundedRectangle, {{0,0}, w, h, r},color: @blue_color )
    |> Graph.add( Text, {{8,17}, text},color: @text_color )
    |> Graph.put_event_filter(0, {Button, :filter_input})
  end

  #----------------------------------------------------------------------------
  def filter_input(event, id, button, graph) do
    case event do

      {:mouse_down, _ } ->
        {:ok,_} = Tracker.Click.start_link(
          id, Primitive.get_uid( button ),
          Primitive.get( button )
        )
        {:stop, graph}

      event ->
        {:continue, event, graph}
    end
  end

end