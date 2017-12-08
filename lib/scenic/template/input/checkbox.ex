defmodule Scenic.Template.Input.Checkbox do
  use Scenic.Template

  alias Scenic.Scene
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Group
  alias Scenic.Primitive.Line
  alias Scenic.Primitive.Rectangle
  alias Scenic.Primitive.RoundedRectangle
  alias Scenic.Primitive.Text
  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Color
  alias Scenic.Primitive.Style.Hidden
  alias Scenic.Primitive.Style.LineWidth
  alias Scenic.Template.Input
  alias Scenic.Template.Input.Checkbox
  alias Scenic.ViewPort.Input.Tracker

  import IEx

  @default_radius     3

  @text_color         :white
  @box_color          :antique_white
  @check_color        :cornflower_blue

  @font               {:roboto, 16}

#  @hidden             Hidden.build( true )
#  @showing            Hidden.build( false )

  @hit_target_color   {:dark_green, 0}

  #----------------------------------------------------------------------------
  def build(data, opts \\ [] )

  def build({chx, text}, opts ) when is_boolean(chx) and is_bitstring(text) do
    r = opts[:r] || opts[:radius] || @default_radius

    # build the checkbox graph

    Input.build( Keyword.put(opts, :value, chx) )
    |> Group.add_to_graph(fn(graph) ->
      graph
      |> Rectangle.add_to_graph({{-2,-2}, 140, 16}, color: @hit_target_color)
      |> RoundedRectangle.add_to_graph({{-2,-2}, 16, 16, @default_radius}, color: @box_color)

      |> Group.add_to_graph(fn(graph) ->
        graph
        |> Line.add_to_graph({{2,2}, {10,10}}, color: @check_color, line_width: 2)
        |> Line.add_to_graph({{2,10}, {10,2}}, color: @check_color, line_width: 2)
      end, tags: [:checkmark], hidden: !chx)
    end, translate: {0, -11})
    

    |> Text.add_to_graph({{18,0}, text}, color: @text_color, font: @font )
    |> Graph.put_event_filter(0, {Checkbox, :filter_input})
  end

  #----------------------------------------------------------------------------
  def filter_input(event, id, checkbox, graph) do
    case event do

      {:mouse_button, :left, :press, _, _ } ->
        uids = Primitive.get(checkbox)
        Tracker.Click.start( :left, id, uids )
        {:stop, graph}

      {:click, target_id, pos} ->
        # find the checkmark for this checkbox
        checkbox_uid = Primitive.get_uid( checkbox )
        [checkmark] = Graph.find(graph, checkbox_uid, tag: :checkmark)
        checkmark_uid = Primitive.get_uid( checkmark )

        new_hidden = !Primitive.get_style(checkmark, :hidden)
        new_value = !new_hidden

        graph = Graph.modify(graph, checkmark_uid, fn(p) ->
          Primitive.put_style(p, :hidden, new_hidden)
        end)

        {:continue, {:value_changed, id, checkbox_uid, !new_hidden}, graph}

      event ->
        IO.inspect(event)
        {:continue, event, graph}
    end
  end

end