#
#  Created by Boyd Multerer on 2021-08-16.
#  Copyright 2021 Kry10 Limited
#

defmodule Scenic.Graph.Bounds do
  @moduledoc false

  # mostly used by the @specs
  alias Scenic.Graph
  alias Scenic.Assets.Static
  alias Scenic.Math.Vector2
  alias Scenic.Math.Matrix

  alias Scenic.Primitive

  @tau :math.pi() * 2
  @tau_14 @tau / 4
  @tau_12 @tau / 2
  @tau_34 @tau * 3 / 4

  @n 32
  @n_14 trunc(@n / 4)
  @n_12 trunc(@n / 2)
  @n_34 trunc(@n * 3 / 4)

  # import IEx

  @spec compute(graph :: Graph.t()) :: Graph.bounds() | nil
  def compute(%Scenic.Graph{primitives: primitives}) do
    primitive(
      nil,
      primitives[0],
      primitives,
      Matrix.identity(),
      Scenic.Primitive.Style.default()
    )
  end

  defp primitive(bounds, primitive, primitives, mx, st)

  # skip hidden primitives
  defp primitive(out, %Primitive{styles: %{hidden: true}}, _, _, _), do: out

  defp primitive(
         out,
         %Primitive{module: Primitive.Group, data: ids} = p,
         ps,
         mx,
         st
       ) do
    styles = prep_styles(p, st)
    matrix = local_tx(p, mx)

    Enum.reduce(ids, out, &primitive(&2, ps[&1], ps, matrix, styles))
  end

  defp primitive(
         out,
         %Primitive{module: mod, data: data} = p,
         _ps,
         mx,
         st
       ) do
    styles = prep_styles(p, st)
    matrix = local_tx(p, mx)

    points(mod, data, styles)
    # we now have a list of lists of points. Some of the primitives
    # have multiple discrete regions, which are the inner lists
    # map these into bounds
    |> Enum.map(fn pts ->
      pts
      |> Vector2.project(matrix)
      |> Vector2.bounds()
    end)
    # we now have a list of bounds. Reduce that into the final bounds
    |> Enum.reduce(out, &set_bounds(&1, &2))
  end

  defp prep_styles(%Primitive{} = p, %{} = st) do
    styles =
      case Map.fetch(p, :styles) do
        {:ok, styles} -> Map.merge(st, styles)
        _ -> st
      end

    case Map.fetch(p, :opts) do
      {:ok, opts} -> Enum.into(opts, styles)
      _ -> styles
    end
  end

  # --------------------------------------------------------
  defp points(mod, data, st)

  defp points(Primitive.Arc, {radius, angle}, _st) do
    n = n_by_angle(angle)

    [
      Enum.reduce(0..n, [], fn i, pts ->
        [{radius * :math.cos(angle * i / n), radius * :math.sin(angle * i / n)} | pts]
      end)
    ]
  end

  defp points(Primitive.Circle, radius, _st) do
    [
      Enum.reduce(0..@n, [], fn i, pts ->
        [{radius * :math.cos(@tau * i / @n), radius * :math.sin(@tau * i / @n)} | pts]
      end)
    ]
  end

  defp points(Primitive.Ellipse, {r0, r1}, _st) do
    [
      Enum.reduce(0..@n, [], fn i, pts ->
        [{r0 * :math.cos(@tau * i / @n), r1 * :math.sin(@tau * i / @n)} | pts]
      end)
    ]
  end

  defp points(Primitive.Line, {{x0, y0}, {x1, y1}}, _st) do
    [[{x0, y0}, {x1, y1}]]
  end

  defp points(Primitive.Quad, {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}, _st) do
    [[{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}, {x0, y0}]]
  end

  defp points(Primitive.Rectangle, {width, height}, _st) do
    [[{0, 0}, {width, 0}, {width, height}, {0, height}, {0, 0}]]
  end

  defp points(Primitive.RoundedRectangle, {width, height, radius}, st) do
    # the easiest way to do this one is to fake it up as a path
    cmds = [
      {:move_to, radius, 0},
      {:arc_to, width, 0, width, radius, radius},
      {:arc_to, width, height, width - radius, height, radius},
      {:arc_to, 0, height, 0, height - radius, radius},
      {:arc_to, 0, 0, radius, 0, radius}
    ]

    points(Primitive.Path, cmds, st)
  end

  defp points(Primitive.Sector, {radius, angle}, _st) do
    n = n_by_angle(angle)

    pts =
      Enum.reduce(0..n, [{0, 0}], fn i, pts ->
        [{radius * :math.cos(angle * i / n), radius * :math.sin(angle * i / n)} | pts]
      end)

    [[{0, 0} | pts]]
  end

  defp points(Primitive.Text, text, st) do
    # break the text into lines
    lines = String.split(text, "\n")
    line_count = Enum.count(lines)

    # text depends on the current styles
    {:ok, {Static.Font, fm}} = Static.meta(st[:font])
    {:ok, font_size} = Map.fetch(st, :font_size)
    {:ok, h_align} = Map.fetch(st, :text_align)
    {:ok, v_align} = Map.fetch(st, :text_base)
    {:ok, line_height} = Map.fetch(st, :line_height)

    ascent = FontMetrics.ascent(font_size, fm)
    descent = FontMetrics.descent(font_size, fm)

    # width is of the longest line
    width =
      Enum.reduce(lines, 0, fn line, acc ->
        w = FontMetrics.width(line, font_size, fm)
        if w > acc, do: w, else: acc
      end)

    natural_height = ascent - descent
    height = natural_height * line_height * (line_count - 1) + natural_height

    # determine the horizontal alignment adjustment
    h_adjust =
      case h_align do
        :left -> 0
        :center -> -1 * (width / 2)
        :right -> -1 * width
      end

    # determine the vertical alignment adjustment
    v_adjust =
      case v_align do
        :top -> 0
        :middle -> -1 * (height / 2)
        :alphabetic -> -ascent
        :bottom -> -1 * height
      end

    # The neutral bounding box is determined by the font and alignment adjustments
    [
      [
        {h_adjust, v_adjust},
        {width + h_adjust, v_adjust},
        {width + h_adjust, height + v_adjust},
        {h_adjust, height + v_adjust},
        {h_adjust, v_adjust}
      ]
    ]
  end

  defp points(Primitive.Triangle, {{x0, y0}, {x1, y1}, {x2, y2}}, _st) do
    [[{x0, y0}, {x1, y1}, {x2, y2}, {x0, y0}]]
  end

  defp points(Primitive.Component, {module, data, _}, st) do
    case Kernel.function_exported?(module, :bounds, 2) do
      true ->
        {l, t, r, b} = module.bounds(data, st)
        [[{l, t}, {r, t}, {r, b}, {l, b}, {l, t}]]

      false ->
        [[]]
    end
  end

  defp points(Primitive.Sprites, {_id, cmds}, _st) do
    Enum.reduce(cmds, [], fn {_, _, {x, y}, {w, h}, _alpha}, acc ->
      [[{x, y}, {x + w, y}, {x + w, y + h}, {x, y + h}, {x, y}] | acc]
    end)
  end

  defp points(Primitive.Path, cmds, _st) do
    {lpts, _lp} =
      Enum.reduce(cmds, {[[]], nil}, fn
        :begin, acc ->
          acc

        :begin_path, acc ->
          acc

        :close_path, {pts, xy} ->
          {[xy | pts], xy}

        {:move_to, x, y}, {pts, _xy} ->
          {[[{x, y}] | pts], {x, y}}

        {:line_to, x, y}, {[h | t], xy} ->
          {[[{x, y} | h] | t], xy}

        {:arc_to, cx, cy, x, y, r}, {[h | t], xy} ->
          {[pts_arc_to(h, cx, cy, x, y, r) | t], xy}

        {:bezier_to, c1x, c1y, c2x, c2y, x, y}, {[h | t], xy} ->
          {[pts_bezier_to(h, c1x, c1y, c2x, c2y, x, y) | t], xy}

        {:quadratic_to, cx, cy, x, y}, {[h | t], xy} ->
          {[pts_quadratic_to(h, cx, cy, x, y) | t], xy}

        _, acc ->
          acc
      end)

    # pry()
    # the lists are in reverse order.
    Enum.map(lpts, &Enum.reverse(&1))
  end

  # ignore everything else
  defp points(_mod, _data, _st), do: [[]]

  # --------------------------------------------------------
  # curve helpers
  defp angle(va, vb) do
    Vector2.dot(Vector2.normalize(va), Vector2.normalize(vb))
    |> :math.acos()
  end

  defp pts_arc_to([{x0, y0} | _] = pts, x1, y1, x2, y2, r) do
    # recreate as two vectors point out of the 1 point
    v_ax = x0 - x1
    v_ay = y0 - y1
    v_bx = x2 - x1
    v_by = y2 - y1
    v_a = {v_ax, v_ay}
    v_b = {v_bx, v_by}

    # use the dot product to find the angle between them
    # angle = Vector2.dot( v_a, v_b )
    # |> :math.acos()
    angle = angle(v_a, v_b)
    ha = angle / 2

    # calculate the hypotenuse
    hypotenuse = r / :math.sin(ha)

    # how far from point1 are the tangent points
    dist_tan_sqr = hypotenuse * hypotenuse - r * r
    dist_tan = :math.sqrt(dist_tan_sqr)

    # Find the arc starting point
    ratio = dist_tan / Vector2.distance({x0, y0}, {x1, y1})
    {vx, vy} = v_a2 = Vector2.mul(v_a, ratio)
    {sx, sy} = pt_start = {x1 + vx, y1 + vy}

    # Find the arc ending point
    ratio = dist_tan / Vector2.distance({x2, y2}, {x1, y1})
    {vx, vy} = v_b2 = Vector2.mul(v_b, ratio)
    {ex, ey} = pt_end = {x1 + vx, y1 + vy}

    # the center point should be on the vector defined by adding v_a2 + v_b2
    v_c = Vector2.add(v_a2, v_b2)
    ratio = hypotenuse / Vector2.length(v_c)
    {vx, vy} = Vector2.mul(v_c, ratio)
    {cx, cy} = {x1 + vx, y1 + vy}

    # now if re-orient ourselves around the center point, we can create
    # two vectors to the start and end points. The angle between these
    # two vectors is the angle of the arc
    v_c_start = {sx - cx, sy - cy}
    v_c_end = {ex - cx, ey - cy}

    # The sign of the angle depends on the winding
    # the sign of the cross product indicates the winding direction
    angle =
      Vector2.cross(
        Vector2.sub({x0, y0}, {x1, y1}),
        Vector2.sub({x1, y1}, {x2, y2})
      )
      |> Kernel.>=(0)
      |> case do
        true -> angle(v_c_start, v_c_end)
        false -> -1 * angle(v_c_start, v_c_end)
      end

    # special case vertical lines so we don't divide by zero
    sa =
      case Vector2.normalize(v_c_start) do
        {+0.0, 1.0} ->
          @tau_14

        {+0.0, -1.0} ->
          -1 * @tau_14

        {x, y} ->
          cond do
            y < 0 -> @tau - angle({x, y}, Vector2.right())
            true -> angle({x, y}, Vector2.right())
          end
      end

    # build the points list
    n = n_by_angle(angle)

    Enum.reduce(0..n, [pt_end, pt_start | pts], fn i, pts ->
      [
        {
          r * :math.cos(sa + angle * i / n) + cx,
          r * :math.sin(sa + angle * i / n) + cy
        }
        | pts
      ]
    end)
  end

  defp pts_bezier_to([{x0, y0} | _] = pts, x1, y1, x2, y2, x3, y3) do
    n = 32

    Enum.reduce(0..n, pts, fn nn, pts ->
      t = nn / n
      t2 = t * t
      t3 = t * t * t
      tm1 = 1 - t
      tm12 = tm1 * tm1
      tm13 = tm1 * tm1 * tm1

      [
        {
          tm13 * x0 + 3 * tm12 * t * x1 + 3 * tm1 * t2 * x2 + t3 * x3,
          tm13 * y0 + 3 * tm12 * t * y1 + 3 * tm1 * t2 * y2 + t3 * y3
        }
        | pts
      ]
    end)
  end

  defp pts_quadratic_to([{x0, y0} | _] = pts, x1, y1, x2, y2) do
    n = 32

    Enum.reduce(0..n, pts, fn nn, pts ->
      t = nn / n
      t2 = t * t
      tm1 = 1 - t
      tm12 = tm1 * tm1

      [
        {
          tm12 * x0 + 2 * tm1 * t * x1 + t2 * x2,
          tm12 * y0 + 2 * tm1 * t * y1 + t2 * y2
        }
        | pts
      ]
    end)
  end

  # --------------------------------------------------------
  defp local_tx(%Primitive{transforms: txs}, tx_parent) when txs == %{}, do: tx_parent

  defp local_tx(%Primitive{default_pin: default_pin, transforms: txs}, tx_parent) do
    txs =
      case txs[:pin] do
        nil -> Map.put(txs, :pin, default_pin)
        _ -> txs
      end

    # multiply the local txs into the tx_parent
    Matrix.mul(tx_parent, Primitive.Transform.combine(txs))
  end

  # --------------------------------------------------------
  defp set_bounds(ltrb, nil), do: ltrb
  defp set_bounds(nil, ltrb), do: ltrb

  defp set_bounds({l, t, r, b}, {ll, tt, rr, bb}) do
    l = if l < ll, do: l, else: ll
    t = if t < tt, do: t, else: tt
    r = if r > rr, do: r, else: rr
    b = if b > bb, do: b, else: bb
    {l, t, r, b}
  end

  defp n_by_angle(a) when a < @tau_14, do: @n_14
  defp n_by_angle(a) when a < @tau_12, do: @n_12
  defp n_by_angle(a) when a < @tau_34, do: @n_34
  defp n_by_angle(_), do: @n
end
