#
#  Created by Boyd Multerer on 2018-03-16.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Script do
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
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style


  @type styles_t :: [:hidden]
  @styles [:hidden]


  @impl Primitive
  @spec validate( script_id :: Scenic.Script.id()  ) ::
    {:ok, script_id :: Scenic.Script.id()} | {:error, String.t()}
    
  def validate( id ) when is_atom(id) or is_bitstring(id) or is_reference(id) or is_pid(id) do
    {:ok, id}
  end

  def validate( data ) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Script ID
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The specification for a Script primitive is teh ID of a script that is pushed in to
      a viewport at some other time. This ID can be a pid, an atom, a string or a reference.

      You can refer to a script before it is pushed, but it will not draw until it is pushed
      to the viewport.#{IO.ANSI.default_color()}
      """
    }
  end


  # --------------------------------------------------------
  # filter and gather styles

  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @impl Primitive
  @spec valid_styles() :: styles_t()
  def valid_styles(), do: @styles


  # --------------------------------------------------------
  # compiling a script is a special case and is handled in Scenic.ViewPort.GraphCompiler
  @doc false
  @impl Primitive
  @spec compile( primitive::Primitive.t(), styles::Style.m() ) :: Script.t()
  def compile( %Primitive{module: __MODULE__}, _styles) do
    raise "compiling a Script is a special case and is handled in Scenic.ViewPort.GraphCompiler"
  end

end
