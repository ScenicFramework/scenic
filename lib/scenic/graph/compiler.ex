#
#  Created by Boyd Multerer on 2021-02-07
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#
# Compile a graph into scripts for the given ViewPort
# Considered to be part of the ViewPort module

defmodule Scenic.Graph.Compiler do
  @moduledoc false

  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Graph
  alias Scenic.Color
  alias Scenic.Primitive.Style.Theme
  alias Scenic.Graph.Compiler

  # import IEx

  defstruct set: %{}, set_stack: [], reqs: nil, req_stack: []

  # ========================================================
  # internal helpers for working with the compiler state
  defp fetch_req(%Compiler{reqs: reqs}, k), do: Map.fetch(reqs, k)

  defp merge_reqs(%Compiler{reqs: reqs} = state, styles) do
    %{state | reqs: Map.merge(reqs, styles)}
  end

  defp push_reqs(%Compiler{reqs: reqs, req_stack: stack} = state) do
    %{state | req_stack: [reqs | stack]}
  end

  defp pop_reqs(%Compiler{req_stack: [head | tail]} = state) do
    %{state | reqs: head, req_stack: tail}
  end

  defp fetch_set(%Compiler{set: set}, k), do: Map.fetch(set, k)

  defp put_set(%Compiler{set: set} = state, k, v) do
    %{state | set: Map.put(set, k, v)}
  end

  defp push_set(%Compiler{set: set, set_stack: stack} = state) do
    %{state | set_stack: [set | stack]}
  end

  defp pop_set(%Compiler{set_stack: [head | tail]} = state) do
    %{state | set: head, set_stack: tail}
  end

  # ========================================================

  # compile a graph into a list of scripts -> [{id,script}|...]
  @spec compile(graph :: Graph.t()) :: {:ok, Script.t()}
  def compile(graph)

  def compile(%Graph{primitives: primitives}) do
    {ops, _} =
      compile_primitive(
        Script.start(),
        primitives[0],
        primitives,
        %Compiler{reqs: Scenic.Primitive.Style.default()}
      )

    {:ok, Script.finish(ops)}
  end

  defp compile_primitive(ops, primitive, primitives, state)

  # don't render the primitive at all if it is hidden
  defp compile_primitive(ops, %{styles: %{hidden: true}}, _, state) do
    {ops, state}
  end

  defp compile_primitive(ops, primitive, primitives, %Compiler{} = state) do
    # prepare the reqs
    state = push_reqs(state)

    # decompose any :stroke styles into :stroke_width and :stroke_fill
    styles =
      case Map.get(primitive, :styles) do
        %{stroke: {width, fill}} = styles ->
          styles
          |> Map.put(:stroke_width, width)
          |> Map.put(:stroke_fill, fill)
          |> Map.delete(:stroke)

        styles ->
          styles
      end

    # merge the primitive's styles into reqs
    state = merge_reqs(state, styles)

    # Further checks to see if we should render the primitive.
    # Check if it needs fill/stroke and those aren't set
    {ops, state} =
      case compile_prim?(primitive, state.reqs) do
        true -> do_compile_primitive(ops, primitive, primitives, state)
        false -> {ops, state}
      end

    # restore the reqs and return
    {ops, pop_reqs(state)}
  end

  defp do_compile_primitive(ops, primitive, primitives, %Compiler{} = state) do
    # get the requested styles and transforms
    tx = Map.get(primitive, :transforms)

    # compile tx as if alone
    tx_ops = compile_transforms([], tx, primitive)

    {prim_ops, style_ops, state} =
      case tx_ops do
        [] ->
          do_primitive(primitive, primitives, state)

        _ ->
          # there are transforms, we will be pushing and popping state
          state = push_set(state)
          {prim_ops, style_ops, state} = do_primitive(primitive, primitives, state)
          state = pop_set(state)
          {prim_ops, style_ops, state}
      end

    # several optimizations based on if tx or which styles were set
    cond do
      tx_ops == [] && style_ops == [] ->
        # no styles or transforms changed
        {[prim_ops | ops], state}

      tx_ops == [] ->
        # styles have changed
        {[prim_ops, style_ops | ops], state}

      true ->
        # transforms changed. do a push/pop
        # NOTE: Must apply the transforms BEFORE the styles because the current
        # transforms affect some of the styles. Namely the gradients.
        ops =
          ops
          |> Script.push_state()
          |> List.insert_at(0, tx_ops)
          |> List.insert_at(0, style_ops)
          |> List.insert_at(0, prim_ops)
          |> Script.pop_state()

        {ops, state}
    end
  end

  # returns {ops, state}
  defp compile_styles(desired, %Compiler{} = state) when is_list(desired) do
    Enum.reduce(desired, {[], state}, fn k, {ops, state} ->
      # if not requested, there is no style to compile...
      with {:ok, req} <- fetch_req(state, k) do
        case fetch_set(state, k) do
          {:ok, ^req} ->
            # Nothing to do. The correct style is already set
            {ops, state}

          _ ->
            # Whatever is set (or not) is different than what is requested
            {compile_style(ops, {k, req}), put_set(state, k, req)}
        end
      else
        # not requested at all case
        _ -> {ops, state}
      end
    end)
  end

  defp compile_prim?(%Primitive{styles: %{reqs: %{hidden: true}}}, _), do: false
  defp compile_prim?(%Primitive{module: Primitive.Arc}, styles), do: !!Script.draw_flag(styles)
  defp compile_prim?(%Primitive{module: Primitive.Circle}, styles), do: !!Script.draw_flag(styles)

  defp compile_prim?(%Primitive{module: Primitive.Ellipse}, styles),
    do: !!Script.draw_flag(styles)

  defp compile_prim?(%Primitive{module: Primitive.Line}, styles),
    do: Script.draw_flag(styles) == :stroke

  defp compile_prim?(%Primitive{module: Primitive.Rectangle}, styles),
    do: !!Script.draw_flag(styles)

  defp compile_prim?(%Primitive{module: Primitive.Quad}, styles), do: !!Script.draw_flag(styles)

  defp compile_prim?(%Primitive{module: Primitive.RoundedRectangle}, styles),
    do: !!Script.draw_flag(styles)

  defp compile_prim?(%Primitive{module: Primitive.Sector}, styles), do: !!Script.draw_flag(styles)
  defp compile_prim?(_, _), do: true

  # first the special-case primitives. This is usually because they depend on knowledge
  # of the compilate state beyond just the currently requested styles.

  # The group is the root and also the only primitive doesn't set its own styles
  defp do_primitive(%Primitive{module: Primitive.Group, data: ids}, primitives, state) do
    {st_ops, state} = compile_styles([:scissor, :fill, :stroke], state)

    {ops, state} =
      Enum.reduce(ids, {[], state}, fn id, {ops, state} ->
        compile_primitive(ops, primitives[id], primitives, state)
      end)

    {ops, st_ops, state}
  end

  defp do_primitive(%Primitive{module: Primitive.Script, data: name}, _, state) do
    {st_ops, state} = compile_styles(Primitive.Script.valid_styles(), state)
    {do_compile_script_name([], name), st_ops, state}
  end

  defp do_primitive(
         %Primitive{module: Primitive.Component, data: {_, _, name}},
         _,
         state
       ) do
    {st_ops, state} = compile_styles(Primitive.Component.valid_styles(), state)
    {do_compile_script_name([], name), st_ops, state}
  end

  defp do_primitive(%Primitive{module: Primitive.Text, data: text}, _, state) do
    {st_ops, state} =
      compile_styles(
        Primitive.Text.valid_styles(),
        state
      )

    # if no fill is set, then check if there is a theme. If no theme...
    # then do what games do. Draw in fuchsia to make it obvious
    # also, fill must be a solid color for text...
    {st_ops, state} = do_text_color(st_ops, state)

    # caclulate the spacing between lines
    %{set: %{font_size: font_size, line_height: line_height}} = state
    spacing = font_size * line_height

    {Script.draw_text([], text, spacing), st_ops, state}
  end

  # the generic primitive compiler
  # this is what allows new "meta" primitives
  defp do_primitive(%Primitive{module: mod} = p, _, state) do
    {st_ops, state} = compile_styles(mod.valid_styles(), state)
    {mod.compile(p, state.reqs), st_ops, state}
  end

  defp do_compile_script_name(ops, name) do
    Script.render_script(ops, name)
  end

  defp do_text_color(
         ops,
         %{reqs: %{fill: {:color, req_color}}, set: %{fill: {:color, set_color}}} = state
       )
       when req_color == set_color do
    {ops, state}
  end

  # use the requested fill color (doesn't accept non-colors)
  defp do_text_color(ops, %{reqs: %{fill: {:color, _}}} = state) do
    {fill_ops, state} = compile_styles([:fill], state)
    {[fill_ops | ops], state}
  end

  # No requested color, but there is a theme. set it's color if it isn't already set
  defp do_text_color(ops, %{reqs: %{theme: theme}} = state) do
    color =
      theme
      |> Theme.normalize()
      |> Map.get(:text)
      |> Color.to_rgba()

    case fetch_set(state, :fill) do
      # color is already set
      {:ok, {:color, ^color}} ->
        {ops, state}

      _ ->
        {
          Script.fill_color(ops, color),
          put_set(state, :fill, {:color, color})
        }
    end
  end

  # fail case. make it obvious
  defp do_text_color(ops, state) do
    fuchsia = Color.to_rgba(:fuchsia)

    {
      Script.fill_color(ops, fuchsia),
      put_set(state, :fill, {:color, fuchsia})
    }
  end

  # ============================================================================
  # styles

  # can ignore :hidden
  defp compile_style(ops, {:hidden, _}), do: ops

  defp compile_style(ops, {:fill, c}) when is_atom(c), do: Script.fill_color(ops, c)
  defp compile_style(ops, {:fill, {:color, c}}), do: Script.fill_color(ops, c)

  defp compile_style(ops, {:fill, {:linear, {sx, sy, ex, ey, sc, ec}}}) do
    Script.fill_linear(ops, sx, sy, ex, ey, sc, ec)
  end

  defp compile_style(ops, {:fill, {:radial, {cx, cy, rs, re, sc, ec}}}) do
    Script.fill_radial(ops, cx, cy, rs, re, sc, ec)
  end

  defp compile_style(ops, {:fill, {:image, id}}) do
    Script.fill_image(ops, id)
  end

  defp compile_style(ops, {:fill, {:stream, id}}) do
    Script.fill_stream(ops, id)
  end

  defp compile_style(ops, {:stroke_width, width}), do: Script.stroke_width(ops, width)

  defp compile_style(ops, {:stroke_fill, color}) when is_atom(color),
    do: compile_style(ops, {:stroke_fill, {:color, color}})

  defp compile_style(ops, {:stroke_fill, {:color, color}}) do
    Script.stroke_color(ops, color)
  end

  defp compile_style(ops, {:stroke_fill, {:linear, {sx, sy, ex, ey, sc, ec}}}) do
    Script.stroke_linear(ops, sx, sy, ex, ey, sc, ec)
  end

  defp compile_style(ops, {:stroke_fill, {:radial, {cx, cy, rs, re, sc, ec}}}) do
    Script.stroke_radial(ops, cx, cy, rs, re, sc, ec)
  end

  defp compile_style(ops, {:stroke_fill, {:image, id}}) do
    Script.stroke_image(ops, id)
  end

  defp compile_style(ops, {:stroke_fill, {:stream, id}}) do
    Script.stroke_stream(ops, id)
  end

  defp compile_style(ops, {:scissor, {w, h}}), do: Script.scissor(ops, w, h)

  defp compile_style(ops, {:cap, type}), do: Script.cap(ops, type)
  defp compile_style(ops, {:join, type}), do: Script.join(ops, type)
  defp compile_style(ops, {:miter_limit, limit}), do: Script.miter_limit(ops, limit)

  defp compile_style(ops, {:font, name}), do: Script.font(ops, name)
  defp compile_style(ops, {:font_size, size}), do: Script.font_size(ops, size)
  defp compile_style(ops, {:text_align, alignment}), do: Script.text_align(ops, alignment)
  defp compile_style(ops, {:text_base, alignment}), do: Script.text_base(ops, alignment)
  # defp compile_style( ops, {:text_height, px} ), do: Script.text_height( ops, px )

  # skip the "meta" styles. These do not have direct analogs in the script language
  defp compile_style(ops, {:line_height, _}), do: ops
  defp compile_style(ops, {:theme, _}), do: ops

  # Raise if this is a completely unknown style
  defp compile_style(_ops, style) do
    raise "Unknown Style: #{inspect(style)}"
  end

  # ============================================================================
  # transforms

  # defp compile_transforms( ops, nil, _ ), do: ops
  # defp compile_transforms( ops, empty, _ ) when empty == %{}, do: ops

  defp compile_transforms(ops, %{rotate: _} = txs, p), do: complex_tx(ops, txs, p)
  defp compile_transforms(ops, %{scale: _} = txs, p), do: complex_tx(ops, txs, p)
  defp compile_transforms(ops, %{matrix: _} = txs, p), do: complex_tx(ops, txs, p)

  defp compile_transforms(ops, %{translate: {x, y}}, _) do
    # The only transform is a translate.
    # Can do the small, direct version
    Script.translate(ops, x, y)
  end

  # do nothing if no transforms are provided
  defp compile_transforms(ops, %{}, _), do: ops

  defp complex_tx(ops, txs, %Primitive{default_pin: default_pin}) do
    # get the pin for this operation
    pin =
      case txs[:pin] do
        nil -> default_pin
        pin -> pin
      end

    # data size optimization...
    # If the pin is {0,0}, then we are rotating around the origin.
    # If it is smaller to send simple commands than a combined matrix, do that.
    # or send if combined matrix if that is smaller
    # note that just transform was taken care of during compile_transforms
    # case pin do
    #   {0, 0} -> zero_pin(ops, txs)
    #   {0.0, 0.0} -> zero_pin(ops, txs)
    #   _ -> combined_tx(ops, pin, txs)
    # end
    combined_tx(ops, pin, txs)
  end

  # defp zero_pin(ops, txs) do
  #   case txs do
  #     %{matrix: _} ->
  #       # doing a matrix anyway...
  #       combined_tx(ops, {0.0, 0.0}, txs)

  #     %{rotate: _, scale: _, translate: _} ->
  #       # combined matrix is smaller
  #       combined_tx(ops, {0.0, 0.0}, txs)

  #     %{rotate: r, scale: {x, y}} ->
  #       ops
  #       |> Script.rotate(r)
  #       |> Script.scale(x, y)

  #     %{rotate: r, translate: {x, y}} ->
  #       ops
  #       |> Script.rotate(r)
  #       |> Script.translate(x, y)

  #     %{scale: {sx, sy}, translate: {tx, ty}} ->
  #       ops
  #       |> Script.scale(sx, sy)
  #       |> Script.translate(tx, ty)

  #     %{rotate: r} ->
  #       Script.rotate(ops, r)

  #     %{scale: {x, y}} ->
  #       Script.scale(ops, x, y)
  #       # transform is already taken care of above...
  #   end
  # end

  defp combined_tx(ops, pin, txs) do
    mx =
      txs
      |> Map.put(:pin, pin)
      |> Scenic.Primitive.Transform.combine()

    <<
      m00::float-size(32)-native,
      m10::float-size(32)-native,
      _m20::size(32),
      m30::float-size(32)-native,
      m01::float-size(32)-native,
      m11::float-size(32)-native,
      _a21::size(32),
      m31::float-size(32)-native,
      _::binary
    >> = mx

    Script.transform(ops, m00, m01, m10, m11, m30, m31)
  end
end
