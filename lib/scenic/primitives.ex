#
#  Created by Boyd Multerer April 30, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# convenience functions for adding basic primitives to a graph.
# this module should be updated as new primitves area dded

defmodule Scenic.Primitives do
  alias Scenic.Primitive
  # alias Scenic.Primitive.Style
  # alias Scenic.Primitive.Transform

  @tau    2.0 * :math.pi();

  #--------------------------------------------------------
  def group( graph, builder, opts \\ [] )
  def group( graph, builder, opts ) when is_function(builder, 1) do
    Primitive.Group.add_to_graph(graph, builder, opts)
  end

  #--------------------------------------------------------
  def line( graph, data, opts \\ [] )
  def line( graph, {{x0,y0}, {x1,y1}}, opts ) when
  is_number(x0) and is_number(y0) and
  is_number(x1) and is_number(y1) do
    Primitive.Line.add_to_graph(
      graph,
      {{x0,y0}, {x1,y1}},
      opts
    )
  end

  #--------------------------------------------------------
  def triangle( graph, data, opts \\ [] )
  def triangle( graph, {{x0,y0}, {x1,y1}, {x2,y2}}, opts ) when
  is_number(x0) and is_number(y0) and
  is_number(x1) and is_number(y1) and
  is_number(x2) and is_number(y2) do
    Primitive.Triangle.add_to_graph(
      graph,
      {{x0,y0}, {x1,y1}, {x2,y2}},
      opts
    )
  end

  #--------------------------------------------------------
  def text( graph, data, opts \\ [] )
  def text( graph, {{x,y}, text}, opts ) when is_bitstring(text) and
  is_number(x) and is_number(y) do
    Primitive.Text.add_to_graph( graph, {{x,y}, text}, opts )
  end
  def text( graph, text, opts ), do: text( graph, {{0,0}, text}, opts )

  #--------------------------------------------------------
  def rect( graph, data, opts \\ [] ), do: rectangle( graph, data, opts )
  def rectangle( graph, data, opts \\ [] )
  def rectangle( graph, {width, height}, opts ) do
    rectangle( graph, {{0,0}, width, height}, opts )
  end
  def rectangle( graph, {{x,y}, width, height}, opts ) when
  is_number(width) and is_number(height) and
  is_number(x) and is_number(y) do
    Primitive.Rectangle.add_to_graph( graph, {{x,y}, width, height}, opts )
  end

  #--------------------------------------------------------
  def rrect( graph, data, opts \\ [] ), do: rounded_rectangle( graph, data, opts )
  def rounded_rectangle( graph, data, opts \\ [] )
  def rounded_rectangle( graph, {width, height, radius}, opts ) do
    rounded_rectangle( graph, {{0,0}, width, height, radius}, opts )
  end
  def rounded_rectangle( graph, {{x,y},width, height, radius}, opts )
  when is_number(width) and is_number(height) and
  is_number(radius) and radius > 0 and
  is_number(x) and is_number(y) do
    Primitive.RoundedRectangle.add_to_graph( graph, {{x,y}, width, height, radius}, opts )
  end

  #--------------------------------------------------------
  def quad( graph, data, opts \\ [] )
  def quad( graph, {{x0,y0}, {x1,y1}, {x2,y2}, {x3,y3}}, opts ) when
  is_number(x0) and is_number(y0) and
  is_number(x1) and is_number(y1) and
  is_number(x2) and is_number(y2) and
  is_number(x3) and is_number(y3) do
    Primitive.Quad.add_to_graph(
      graph,
      {{x0,y0}, {x1,y1}, {x2,y2}, {x3,y3}},
      opts
    )
  end

  #--------------------------------------------------------
  def sector( graph, data, opts \\ [] )
  def sector( graph, {start, finish, radius}, opts ), do:
    sector( graph, {{0,0}, start, finish, radius, {1.0,1.0}}, opts )
  def sector( graph, {{x,y}, start, finish, radius}, opts ), do:
    sector( graph, {{x,y}, start, finish, radius, {1.0,1.0}}, opts )
  def sector( graph, {{x,y}, start, finish, radius, {h,k}}, opts ) when
  is_number(x) and is_number(y) and
  is_number(start) and is_number(finish) and is_number(radius) and
  is_number(h) and is_number(k) do
    Primitive.Sector.add_to_graph(
      graph,
      {{x,y}, start, finish, radius, {h,k}},
      opts
    )
  end

  #--------------------------------------------------------
  def oval( graph, data, opts \\ [] )
  def oval( graph, radius, opts ) when is_number(radius), do: circle( graph, radius, opts )
  def oval( graph, {{_,_}, _} = data, opts ), do: circle( graph, data, opts )
  def oval( graph, {radius, {h,k}}, opts ) do
    sector( graph, {{0,0}, 0, @tau, radius, {h,k}}, opts )
  end
  def oval( graph, {{x,y}, radius, {h,k}}, opts ) do
    sector( graph, {{x,y}, 0, @tau, radius, {h,k}}, opts )
  end

  #--------------------------------------------------------
  def circle( graph, data, opts \\ [] )
  def circle( graph, radius, opts ) when is_number(radius) do
    sector( graph, {{0,0}, 0, @tau, radius, {1.0, 1.0}}, opts )
  end
  def circle( graph, {{x,y},radius}, opts ) when
  is_number(radius) and is_number(x) and is_number(y) do
    sector( graph, {{x,y}, 0, @tau, radius, {1.0, 1.0}}, opts )
  end




  #--------------------------------------------------------
  def texture( graph, data, opts \\ [] )

  def texture( graph, {width, height, key}, opts ) when
  is_number(width) and is_number(height) do
    texture( graph, {
    {{0, 0}, {width, 0}, {width, height}, {0, height}},
    {{0.0, 0.0}, {1.0, 0.0}, {1.0, 1.0}, {0.0, 1.0}},
    key
  }, opts )
  end

  def texture( graph, {{x,y}, width, height, key}, opts ) do
    texture( graph, {
    {{x, y}, {x + width, y}, {x + width, y + height}, {x, y + height}},
    {{0.0, 0.0}, {1.0, 0.0}, {1.0, 1.0}, {0.0, 1.0}},
    key
  }, opts )
  end

  def texture( graph, {{{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}, key}, opts ) do
    texture( graph, {
    {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}},
    {{0.0, 0.0}, {1.0, 0.0}, {1.0, 1.0}, {0.0, 1.0}},
    key
  }, opts )
  end

  def texture( graph, {
    {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}},
    {{s0, t0}, {s1, t1}, {s2, t2}, {s3, t3}},
    key
  } = data, opts ) when is_bitstring(key) and
  is_number(x0) and is_number(y0) and
  is_number(x1) and is_number(y1) and
  is_number(x2) and is_number(y2) and
  is_number(x3) and is_number(y3) and
  is_number(s0) and is_number(t0) and
  is_number(s1) and is_number(t1) and
  is_number(s2) and is_number(t2) and
  is_number(s3) and is_number(t3) do
    Primitive.Texture.add_to_graph( graph, data, opts )
  end


  #--------------------------------------------------------
  def scene_ref( graph, data, opts \\ [] )

  def scene_ref( graph, {:graph,_,_} = key, opts ) do
    Primitive.SceneRef.add_to_graph( graph, key, opts )
  end

  def scene_ref( graph, name_pid, opts ) when
  is_atom(name_pid) or is_pid(name_pid) do
    Primitive.SceneRef.add_to_graph( graph, {name_pid, nil}, opts )
  end

  def scene_ref( graph, {name,_} = data, opts ) when is_atom(name) do
    Primitive.SceneRef.add_to_graph( graph, data, opts )
  end

  def scene_ref( graph, {pid,_} = data, opts ) when is_pid(pid) do
    Primitive.SceneRef.add_to_graph( graph, data, opts )
  end

  def scene_ref( graph, {{module,_},_} = data, opts ) when is_atom(module) do
    Primitive.SceneRef.add_to_graph( graph, data, opts )
  end

end






