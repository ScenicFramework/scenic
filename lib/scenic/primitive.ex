#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
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
  * [`Ellipse`](Scenic.Primitive.Ellipse.html) draws an ellipse.
  * [`Group`](Scenic.Primitive.Group.html) doesn't draw anything. Instead, it creates a node in the graph that you can insert more primitives into. Any styles or transforms you apply to the Group are inherited by all the primitives below it.
  * [`Line`](Scenic.Primitive.Line.html) draws a line.
  * [`Path`](Scenic.Primitive.Path.html) is sort of an escape valve for complex shapes not covered by the other primitives. You supply a list of instructions, such as :move_to, :line_to, :bezier_to, etc to generate a complex shape.
  * [`Quad`](Scenic.Primitive.Quad.html) draws polygon with four sides.
  * [`Rectangle`](Scenic.Primitive.Rectangle.html) draws a rectangle.
  * [`RoundedRectangle`](Scenic.Primitive.RoundedRectangle.html) draws a rectangle with the corners rounded by a given radius.
  * [`SceneRef`](Scenic.Primitive.SceneRef.html) doesn't draw anything by itself. Instead it points to another scene/graph and tells the driver to draw that here.
  * [`Sector`](Scenic.Primitive.Sector.html) draws a shape that looks like a piece of pie. If you want to stroke just the curved edge, then combine it with an [`Arc`](Scenic.Primitive.Arc.html).
  * [`Text`](Scenic.Primitive.Text.html) draws a string of text.
  * [`Triangle`](Scenic.Primitive.Triangle.html) draws a triangle.
  """

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Transform
  # alias Scenic.Math.Matrix

  # import IEx

  @callback add_to_graph(map, any, opts :: keyword) :: map

  @callback valid_styles() :: list
  @callback filter_styles(map) :: map

  @callback info(data :: any) :: bitstring
  @callback verify(any) :: any

  @callback default_pin(any) :: {float, float}
  @callback expand(any) :: any

  @callback contains_point?(any, {float, float}) :: true | false

  @not_styles [
    :module,
    :id,
    :parent_uid,
    :builder,
    :data,
    :styles,
    :transforms,
    :pin,
    :rotate,
    :matrix,
    :scale,
    :translate
  ]

  @transform_types [:pin, :rotate, :matrix, :scale, :translate]

  @standard_options [:id]

  # note: the following fields are all optional on a primitive.
  # :id, :tags, :event_filter, :state, :styles, :transforms
  # puid is managed automatically by the owning graph
  defstruct module: nil, data: nil, parent_uid: -1, id: nil, styles: %{}, transforms: %{}

  @type t :: %Primitive{
          module: atom,
          data: any,
          parent_uid: integer,
          id: any,
          styles: map,
          transforms: map
        }

  # ===========================================================================
  defmodule Error do
    @moduledoc false
    defexception message: nil, error: nil, data: nil
  end

  # ===========================================================================
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Primitive

      @doc false
      def build(data \\ nil, opts \\ [])

      def build(data, opts) do
        data = verify!(data)
        Primitive.build(__MODULE__, data, opts)
      end

      @doc false
      def add_to_graph(graph, data \\ nil, opts \\ [])

      def add_to_graph(%Scenic.Graph{} = graph, data, opts) do
        Graph.add(graph, __MODULE__, data, opts)
      end

      @doc false
      def verify!(data) do
        case verify(data) do
          {:ok, data} -> data
          err -> raise Error, message: info(data), error: err, data: data
        end
      end

      # make sure only understood style types are carried on a primitive
      # group is the exception. It overrides this function
      @doc false
      def filter_styles(styles) when is_map(styles) do
        Enum.reduce(valid_styles(), %{}, fn k, acc ->
          case Map.get(styles, k) do
            nil -> acc
            val -> Map.put(acc, k, val)
          end
        end)
      end

      # the default behaviour is to do nothing
      # this is the case for groups, lines, and polygons
      @doc false
      def expand(data), do: data

      # the default is false for contains_point?. Primitive types
      # are effectively un-clickable unless this is overridden.
      # point must already be transformed into local coordinates
      @doc false
      def contains_point?(_, _), do: false

      # unless otherwise defined, the default pin is {0,0}
      @doc false
      def default_pin(_), do: {0.0, 0.0}

      # simple defaults that can be overridden
      @doc false
      def get(%Primitive{data: data}), do: data
      @doc false
      def put(p, data), do: Primitive.do_put(p, data)

      @doc false
      def normalize(data), do: data

      # --------------------------------------------------------
      defoverridable build: 2,
                     add_to_graph: 3,
                     filter_styles: 1,
                     expand: 1,
                     contains_point?: 2,
                     default_pin: 1,
                     get: 1,
                     put: 2,
                     normalize: 1
    end

    # quote
  end

  # defmacro

  # ============================================================================
  # build and add

  # --------------------------------------------------------
  # build a new primitive
  # in general, default the various lists and the assign map to nil to save space
  # assume most elements do not hvae these items set.

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
    # first build the map with the non-optional fields
    %{
      # per Jose. Declaring stuct this way saves memory
      __struct__: __MODULE__,
      module: module,
      data: data,
      parent_uid: -1
    }
    |> apply_options(opts)
  end

  defp apply_options(p, opts) do
    p
    |> apply_standard_options(opts)
    |> apply_style_options(opts)
    |> apply_transform_options(opts)
  end

  defp apply_standard_options(p, opts) do
    # extract the standard options from the opts
    opts = Enum.filter(opts, fn {k, _} -> Enum.member?(@standard_options, k) end)

    # enumerate and apply each of the standard opts
    Enum.reduce(opts, p, fn
      {:id, v}, p ->
        Map.put(p, :id, v)
    end)
  end

  defp apply_style_options(p, opts) do
    # Scan the options list. Merge in each style as they are found
    Enum.reduce(opts, Map.get(p, :styles, %{}), fn
      {:styles, styles}, s when is_map(styles) ->
        Map.merge(s, styles)

      {k, v}, s ->
        case Enum.member?(@not_styles, k) do
          # skip
          true ->
            s

          false ->
            Style.verify!(k, v)
            Map.put(s, k, v)
        end
    end)
    |> case do
      s when s == %{} -> p
      styles -> Map.put(p, :styles, styles)
    end
  end

  defp apply_transform_options(p, opts) do
    # map the shortcut transforms options
    opts =
      Enum.map(opts, fn
        {:t, v} -> {:translate, v}
        {:s, v} -> {:scale, v}
        {:r, v} -> {:rotate, v}
        opt -> opt
      end)

    # Scan the options list. Merge in each style as they are found
    Enum.reduce(opts, Map.get(p, :transforms, %{}), fn
      {:transforms, txs}, t when is_map(txs) ->
        Map.merge(t, txs)

      {k, v}, t ->
        case Enum.member?(@transform_types, k) do
          true ->
            Transform.verify!(k, v)
            Map.put(t, k, v)

          false ->
            t
        end
    end)
    |> case do
      t when t == %{} -> p
      txs -> Map.put(p, :transforms, txs)
    end
  end

  # ============================================================================
  # type / module

  # def get_module( primitive )
  # def get_module( %Primitive{module: mod} ) when is_atom(mod), do: mod

  # --------------------------------------------------------
  # id
  # I'm allowing the styles to not be present on the primitive, which is why
  # I'm not parsing it out in the function match

  # def get_id( primitive )
  # def get_id( %Primitive{} = p ) do
  #   Map.get(p, :id)
  # end

  # def put_id( primitive, id )
  # def put_id( %Primitive{} = p, nil ), do: Map.delete(p, :id)
  # def put_id( %Primitive{} = p, id ), do: Map.put(p, :id, id)

  # ============================================================================
  # styles

  @doc """
  Get the styles map from a primitive.

  Parameters:
  * `primitive` - The primitive

  Returns the a map of styles set directly onto this primitive. This does 
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
  def put_styles(primitve, styles)
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
    Map.get(p, :styles, %{})
    |> Map.delete(type)
    |> (&put_styles(p, &1)).()
  end

  def put_style(%Primitive{} = p, type, data) when is_atom(type) do
    Map.get(p, :styles, %{})
    |> Map.put(type, data)
    |> (&put_styles(p, &1)).()
  end

  @deprecated "Use Primitive.merge_opts instead"
  def put_style(%Primitive{} = p, list) when is_list(list) do
    Enum.reduce(list, p, fn {type, data}, acc ->
      put_style(acc, type, data)
    end)
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

  Returns the a map of transforms set directly onto this primitive. This does 
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
  def put_transforms(primitve, transforms)
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

  @deprecated "Use Primitive.merge_opts instead"
  def put_transform(%Primitive{} = p, tx_list) when is_list(tx_list) do
    Enum.reduce(tx_list, p, fn {k, v}, acc ->
      put_transform(acc, k, v)
    end)
  end

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
  def get(primitive)

  def get(%Primitive{module: mod} = p) do
    # give the primitive a chance to own the get
    mod.get(p)
  end

  @deprecated "Use Primitive.merge_opts instead."
  @spec put_opts(primitive :: Primitive.t(), opts :: keyword) :: Primitive.t()
  def put_opts(primitive, opts)

  def put_opts(%Primitive{}, opts) when is_list(opts) do
    raise "Primitive.put_opts has been deprecated. Use Primitive.merge_opts instead."
  end

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

  def merge_opts(%Primitive{} = p, opts) when is_list(opts) do
    apply_options(p, opts)
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
    # give the primitive a chance to own the put
    mod.put(p, data)
    |> apply_options(opts)
  end

  # the default behavior for put - just verify the data and put it in place
  # not a defp because the primitives themselves call it
  def do_put(%Primitive{module: mod} = p, data) do
    data = mod.verify!(data)
    Map.put(p, :data, data)
  end

  # ============================================================================
  # reduce a primitive to its minimal form
  # --------------------------------------------------------
  @doc false
  @spec minimal(primitive :: Primitive.t()) :: map
  # parent_uid: puid
  def minimal(%Primitive{module: mod, data: data} = p) do
    %{
      data: {mod, data}
    }
    # add styles, if any are set
    |> mprim_add_styles(p)
    # add the id if set
    |> mprim_add_id(p)
    # add transforms, if any are set
    |> mprim_add_transforms(p)
  end

  defp mprim_add_styles(min_p, %{styles: styles}) do
    prim_styles = Style.primitives(styles)

    case prim_styles == %{} do
      true -> min_p
      false -> Map.put(min_p, :styles, prim_styles)
    end
  end

  defp mprim_add_styles(min_p, _), do: min_p

  defp mprim_add_id(min_p, %{id: nil}), do: min_p
  defp mprim_add_id(min_p, %{id: id}), do: Map.put(min_p, :id, id)
  defp mprim_add_id(min_p, _), do: min_p

  defp mprim_add_transforms(min_p, %Primitive{transforms: nil}), do: min_p

  defp mprim_add_transforms(min_p, %Primitive{transforms: txs, module: module, data: data}) do
    # if either rotate or scale is set, and pin is not, set pin to the default
    txs =
      if Map.get(txs, :pin) == nil &&
           (Map.get(txs, :rotate) != nil || Map.get(txs, :scale) != nil) do
        Map.put(txs, :pin, module.default_pin(data))
      else
        txs
      end

    # normalize scale if necessary
    txs =
      case txs[:scale] do
        nil ->
          txs

        pct when is_number(pct) ->
          Map.put(txs, :scale, {pct, pct})

        {_, _} ->
          txs
      end

    Map.put(min_p, :transforms, txs)
  end

  defp mprim_add_transforms(min_p, _), do: min_p

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
