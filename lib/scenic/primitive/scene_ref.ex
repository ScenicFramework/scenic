#
#  Created by Boyd Multerer on 3/16/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.SceneRef do
  @moduledoc false
  use Scenic.Primitive

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must point to a valid scene or component.
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify(name) when is_atom(name), do: {:ok, name}
  def verify({name, id}) when is_atom(name), do: {:ok, {name, id}}
  def verify(pid) when is_pid(pid), do: {:ok, {pid, nil}}
  def verify({pid, id}) when is_pid(pid), do: {:ok, {pid, id}}
  def verify({:graph, scene, id}), do: {:ok, {:graph, scene, id}}
  def verify({{module, data}, id}) when is_atom(module), do: {:ok, {{module, data}, id}}
  def verify(_), do: :invalid_data

  # ============================================================================
  # filter and gather styles

  @spec valid_styles() :: [:all, ...]
  def valid_styles(), do: [:all]

  def filter_styles(styles) when is_map(styles), do: styles
end
