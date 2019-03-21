#
#  Created by Boyd Multerer on 28/02/2019.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

# This scene is automatically set as the root when any other scene
# crashes during it's init phase. The idea is to display debugging
# info about the crash without trigging the fast-as-it-can supervisor
# restart behavior as it tries to start a scene that will always crash.

defmodule Scenic.Scenes.Error do
  @moduledoc false
  use Scenic.Scene

  alias Scenic.ViewPort
  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Components

  # import IEx

  @size 20
  @margin_h 20
  @margin_v 20
  @v_spacing @size

  @stack_header "Stack Trace\n"
  @error_header "Error\n  "
  @args_header "Scene Args\n  "
  @mod_header " crashed during init/2"

  @font :roboto_mono
  @error_color :orange_red
  @args_color :yellow

  # --------------------------------------------------------
  def init({{module_msg, err_msg, args_msg, stack_msg}, scene_mod, scene_args}, opts) do
    # Get the viewport width
    {:ok, %ViewPort.Status{size: {width, _}}} =
      opts[:viewport]
      |> ViewPort.info()

    fm = Scenic.Cache.Static.FontMetrics.get(@font)
    wrap_width = width - @margin_h * 2

    head_msg = module_msg <> @mod_header

    err_msg =
      (@error_header <> err_msg)
      |> FontMetrics.wrap(wrap_width, @size, fm, indent: 4)

    args_msg =
      (@args_header <> args_msg)
      |> FontMetrics.wrap(wrap_width, @size, fm, indent: 4)

    stack_msg =
      (@stack_header <> stack_msg)
      |> String.replace("    ", "  ")
      |> FontMetrics.wrap(wrap_width, @size, fm, indent: 4)

    head_v = 80
    args_v = head_v + msg_height(head_msg, @size) + @v_spacing
    err_v = args_v + msg_height(args_msg, @size) + @v_spacing
    stack_v = err_v + msg_height(err_msg, @size) + @v_spacing

    graph =
      Graph.build(font: @font, font_size: @size, t: {@margin_h, @margin_v})
      |> button("Try Again", id: :try_again, theme: :warning)
      |> button("Reset", id: :restart, translate: {116, 0})
      |> text(head_msg, translate: {0, head_v}, font_size: @size + 4)
      |> text(args_msg, translate: {0, args_v}, fill: @args_color)
      |> text(err_msg, translate: {0, err_v}, fill: @error_color)
      |> text(stack_msg, translate: {0, stack_v}, fill: @error_color)

    {:ok, {scene_mod, scene_args, opts[:viewport]}, push: graph}
  end

  # --------------------------------------------------------
  def filter_event({:click, :try_again}, _, {scene_mod, scene_args, vp} = state) do
    ViewPort.set_root(vp, {scene_mod, scene_args})
    {:halt, state}
  end

  # --------------------------------------------------------
  def filter_event({:click, :restart}, _, {_, _, vp} = state) do
    ViewPort.reset(vp)
    {:halt, state}
  end

  defp msg_height(msg, pixel_size) do
    msg
    |> String.split("\n")
    |> Enum.count()
    |> Kernel.*(pixel_size)
  end
end
