#
#  Created by Boyd Multerer on 2018-03-16.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Component do
  @moduledoc """
  Manages a child component from a parent graph
  """

  use Scenic.Primitive
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  @type t :: {mod :: module, param :: any, name :: atom | String.t()}
  @type styles_t :: [:hidden]
  @styles [:hidden]

  # longer names use more memory, but have a lower chance of collision.
  # 16 should still have a very very very low chance of collision
  # (16 * 8) = 128 bits of randomness
  @name_length 16

  # ============================================================================
  # data verification and serialization

  @impl Primitive
  @spec validate(
          {mod :: module, param :: any}
          | {mod :: module, param :: any, name :: pid | atom | String.t()}
        ) ::
          {:ok, {mod :: module, param :: any, name :: pid | atom | String.t()}}
          | {:error, String.t()}
  def validate({mod, param}) do
    name =
      @name_length
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64(padding: false)

    validate({mod, param, name})
  end

  # special case the root

  def validate({:_root_, nil, :_root_}), do: {:ok, {:_root_, nil, :_root_}}

  def validate({mod, param, name})
      when is_atom(mod) and mod != nil and
             (is_pid(name) or is_atom(name) or is_bitstring(name)) and name != nil do
    case mod.validate(param) do
      {:ok, data} -> {:ok, {mod, data, name}}
      err -> err
    end
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Component specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The specification for a component is { module, param } or { module, param, name }

      If you do not supply a name, a random string will be chosen for you.#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  # filter and gather styles

  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @impl Primitive
  @spec valid_styles() :: styles :: styles_t()
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  # compiling a component is a special case and is handled in Scenic.ViewPort.GraphCompiler
  @doc false
  @impl Primitive
  @spec compile(primitive :: Primitive.t(), styles :: Style.m()) :: Script.t()
  def compile(%Primitive{module: __MODULE__}, _styles) do
    raise "compiling a Component is a special case and is handled in Scenic.ViewPort.GraphCompiler"
  end
end
