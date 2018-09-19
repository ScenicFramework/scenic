#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Group do
  use Scenic.Primitive
  alias Scenic.Primitive

  #  import IEx

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def build(nil, opts), do: build([], opts)

  def build(ids, opts) do
    verify!(ids)
    Primitive.build(__MODULE__, ids, opts)
  end

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a list of valid uids of other elements in the graph.
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify(ids) when is_list(ids) do
    case Enum.all?(ids, fn id -> is_integer(id) end) do
      true -> {:ok, ids}
      false -> :invalid_data
    end
  end

  def verify(_), do: :invalid_data

  # ============================================================================
  # filter and gather styles

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
