#
#  Created by Boyd Multerer on 28/02/2019.
#  Copyright © 2019 Kry10 Limited. All rights reserved.
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
  alias Scenic.Assets.Static

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

  @default_font :roboto
  @error_color :orange_red
  @args_color :yellow

  # --------------------------------------------------------
  @impl Scenic.Scene
  def init(scene, {{module_msg, err_msg, args_msg, stack_msg}, scene_mod, scene_args}, _opts) do
    # Get the viewport width
    {width, _} = scene.viewport.size

    {:ok, {Static.Font, fm}} = Static.fetch(@default_font)
    wrap_width = width - @margin_h * 2

    head_msg = module_msg <> @mod_header

    err_msg =
      (@error_header <> err_msg)
      |> FontMetrics.wrap(wrap_width, @size, fm)

    args_msg =
      (@args_header <> args_msg)
      |> FontMetrics.wrap(wrap_width, @size, fm)

    stack_msg =
      (@stack_header <> stack_msg)
      |> String.replace("    ", "  ")
      |> FontMetrics.wrap(wrap_width, @size, fm)

    head_v = 80
    args_v = head_v + msg_height(head_msg, @size) + @v_spacing
    err_v = args_v + msg_height(args_msg, @size) + @v_spacing
    stack_v = err_v + msg_height(err_msg, @size) + @v_spacing

    graph =
      Graph.build(font: @default_font, font_size: @size, translate: {@margin_h, @margin_v})
      |> button("Try Again", id: :try_again, theme: :warning)
      |> text(head_msg, translate: {0, head_v}, font_size: @size + 4)
      |> text(args_msg, translate: {0, args_v}, fill: @args_color)
      |> text(err_msg, translate: {0, err_v}, fill: @error_color)
      |> text(stack_msg, translate: {0, stack_v}, fill: @error_color)

    scene =
      scene
      |> assign(args: scene_args, mod: scene_mod)
      |> push_graph(graph)

    {:ok, scene}
  end

  # --------------------------------------------------------
  @impl Scenic.Scene
  def handle_event({:click, :try_again}, _, %{assigns: %{args: args, mod: mod}} = scene) do
    ViewPort.set_root(scene.viewport, mod, args)
    {:noreply, scene}
  end

  defp msg_height(msg, pixel_size) do
    msg
    |> String.split("\n")
    |> Enum.count()
    |> Kernel.*(pixel_size)
  end
end
