#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Group do
  @moduledoc """
  A container to hold other primitives.

  Any styles placed on a group will be inherited by the primitives in the 
  group. Any transforms placed on a group will be multiplied into the transforms
  in the primitives in the group.

  ## Data

  `uids`

  The data for an arc is a list of internal uids for the primitives it contains


  ## Styles

  The group is special in that it accepts all styles and transforms, even if they
  are non-standard. These are then inherited by any primitives, including SceneRefs

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#group/3)
  """

  use Scenic.Primitive
  alias Scenic.Primitive

  #  import IEx

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def build(nil, opts), do: build([], opts)

  def build(ids, opts) do
    verify!(ids)
    Primitive.build(__MODULE__, ids, opts)
  end

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a list of valid uids of other elements in the graph.
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(ids) when is_list(ids) do
    if Enum.all?(ids, &is_integer/1), do: {:ok, ids}, else: :invalid_data
  end

  def verify(_), do: :invalid_data

  # ============================================================================
  # filter and gather styles

  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @spec valid_styles() :: [:all, ...]
  def valid_styles(), do: [:all]

  def filter_styles(styles) when is_map(styles), do: styles

  # ============================================================================
  # apis to manipulate the list of child ids

  # ----------------------------------------------------------------------------
  def insert_at(%Primitive{module: __MODULE__, data: uid_list} = p, index, uid) do
    Map.put(
      p,
      :data,
      List.insert_at(uid_list, index, uid)
    )
  end

  # ----------------------------------------------------------------------------
  def delete(%Primitive{module: __MODULE__, data: uid_list} = p, uid) do
    Map.put(
      p,
      :data,
      Enum.reject(uid_list, fn xid -> xid == uid end)
    )
  end

  # ----------------------------------------------------------------------------
  def increment(%Primitive{module: __MODULE__, data: uid_list} = p, offset) do
    Map.put(
      p,
      :data,
      Enum.map(uid_list, fn xid -> xid + offset end)
    )
  end
end
