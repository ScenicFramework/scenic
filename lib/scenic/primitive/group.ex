#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
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
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  #  import IEx

  @type t :: [pos_integer]
  @type styles_t :: [:hidden | atom]

  @styles [:hidden]

  # ============================================================================
  # data verification and serialization

  @impl Primitive
  @spec validate(ids :: [pos_integer]) ::
          {:ok, ids :: [pos_integer]} | {:error, String.t()}
  def validate(ids) when is_list(ids) do
    case Enum.all?(ids, fn n -> is_integer(n) && n >= 0 end) do
      true -> {:ok, ids}
      false -> err_validation(ids)
    end
  end

  def validate(data), do: err_validation(data)

  defp err_validation(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Group specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for an Group is a list of primitive ids.#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @impl Primitive
  @spec valid_styles() :: [:hidden, ...]
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  # compiling a group is a special case and is handled in Scenic.ViewPort.GraphCompiler
  @doc false
  @impl Primitive
  @spec compile(primitive :: Primitive.t(), styles :: Style.t()) :: Script.t()
  def compile(%Primitive{module: __MODULE__}, _styles) do
    raise "compiling a group is a special case and is handled in Scenic.ViewPort.GraphCompiler"
  end

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
