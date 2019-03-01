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

  @size 24

  # --------------------------------------------------------
  def init({{head_msg, err_msg, args_msg, stack_msg}, scene_mod, scene_args}, opts) do
    graph =
      Graph.build(font: :roboto, font_size: @size)
      |> button("Try Again", id: :try_again, translate: {20, 40}, theme: :warning)
      |> button("Reset", id: :restart, translate: {120, 40})
      |> text(head_msg, translate: {20, 120}, font_size: @size + 4)
      |> text(err_msg, translate: {20, 130 + @size}, fill: :red)
      |> text(args_msg, translate: {20, 140 + @size * 2}, fill: :yellow)
      |> text(stack_msg, translate: {20, 150 + @size * 4}, fill: :red)
      |> push_graph()

    {:ok, {scene_mod, scene_args, opts[:viewport]}}
  end

  # --------------------------------------------------------
  def filter_event({:click, :try_again}, _, {scene_mod, scene_args, vp} = state) do
    ViewPort.set_root(vp, {scene_mod, scene_args})
    {:stop, state}
  end

  # --------------------------------------------------------
  def filter_event({:click, :restart}, _, {_, _, vp} = state) do
    ViewPort.reset(vp)
    {:stop, state}
  end
end
