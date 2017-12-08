defmodule Scenic.Template.Input.RadioButton do
  use Scenic.Template.Input

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Rectangle
  alias Scenic.Primitive.RoundedRectangle
  alias Scenic.Primitive.Text
  alias Scenic.Template.Input
  alias Scenic.Template.Input.RadioButton
  alias Scenic.ViewPort.Input.Tracker

  import IEx

  @radius             3

  @text_color         :white
  @box_color          :antique_white
  @check_color        :cornflower_blue

  @font               {:roboto, 16}

  @hit_target_color   {:dark_green, 0}

  #----------------------------------------------------------------------------
  def build(data, opts \\ [] )

  def build({chx, text}, opts ) when is_boolean(chx) and is_bitstring(text) do
    # build the button graph
    Input.build( Keyword.put_new(opts, :value, chx) )
      |> Rectangle.add_to_graph({{-2,-2}, 140, 16}, color: @hit_target_color)
      |> RoundedRectangle.add_to_graph({{0,0}, 12, 12, @radius}, color: @box_color)
      |> RoundedRectangle.add_to_graph({{2,2}, 8, 8, @radius}, color: @check_color, hidden: !chx, tags: [:checkmark])
      |> Text.add_to_graph({{16,11}, text}, color: @text_color, font: @font)
      |> Graph.put_event_filter(0, {RadioButton, :filter_input})
  end

  #----------------------------------------------------------------------------
  def filter_input(event, %Primitive{} = radio_button, graph) do
    case event do
      {:mouse_button, :left, :press, _, _ } ->
        uids = Graph.gather_uids(graph, radio_button)
        Tracker.Click.start( :left, radio_button, uids )
        {:stop,  graph}

      event ->
        {:continue, event, graph}
    end
  end

end

























