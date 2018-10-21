#
#  Created by Boyd Multerer on 2018-03-16.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.SceneRef do
  @moduledoc """
  A reference to another graph or component.

  When rendering a graph, the SceneRef primmitive causes the render to stop
  what it is doing, render another graph, then continue on where it left off.

  The SceneRef primitive is usually added for you when you use a Component
  via the Primitive.Components helpers.

  However, it can also be useful directly if you want to declare multiple
  graphs in a single scene and reference them from each other. This is
  done when you want to limit the data scanned and sent when just a portion
  of your graph is changing.

  Be careful not to create circular references!

  ## Data

  The data for a SceneRef can take one of several forms.
  * `scene_name` - an atom naming a scene you are managing yourself
  * `{scene_name, sub_id}` - an atom naming a scene you are managing yourself and a sub-id
  * `pid` - the pid of a running scene (rarely used)
  * `{pid, sub_id}` - the pid of a running scene and a sub_id (rarely used)
  * `{:graph, scene, sub_id}` - a full graph key - must already be in `ViewPort.Tables`
  * `{{module, data}, sub_id}` - init data for a dynamic scene (very common)

  ## Styles

  The SceneRef is special in that it accepts all styles and transforms, even if they
  are non-standard. These are then inherited by any dynamic scenes that get created.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#scene_ref/3)
  """

  use Scenic.Primitive

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must point to a valid scene or component.
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(name) when is_atom(name), do: {:ok, name}
  def verify({name, id}) when is_atom(name), do: {:ok, {name, id}}
  def verify(pid) when is_pid(pid), do: {:ok, {pid, nil}}
  def verify({pid, id}) when is_pid(pid), do: {:ok, {pid, id}}
  def verify({:graph, scene, id}), do: {:ok, {:graph, scene, id}}
  def verify({{module, data}, id}) when is_atom(module), do: {:ok, {{module, data}, id}}
  def verify(_), do: :invalid_data

  # ============================================================================
  # filter and gather styles

  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @spec valid_styles() :: [:all, ...]
  def valid_styles(), do: [:all]

  def filter_styles(styles) when is_map(styles), do: styles
end
