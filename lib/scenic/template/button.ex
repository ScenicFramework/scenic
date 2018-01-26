defmodule Scenic.Template.Button do
  use Scenic.Template

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.RoundedRectangle
  alias Scenic.Primitive.Text
  alias Scenic.Template.Input
  alias Scenic.Template.Button
  alias Scenic.ViewPort.Input.Tracker

#  import IEx

  # default button width and height
  @default_width      70
  @default_height     24
  @default_radius     6

  @blue_color         :steel_blue
  @text_color         :white

  #----------------------------------------------------------------------------
  def build( data, opts \\ [])
  def build( {{x,y}, text}, opts ) when is_bitstring(text) do
    w = opts[:width]  || opts[:w] || @default_width
    h = opts[:height] || opts[:h] || @default_height
    r = opts[:radius] || opts[:r] || @default_radius

    # build the button graph
    Input.build( [{:font, {:roboto, 14}} | opts] )
    |> RoundedRectangle.add_to_graph( {{x,y}, w, h, r}, color: @blue_color )
    |> Text.add_to_graph( {{x+8,y+17}, text}, color: @text_color )
    |> Graph.request_input( :cursor_button )
    |> Graph.put_event_filter(0, {Button, :filter_input})
  end

  #----------------------------------------------------------------------------
  def filter_input(event, %Primitive{} = p, graph) do
    case event do
      {:cursor_button, :left, :press, _, _ } ->
        Tracker.Click.start( :left, p, Primitive.get(p) )
        {:stop, graph}

      {:cursor_button, :left, :release, _, _ } ->  {:stop, graph}
      event ->                                    {:continue, event, graph}
    end
  end

end

