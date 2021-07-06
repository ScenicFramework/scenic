#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive do
  @moduledoc """
  Please see [`Primitives Overview`](overview_primitives.html) for a high-level description.

  ## What is a primitive

  A primitive is the simplest thing Scenic knows how to draw on the screen. There is is only
  a small, fixed set of them, but they can be combined in a graph to draw very complicated
  images.

  In general, each Primitive type has a piece of data that it expects to operate on. For
  example, Primitive.Text requires a bitstring. Primitive.Circle requires a radius. Please
  see the documentation for each primitive for details.

  ## How to use primitives

  By far, the easiest way to use primitives is to import the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html). These helpers can both add primitives to
  a scene you are building and modify later as you react to events.

  Once you get a primitive out of a graph via functions such as `Graph.modify`, or `Graph.get`,
  You can use the generic helpers in this module to access or manipulate them.

  ## Standard primitives

  The set of primitives supported in Scenic is fixed in any given version. They have been chosen
  to provide the maximum flexibility when combined together, while still requiring the minimal
  amount of code and maintenance.

  If required, new primitives can be added in the future, but they will not work with older
  versions of the drivers.

  * [`Arc`](Scenic.Primitive.Arc.html) draws an arc. This would be a line cut out of a part of the edge of a circle. If you want a shape that looks like a piece of pie, then you should use the [`Sector`](Scenic.Primitive.Sector.html).
  * [`Circle`](Scenic.Primitive.Circle.html) draws a circle.
  * [`Component`](Scenic.Primitive.Component.html) Starts and renders a child component.
  * [`Ellipse`](Scenic.Primitive.Ellipse.html) draws an ellipse.
  * [`Group`](Scenic.Primitive.Group.html) doesn't draw anything. Instead, it creates a node in the graph that you can insert more primitives into. Any styles or transforms you apply to the Group are inherited by all the primitives below it.
  * [`Line`](Scenic.Primitive.Line.html) draws a line.
  * [`Quad`](Scenic.Primitive.Quad.html) draws polygon with four sides.
  * [`Rectangle`](Scenic.Primitive.Rectangle.html) draws a rectangle.
  * [`RoundedRectangle`](Scenic.Primitive.RoundedRectangle.html) draws a rectangle with the corners rounded by a given radius.
  * [`Script`](Scenic.Primitive.Script.html) sends a given render script to the drivers unchanged.
  * [`Sector`](Scenic.Primitive.Sector.html) draws a shape that looks like a piece of pie. If you want to stroke just the curved edge, then combine it with an [`Arc`](Scenic.Primitive.Arc.html).
  * [`Sprites`](Scenic.Primitive.Sprites.html) draw an image, or multiple parts of an image.
  * [`Text`](Scenic.Primitive.Text.html) draws a string of text.
  * [`Triangle`](Scenic.Primitive.Triangle.html) draws a triangle.


  Note: the Path primitive has been deprecated. Use the Script primitive instead.
  """

  alias Scenic.Graph
  alias Scenic.Utilities
  alias Scenic.Primitive
  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Transform

  # alias Scenic.Math.Matrix
  # import IEx

  @type t :: %Primitive{
          module: atom,
          data: any,
          parent_uid: integer,
          id: any,
          styles: map,
          transforms: map,
          opts: list
        }

  @callback validate(data :: any) :: {:ok, data :: any} | {:error, String.t()}

  @callback valid_styles() :: list
  @callback compile(primitive :: Primitive.t(), styles :: Style.t()) ::
              script :: Scenic.Script.t()

  # @callback info(data :: any) :: bitstring
  # @callback verify(any) :: any

  # @callback add_to_graph(map, any, opts :: keyword) :: map
  # @callback default_pin(any) :: {float, float}
  # @callback contains_point?(any, {float, float}) :: true | false

  # note: the following fields are all optional on a primitive.
  # puid is managed automatically by the owning graph
  # custom opts is used for components
  defstruct module: nil,
            data: nil,
            parent_uid: -1,
            id: nil,
            styles: %{},
            transforms: %{},
            opts: []

  # # ===========================================================================
  # defmodule Error do
  #   @moduledoc false
  #   defexception message: nil
  # end

  # ===========================================================================
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Primitive

      @doc false
      def build(data, opts \\ []) do
        Primitive.build(__MODULE__, data, opts)
      end

      @doc false
      def add_to_graph(graph, data \\ nil, opts \\ [])

      def add_to_graph(%Scenic.Graph{} = graph, data, opts) do
        Graph.add(graph, __MODULE__, data, opts)
      end

      # the default is false for contains_point?. Primitive types
      # are effectively un-clickable unless this is overridden.
      # point must already be transformed into local coordinates
      @doc false
      def contains_point?(_, _), do: false

      # unless otherwise defined, the default pin is {0,0}
      @doc false
      def default_pin(_), do: {0.0, 0.0}

      # --------------------------------------------------------
      defoverridable build: 2,
                     add_to_graph: 3,
                     contains_point?: 2,
                     default_pin: 1
    end

    # quote
  end

  # defmacro

  # ============================================================================
  # build and add

  # --------------------------------------------------------
  # build a new primitive
  # in general, default the various lists and the assign map to nil to save space
  # assume most elements do not have these items set.

  @doc """
  Generic builder to create a new primitive.

  This function is used internally. You should almost always use the helpers in
  [Scenic.Primitives](Scenic.Primitives.html) instead.

  Parameters:
  * `module` - The module of the primitive you are building
  * `data` - the primitive-specific data being set into the primitive
  * `opts` - a list of style and transform options to apply to the primitive

  Returns the built primitive.
  """

  @spec build(module :: atom, data :: any, opts :: keyword) :: Primitive.t()
  def build(module, data, opts \\ []) do
    data =
      case module.validate(data) do
        {:ok, data} -> data
        {:error, error} -> raise error
      end

    # prepare and validate the opts
    {:ok, id, st, tx, op} = prep_opts(opts)

    # first build the map with the non-optional fields
    %{
      # per Jose. Declaring struct this way saves memory
      __struct__: __MODULE__,
      id: id,
      module: module,
      data: data,
      parent_uid: -1,
      styles: Enum.into(st, %{}),
      transforms: Enum.into(tx, %{}),
      opts: op
    }
  end

  # split a primitive's options into three buckets. Styles, Transforms, and opts
  # this is because the three groups have different render and inheritance models.
  defp prep_opts(opts) when is_list(opts) do
    {id, st, tx, op} =
      Enum.reduce(
        opts,
        {nil, [], [], []},
        fn {k, v}, {id, st, tx, op} ->
          cond do
            k == :id -> {v, st, tx, op}
            Style.opts_map()[k] -> {id, [{k, v} | st], tx, op}
            Transform.opts_map()[k] -> {id, st, [{k, v} | tx], op}
            true -> {id, st, tx, [{k, v} | op]}
          end
        end
      )

    # validate the opts for styles and transforms
    st =
      case NimbleOptions.validate(st, Style.opts_schema()) do
        {:ok, st} -> st
        {:error, error} -> raise Exception.message(error)
      end

    tx =
      case NimbleOptions.validate(tx, Transform.opts_schema()) do
        {:ok, tx} -> tx
        {:error, error} -> raise Exception.message(error)
      end

    {:ok, id, st, tx, op}
  end

  # ============================================================================
  # styles

  @doc """
  Get the styles map from a primitive.

  Parameters:
  * `primitive` - The primitive

  Returns the map of styles set directly onto this primitive. This does
  not include any inherited styles.
  """
  @spec get_styles(primitive :: Primitive.t()) :: map
  def get_styles(primitive)

  def get_styles(%Primitive{} = p) do
    Map.get(p, :styles, %{})
  end

  @doc """
  Update the styles map in a primitive.

  Parameters:
  * `primitive` - The primitive
  * `styles` - The new styles map

  Returns the primitive with the updated styles.
  """
  @spec put_styles(primitive :: Primitive.t(), styles :: map) :: Primitive.t()
  def put_styles(primitive, styles)
  def put_styles(%Primitive{} = p, nil), do: Map.delete(p, :styles)
  def put_styles(%Primitive{} = p, s) when s == %{}, do: Map.delete(p, :styles)

  def put_styles(%Primitive{} = p, styles) do
    Map.put(p, :styles, styles)
  end

  @spec get_style(primitive :: Primitive.t(), type :: atom, default :: any) :: any
  def get_style(primitive, type, default \\ nil)

  @doc """
  Get the value of a specific style set on the primitive.

  If the style is not set, it returns default

  Parameters:
  * `primitive` - The primitive
  * `type` - atom representing the style to get.
  * `default` - default value to return if the style is not set.

  Returns the value of the style.
  """
  def get_style(%Primitive{} = p, type, default) when is_atom(type) do
    Map.get(p, :styles, %{})
    |> Map.get(type, default)
  end

  @doc """
  Update the value of a specific style set on the primitive.

  Parameters:
  * `primitive` - The primitive
  * `type` - atom representing the style to get.
  * `data` - the value to set on the style.

  Returns the updated primitive.
  """
  @spec put_style(primitive :: Primitive.t(), type :: atom, data :: any) :: Primitive.t()
  def put_style(%Primitive{} = p, type, nil) when is_atom(type) do
    delete_style(p, type)
  end

  def put_style(%Primitive{} = p, type, data) when is_atom(type) do
    merge_opts(p, [{type, data}])
  end

  @doc """
  Deletes a specified style from a primitive.

  Does nothing if the style is not set.

  Parameters:
  * `primitive` - The primitive
  * `type` - atom representing the style to delete.

  Returns the updated primitive.
  """
  @spec delete_style(primitive :: Primitive.t(), type :: atom) :: Primitive.t()
  def delete_style(primitive, type)

  def delete_style(%Primitive{} = p, type) when is_atom(type) do
    Map.get(p, :styles, %{})
    |> Map.delete(type)
    |> (&put_styles(p, &1)).()
  end

  # ============================================================================
  # transforms

  @doc """
  Get the transforms map from a primitive.

  Parameters:
  * `primitive` - The primitive

  Returns the map of transforms set directly onto this primitive. This does
  not include any inherited transforms.
  """
  @spec get_transforms(primitive :: Primitive.t()) :: map
  def get_transforms(primitive)

  def get_transforms(%Primitive{} = p) do
    Map.get(p, :transforms, %{})
  end

  @doc """
  Update the transforms map in a primitive.

  Parameters:
  * `primitive` - The primitive
  * `transforms` - The new transforms map

  Returns the primitive with the updated transforms.
  """
  @spec put_transforms(primitive :: Primitive.t(), transforms :: map) :: Primitive.t()
  def put_transforms(primitive, transforms)
  def put_transforms(%Primitive{} = p, nil), do: Map.delete(p, :transforms)
  def put_transforms(%Primitive{} = p, t) when t == %{}, do: Map.delete(p, :transforms)

  def put_transforms(%Primitive{} = p, txs) do
    Map.put(p, :transforms, txs)
  end

  @spec get_transform(primitive :: Primitive.t(), type :: atom, default :: any) :: any
  def get_transform(primitive, tx_type, default \\ nil)

  @doc """
  Get the value of a specific transform set on the primitive.

  If the transform is not set, it returns default

  Parameters:
  * `primitive` - The primitive
  * `type` - atom representing the transform to get.
  * `default` - default value to return if the transform is not set.

  Returns the value of the transform.
  """
  def get_transform(%Primitive{} = p, tx_type, default) when is_atom(tx_type) do
    Map.get(p, :transforms, %{})
    |> Map.get(tx_type, default)
  end

  @doc """
  Update the value of a specific transform set on the primitive.

  Parameters:
  * `primitive` - The primitive
  * `type` - atom representing the transform to get.
  * `data` - the value to set on the transform.

  Returns the updated primitive.
  """
  @spec put_transform(primitive :: Primitive.t(), type :: atom, transform :: any) :: Primitive.t()
  def put_transform(%Primitive{} = p, tx_type, nil) when is_atom(tx_type) do
    Map.get(p, :transforms, %{})
    |> Map.delete(tx_type)
    |> (&put_transforms(p, &1)).()
  end

  def put_transform(%Primitive{} = p, tx_type, data) when is_atom(tx_type) do
    Map.get(p, :transforms, %{})
    |> Map.put(tx_type, data)
    |> (&put_transforms(p, &1)).()
  end

  # @deprecated "Use Primitive.merge_opts instead"
  # def put_transform(%Primitive{} = p, tx_list) when is_list(tx_list) do
  #   Enum.reduce(tx_list, p, fn {k, v}, acc ->
  #     put_transform(acc, k, v)
  #   end)
  # end

  @doc """
  Deletes a specified transform from a primitive.

  Does nothing if the transform is not set.

  Parameters:
  * `primitive` - The primitive
  * `type` - atom representing the transform to delete.

  Returns the updated primitive.
  """
  @spec delete_transform(primitive :: Primitive.t(), type :: atom) :: Primitive.t()
  def delete_transform(primitive, tx_type)

  def delete_transform(%Primitive{} = p, tx_type) when is_atom(tx_type) do
    Map.get(p, :transforms, %{})
    |> Map.delete(tx_type)
    |> (&put_transforms(p, &1)).()
  end

  # ============================================================================
  # primitive-specific data

  @doc """
  Get the value of the primitive-specific data.

  Parameters:
  * `primitive` - The primitive

  Returns the value of the primitive-specific data.
  """
  @spec get(primitive :: Primitive.t()) :: any
  def get(%Primitive{data: data}) do
    data
  end

  # @deprecated "Use Primitive.merge_opts instead."
  # @spec put_opts(primitive :: Primitive.t(), opts :: keyword) :: Primitive.t()
  # def put_opts(primitive, opts)

  # def put_opts(%Primitive{}, opts) when is_list(opts) do
  #   raise "Primitive.put_opts has been deprecated. Use Primitive.merge_opts instead."
  # end

  @doc """
  Merge an options-list of styles and transforms onto a primitive.

  This function might go through a name-change in the future. It is really
  more of a merge. The supplied list of styles and transforms

  Parameters:
  * `primitive` - The primitive

  Returns the value of the primitive-specific data.
  """
  @spec merge_opts(primitive :: Primitive.t(), opts :: keyword) :: Primitive.t()
  def merge_opts(primitive, opts)

  def merge_opts(%Primitive{} = primitive, opts) when is_list(opts) do
    {:ok, id, st, tx, op} = prep_opts(opts)

    primitive
    |> Utilities.Map.put_set(:id, id)
    |> Map.put(:styles, Map.merge(primitive.styles, Enum.into(st, %{})))
    |> Map.put(:transforms, Map.merge(primitive.transforms, Enum.into(tx, %{})))
    |> Map.put(:opts, Keyword.merge(primitive.opts, op))
  end

  @doc """
  Put primitive-specific data onto the primitive.

  Like many of the functions in the Scenic.Primitive module, you are usually better
  off using the helper functions in [`Scenic.Primitives`](Scenic.Primitives.html) instead.

  Parameters:
  * `primitive` - The primitive
  * `data` - The data to set
  * `opts` - A list of style/transform options to merge

  Returns the updated primitive.
  """

  @spec put(primitive :: Primitive.t(), data :: any, opts :: list) :: Primitive.t()
  def put(primitive, data, opts \\ [])

  def put(%Primitive{module: mod} = p, data, opts) do
    case mod.validate(data) do
      {:ok, data} -> data
      {:error, error} -> raise error
    end

    # give the primitive a chance to own the put
    p
    |> Map.put(:data, data)
    |> merge_opts(opts)
  end

  # # the default behavior for put - just verify the data and put it in place
  # # not a defp because the primitives themselves call it
  # @doc false
  # def do_put(%Primitive{module: mod} = p, data) do
  #   case mod.validate(data) do
  #     {:ok, data} -> data
  #     {:error, error} -> raise Exception.message(error)
  #   end
  #   Map.put(p, :data, data)
  # end

  # --------------------------------------------------------
  @doc """
  Determines if a point is contained within a primitive.

  The supplied point must already be projected into the local coordinate space
  of the primitive. In other words, this test does NOT take into account any
  transforms that have been applied to the primitive.

  The input mechanism takes care of this for you by projecting incoming points
  by the inverse-matrix of a primitive before calling this function...

  Note that some primitives, such as Group, do not inherently have a notion of
  containing a point. In those cases, this function will always return false.

  Parameters:
  * `primitive` - The primitive
  * `point` - The point to test

  Returns `true` or `false`.
  """

  @spec contains_point?(primitive :: Primitive.t(), point :: Scenic.Math.point()) :: map
  def contains_point?(%Primitive{module: mod, data: data}, point) do
    mod.contains_point?(data, point)
  end
end
