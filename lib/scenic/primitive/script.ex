#
#  Created by Boyd Multerer on 2021-02-03.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Script do
  @moduledoc """
  A reference to a draw script.

  The `Script` primitive is used to refer to a script that you created
  and loaded into the ViewPort separately from the graph. This script also
  has full access to the `Scenic.Script` API.

  For example, the check mark shape in the `Checkbox` control is a draw
  script that is reference by the checkbox control's graph. A graph
  can reference the same script multiple times, which is very efficient
  as the script is only sent to the drivers once.

  If the graph is modified later, then any scripts it references will not
  need to be resent to the drivers. This is an isolation of concerns. The same
  is true in reverse. If you rebuild a script and send it to the
  `ViewPort`, the script will be sent to the drivers, but any graphs that
  reference it do not need to be.

  ## `Script` vs. `Path`

  Both the `Path` and the `Script` primitives use the `Scenic.Script` to create scripts
  are sent to the drivers for drawing. The difference is that a Path is far more limited
  in what it can do, and is inserted inline with the compiled graph that created it.

  The script primitive, on the other hand, has full access to the API set of
  `Scenic.Script` and accesses scripts by reference.

  The inline vs. reference difference is important. A simple path will be consume
  fewer resources. BUT it will cause the entire graph to be recompile and resent
  to the drivers if you change it.

  A script primitive references a script that you create separately from the
  the graph. This means that any changes to the graph (such as an animation) will
  NOT need to recompile or resend the script.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#script/3)

  This example is based on the check mark script from the Checkbox control.

  ```elixir
    alias Scenic.Script

    # build the checkmark script
    my_script =
      Script.start()
      |> Script.push_state()
      |> Script.join(:round)
      |> Script.stroke_width(3)
      |> Script.stroke_color(:light_blue)
      |> Script.begin_path()
      |> Script.move_to(0, 8)
      |> Script.line_to(5, 13)
      |> Script.line_to(12, 1)
      |> Script.stroke_path()
      |> Script.pop_state()
      |> Script.finish()

    # push the script to the ViewPort
    scene = push_script(scene, my_script, "My Script")

    # refer to the script in a graph, and position it
    graph
    |> script("My Script", translate: {3, 2})
  ```
  """

  use Scenic.Primitive
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  @type styles_t :: [:hidden | :scissor]
  @styles [:hidden, :scissor]

  @impl Primitive
  @spec validate(script_id :: Scenic.Script.id()) ::
          {:ok, script_id :: Scenic.Script.id()} | {:error, String.t()}

  def validate(id) when is_bitstring(id) do
    {:ok, id}
  end

  def validate(data) do
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
  # compiling a script is a special case and is handled in Scenic.Graph.Compiler
  @doc false
  @impl Primitive
  @spec compile(primitive :: Primitive.t(), styles :: Style.t()) :: Script.t()
  def compile(%Primitive{module: __MODULE__}, _styles) do
    raise "compiling a Script is a special case and is handled in Scenic.Graph.Compiler"
  end
end
