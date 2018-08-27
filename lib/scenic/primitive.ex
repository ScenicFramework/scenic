#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive do
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Transform
  # alias Scenic.Math.Matrix

  # import IEx

  @callback add_to_graph(map, any, list) :: map

  @callback valid_styles() :: list
  @callback filter_styles( map ) :: map

  @callback info() :: bitstring
  @callback verify( any ) :: any

  @callback default_pin( any ) :: {float, float}
  @callback expand( any ) :: any

  @callback contains_point?( any, {float, float} ) :: true | false


  @not_styles       [:module, :id, :parent_uid,
    :builder, :data, :styles, :transforms, :pin, :rotate, :matrix,
    :scale, :translate]

  @transform_types [:pin, :rotate, :matrix, :scale, :translate]

  @standard_options [:id]


  # note: the following fields are all optional on a primitive.
  # :id, :tags, :event_filter, :state, :styles, :transforms
  # puid is managed automatically by the owning graph
  defstruct module: nil, data: nil, parent_uid: -1,
    id: nil, styles: %{}, transforms: %{}

  @type t :: %Primitive{
    module: atom,
    data: any,
    parent_uid: integer,
    id: any,
    styles: map,
    transforms: map
  }


  #===========================================================================
  defmodule Error do
    defexception [ message: nil, error: nil, data: nil ]
  end


  #===========================================================================
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Primitive

      def build(data \\ nil, opts \\ [])
      def build(data, opts) do
        data = verify!( data )
        Primitive.build(__MODULE__, data, opts)
      end

      def add_to_graph(graph, data \\ nil, opts \\ [])
      def add_to_graph(%Scenic.Graph{} = graph, data, opts) do
        Graph.add(graph, __MODULE__, data, opts )
      end

      @doc false
      def verify!( data ) do
        case verify(data) do
          {:ok, data} -> data
          err -> raise Error, message: info(), error: err, data: data
        end
      end

      # make sure only understood style types are carried on a primitive
      # group is the exception. It overrides this function
      @doc false
      def filter_styles( styles ) when is_map(styles) do
        Enum.reduce(valid_styles(), %{}, fn(k, acc)->
          case Map.get(styles, k) do
            nil -> acc
            val -> Map.put(acc, k, val)
          end
        end)
      end

      # the default behaviour is to do nothing
      # this is the case for groups, lines, and polygons
      @doc false
      def expand( data ), do: data


      # the default is false for contains_point?. Primitive types
      # are effectively un-clickable unless this is overridden.
      # point must already be transformed into local coordinates
      @doc false
      def contains_point?( _, _), do: false

      # unless otherwise defined, the default pin is {0,0}
      @doc false
      def default_pin(_), do: {0.0,0.0}

      # simple defaults that can be overridden
      def get( %Primitive{data: data} ),  do: data
      def put( p, data ),                 do: Primitive.do_put( p, data )
      @doc false
      def normalize( data ),              do: data

      #--------------------------------------------------------
      defoverridable [
        build:            2,
        add_to_graph:     3,
        filter_styles:    1,
        expand:           1,
        contains_point?:  2,
        default_pin:      1,
        get:              1,
        put:              2,
        normalize:        1
      ]
    end # quote
  end # defmacro


  #============================================================================
  # build and add

  #--------------------------------------------------------
  # build a new primitive
  # in general, default the various lists and the assign map to nil to save space
  # assume most elements do not hvae these items set.
  @spec build( module :: atom, data :: any, opts :: list ) :: Primitive.t
  def build( module, data, opts \\ [] ) do
    # first build the map with the non-optional fields
    %{
      __struct__:   __MODULE__,       # per Jose. Declaring stuct this way saves memory
      module:       module,
      data:         data,
      parent_uid:   -1
    }
    |> apply_options( opts )
  end

  defp apply_options( p, opts ) do
    p
    |> apply_standard_options( opts )
    |> apply_style_options( opts )
    |> apply_transform_options( opts )
  end

  defp apply_standard_options( p, opts ) do
    # extract the standard options from the opts
    opts = Enum.filter(opts, fn({k,_}) -> Enum.member?(@standard_options, k) end)

    # enumerate and apply each of the standard opts
    Enum.reduce( opts, p, fn
      {:id,v}, p ->
        Map.put(p, :id, v)
    end)
  end

  defp apply_style_options( p, opts ) do
    # Scan the options list. Merge in each style as they are found
    Enum.reduce(opts, Map.get(p, :styles, %{}), fn
      {:styles, styles}, s when is_map(styles) -> Map.merge(s, styles)
      {k,v}, s ->
        case Enum.member?(@not_styles, k) do
          true -> s   # skip
          false ->
            Style.verify!( k, v )
            Map.put(s, k, v)
        end
    end)
    |> case do
      s when s == %{} -> p
      styles -> Map.put(p, :styles, styles)
    end
  end

  defp apply_transform_options( p, opts ) do
    # map the shortcut transforms options
    opts = Enum.map(opts, fn
      {:t,v} -> {:translate,v}
      {:s,v} -> {:scale,v}
      {:r,v} -> {:rotate,v}
      opt -> opt
    end)

    # Scan the options list. Merge in each style as they are found
    Enum.reduce(opts, Map.get(p, :transforms, %{}), fn
      {:transforms, txs}, t when is_map(txs) -> Map.merge(t, txs)
      {k,v}, t ->
        case Enum.member?(@transform_types, k) do
          true ->
            Transform.verify!( k, v )
            Map.put(t, k, v)
          false -> t
        end
    end)
    |> case do
      t when t == %{} -> p
      txs -> Map.put(p, :transforms, txs)
    end
  end


  #============================================================================
  # type / module

  # def get_module( primitive )
  # def get_module( %Primitive{module: mod} ) when is_atom(mod), do: mod

  #--------------------------------------------------------
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



  #============================================================================
  # styles
  # I'm allowing the styles to not be present on the primitive, which is why
  # I'm not parsing it out in the function match

  @spec get_styles( primitive :: Primitive.t ) :: map
  def get_styles( primitive )
  def get_styles( %Primitive{} = p ) do
    Map.get(p, :styles, %{})
  end


  # def get_primitive_styles( primitive )
  # def get_primitive_styles( %Primitive{} = p ) do
  #   Map.get(p, :styles, %{})
  #   |> Style.primitives()
  # end

  @spec put_styles( primitive :: Primitive.t, styles :: map ) :: Primitive.t
  def put_styles( primitve, styles )
  def put_styles( %Primitive{} = p, nil ), do: Map.delete(p, :styles)
  def put_styles( %Primitive{} = p, s ) when s == %{}, do: Map.delete(p, :styles)
  def put_styles( %Primitive{} = p, styles ) do
    Map.put(p, :styles, styles)
  end

  @spec get_style( primitive :: Primitive.t, type :: atom, default :: any ) :: any
  def get_style(primitive, type, default \\ nil)
  def get_style(%Primitive{} = p, type, default) when is_atom(type) do
    Map.get(p, :styles, %{})
    |> Map.get(type, default)
  end

  # the public facing put_style gives the primitive module a chance to filter the styles
  # do_put_style does the actual work
  @spec put_style( primitive :: Primitive.t, type :: atom, data :: any ) :: Primitive.t
  def put_style(%Primitive{} = p, type, nil) when is_atom(type) do
    Map.get(p, :styles, %{})
    |> Map.delete(type)
    |> ( &put_styles(p, &1) ).()
  end
  def put_style(%Primitive{} = p, type, data) when is_atom(type) do
    Map.get(p, :styles, %{})
    |> Map.put(type, data)
    |> ( &put_styles(p, &1) ).()
  end
  def put_style(%Primitive{} = p, list) when is_list(list) do
    Enum.reduce(list, p, fn({type,data},acc)->
      put_style(acc, type, data)
    end)
  end

  @spec delete_style( primitive :: Primitive.t, type :: atom ) :: Primitive.t
  def delete_style(primitive, type)
  def delete_style(%Primitive{} = p, type) when is_atom(type) do
    Map.get(p, :styles, %{})
    |> Map.delete( type )
    |> ( &put_styles(p, &1) ).()
  end


  #============================================================================
  # transforms
  # I'm allowing the transforms to not be present on the primitive, which is why
  # I'm not parsing it out in the function match

  @spec get_transforms( primitive :: Primitive.t ) :: map
  def get_transforms( primitive )
  def get_transforms( %Primitive{} = p ) do
    Map.get(p, :transforms, %{})
  end

  @spec put_transforms( primitive :: Primitive.t, transforms :: map ) :: Primitive.t
  def put_transforms( primitve, transforms )
  def put_transforms( %Primitive{} = p, nil ), do: Map.delete(p, :transforms)
  def put_transforms( %Primitive{} = p, t ) when t == %{}, do: Map.delete(p, :transforms)
  def put_transforms( %Primitive{} = p, txs ) do
    Map.put(p, :transforms, txs)
  end

  @spec get_transform( primitive :: Primitive.t, type :: atom, default :: any ) :: any
  def get_transform(primitive, tx_type, default \\ nil)
  def get_transform(%Primitive{} = p, tx_type, default) when is_atom(tx_type) do
    Map.get(p, :transforms, %{})
    |> Map.get(tx_type, default)
  end

  # the public facing put_style gives the primitive module a chance to filter the styles
  # do_put_style does the actual work
  @spec put_transform( primitive :: Primitive.t, type :: atom, transform :: any ) :: Primitive.t
  def put_transform(%Primitive{} = p, tx_type, nil) when is_atom(tx_type) do
    Map.get(p, :transforms, %{})
    |> Map.delete(tx_type)
    |> ( &put_transforms(p, &1) ).()
  end
  def put_transform(%Primitive{} = p, tx_type, data) when is_atom(tx_type) do
    Map.get(p, :transforms, %{})
    |> Map.put(tx_type, data)
    |> ( &put_transforms(p, &1) ).()
  end
  def put_transform(%Primitive{} = p, tx_list) when is_list(tx_list) do
    Enum.reduce(tx_list, p, fn({k,v},acc) ->
      put_transform(acc, k, v)
    end)
  end

  @spec delete_transform( primitive :: Primitive.t, type :: atom ) :: Primitive.t
  def delete_transform(primitive, tx_type)
  def delete_transform(%Primitive{} = p, tx_type) when is_atom(tx_type) do
    Map.get(p, :transforms, %{})
    |> Map.delete( tx_type )
    |> ( &put_transforms(p, &1) ).()
  end


  #============================================================================
  # primitive-specific data
  @spec get( primitive :: Primitive.t ) :: any
  def get( primitive )
  def get( %Primitive{module: mod} = p ) do
    # give the primitive a chance to own the get
    mod.get(p)
  end

  @spec put_opts( primitive :: Primitive.t, opts :: list ) :: Primitive.t
  def put_opts( primitive, opts )
  def put_opts( %Primitive{} = p, opts ) when is_list(opts) do
    apply_options( p, opts )
  end

  @spec put( primitive :: Primitive.t, data :: any, opts :: list ) :: Primitive.t
  def put( primitive, data, opts \\ [] )
  def put( %Primitive{module: mod} = p, data, opts ) do
    # give the primitive a chance to own the put
    mod.put( p, data )
    |> apply_options( opts )
  end

  # the default behavior for put - just verify the data and put it in place
  # not a defp because the primitives themselves call it
  def do_put( %Primitive{module: mod} = p, data ) do
    data = mod.verify!( data )
    Map.put(p, :data, data)
  end

  #============================================================================
  # reduce a primitive to its minimal form
  #--------------------------------------------------------
  @doc false
  @spec minimal( primitive :: Primitive.t ) :: map
  def minimal( %Primitive{module: mod, data: data} = p ) do     #parent_uid: puid
      min_p = %{
        data:       {mod, data},
      }

      # add styles, if any are set
      min_p = case Map.get(p, :styles) do
        nil -> min_p
        styles ->
          prim_styles = Style.primitives(styles)
          case prim_styles == %{} do
            true -> min_p
            false -> Map.put(min_p, :styles, prim_styles)
          end
      end

      # add the id if set
      min_p = case Map.get(p, :id) do
        nil -> min_p
        id -> Map.put(min_p, :id, id)
      end

      # add transforms, if any are set
      case Map.get(p, :transforms) do
        nil -> min_p
        txs ->
            # if either rotate or scale is set, and pin is not, set pin to the default
            txs = case (Map.get(txs, :rotate) != nil || Map.get(txs, :scale) != nil) && (Map.get(txs, :pin) == nil) do
              true ->
                pin = Map.get(p, :module).default_pin(Map.get(p, :data))
                Map.put(txs, :pin, pin )
              false -> txs
            end

            # normalize scale if necessary
            txs = case txs[:scale] do
              nil -> txs
              pct when is_number(pct) ->
                Map.put(txs, :scale, {pct,pct})
              {_,_} -> txs
            end

            Map.put(min_p, :transforms, txs)
      end
  end


  #--------------------------------------------------------
  @spec contains_point?( primitive :: Primitive.t, point :: Scenic.Math.point ) :: map
  def contains_point?( %Primitive{module: mod, data: data}, point) do
    mod.contains_point?(data, point)
  end
end























