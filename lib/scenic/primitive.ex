#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive do
  alias Scenic.Utilities
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Transform
  alias Scenic.Math.Matrix

  # import IEx

  @callback add_to_graph(map, any, list) :: map

  @callback valid_styles() :: list
  @callback filter_styles( map ) :: map

  @callback info() :: bitstring
  @callback verify( any ) :: any

  @callback default_pin( any ) :: {integer, integer}
  @callback expand( any ) :: any

  @callback contains_point?( any, {integer, integer} ) :: true | false


  @not_styles       [:module, :uid, :parent_uid, :id, :tags, :event_filter,
    :state, :builder, :data, :styles, :transforms, :pin, :rotate, :matrix,
    :scale, :translate]

  @transform_types [:pin, :rotate, :matrix, :scale, :translate]

  @standard_options [:id, :tags]


  # note: the following fields are all optional on a primitive.
  # :id, :tags, :event_filter, :state, :styles, :transforms
  defstruct module: nil, uid: -1, parent_uid: -1, data: nil,
    id: nil, tags: [], event_filter: nil, state: nil, styles: %{}, transforms: %{},
    local_tx: nil, inverse_tx: nil



  #===========================================================================
  defmodule Error do
    defexception [ message: nil, error: nil ]
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

      def verify!( data ) do
        case verify(data) do
          {:ok, data} -> data
          err -> raise Error, message: info(), error: err
        end
      end

      # make sure only understood style types are carried on a primitive
      # group is the exception. It overrides this function
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
      def expand( data ), do: data


      # the default is false for contains_point?. Primitive types
      # are effectively un-clickable unless this is overridden.
      # point must already be transformed into local coordinates
      def contains_point?( _, _), do: false

      # simple defaults that can be overridden
      def get( %Primitive{data: data} ),  do: data
      def put( p, data ),                 do: Primitive.do_put( p, data )
      def normalize( data ),              do: data

      #--------------------------------------------------------
      defoverridable [
        build:            2,
        add_to_graph:     3,
        filter_styles:    1,
        expand:           1,
        contains_point?:  2,
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
  def build( module, data, opts \\ [] ) do
    # first build the map with the non-optional fields
    %{
      __struct__:   __MODULE__,       # per Jose. Declaring stuct this way saves memory
      module:       module,
      data:         data,
      uid:          nil,
      parent_uid:   -1
    }
    |> apply_options( opts )
  end

  def update_opts( %Primitive{} = p, opts ) do
    apply_options( p, opts )
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
      {:id,v}, p when is_atom(v) or is_bitstring(v) ->
        Map.put(p, :id, v)
      {:id,_}, _ ->
        raise Error, message: "id option must be an atom"

      {:tags,v}, p when is_list(v) ->
        Map.put(p, :tags, v)
      {:tags,_}, _ ->
        raise Error, message: "tags option must be a list"
    end)
  end

  defp apply_style_options( p, opts ) do
    # extract the styles from the opts
    styles = Enum.reject(opts, fn({k,_}) -> Enum.member?(@not_styles, k) end)
    |> Enum.into( %{} )

    # verify the transforms
    Enum.each(styles, fn{k,v} -> Style.verify!( k, v ) end)

    # return the verified transforms
    Map.get(p, :styles, %{})
    |> Map.merge( styles )
    |> case do
      s when s == %{} ->
        p
      styles ->
        Map.put(p, :styles, styles)
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

    # extract the transforms from the opts
    txs = Enum.filter(opts, fn({k,_}) -> Enum.member?(@transform_types, k) end)
    |> Enum.into( %{} )

    # verify the transforms
    Enum.each(txs, fn{k,v} -> Transform.verify!( k, v ) end)

    # return the verified transforms
    Map.get(p, :transforms, %{})
    |> Map.merge( txs )
    |> case do
      t when t == %{} ->
        p
      txs ->
        Map.put(p, :transforms, txs)
    end
  end

  # defp prep_state_opt( state )
  # defp prep_state_opt( state ),                 do: state

  # defp prep_event_filter_opt( event_handler )
  # defp prep_event_filter_opt( nil ),            do: nil
  # defp prep_event_filter_opt( {mod,act} )       when is_atom(mod) and is_atom(act), do: {mod,act}
  # defp prep_event_filter_opt( handler )         when is_function(handler, 4), do: handler
  # defp prep_event_filter_opt( _ ) do
  #   raise Error, message: "event_handler option must be a function or {module, action}"
  # end


  #============================================================================
  # type / module

#  def type_code(primitive),           do: get_module(primitive).type_code()

  def get_module( primitive )
  def get_module( %Primitive{module: mod} ) when is_atom(mod), do: mod


  #============================================================================
  # Structure

  #--------------------------------------------------------
  # uid
  def get_uid( primitive )
  def get_uid( %Primitive{uid: uid} ), do: uid

  def put_uid( primitive, uid )
  def put_uid( %Primitive{} = p, uid )    when is_integer(uid) do
    Map.put(p, :uid, uid)
  end

  #--------------------------------------------------------
  # the parent group in the graph
  def get_parent_uid( primitive )
  def get_parent_uid(%Primitive{parent_uid: puid}) when is_integer(puid), do: puid

  def put_parent_uid(primitive, uid)
  def put_parent_uid(%Primitive{} = p, puid)  when is_integer(puid) do
    Map.put(p, :parent_uid, puid)
  end


  #--------------------------------------------------------
  # id
  # I'm allowing the styles to not be present on the primitive, which is why
  # I'm not parsing it out in the function match

  def get_id( primitive )
  def get_id( %Primitive{} = p ) do
    Map.get(p, :id)
  end

  def put_id( primitive, id )
  def put_id( %Primitive{} = p, nil ), do: Map.delete(p, :id)
  def put_id( %Primitive{} = p, id ) when (is_atom(id) or is_bitstring(id)) do
    Map.put(p, :id, id)
  end

  #--------------------------------------------------------
  # searchable tags - can be strings or atoms or integers
  # I'm allowing the styles to not be present on the primitive, which is why
  # I'm not parsing it out in the function match

  def get_tags( primitive )
  def get_tags(%Primitive{}= p) do
    Map.get(p, :tags, [])
  end

  def put_tags( primitive, tags )
  def put_tags( %Primitive{} = p, nil ), do: Map.delete(p, :tags)
  def put_tags( %Primitive{} = p, [] ), do: Map.delete(p, :tags)
  def put_tags(%Primitive{} = p, tags) when is_list(tags) do
    Map.put(p, :tags, tags)
  end

  def has_tag?( primitive, tag )
  def has_tag?( %Primitive{} = p, tag ) do
    Map.get(p, :tags, [])
    |> Enum.member?( tag )
  end

  def put_tag(primitive, tag)
  def put_tag(%Primitive{tags: tags} = p, tag) do
    case has_tag?(p, tag) do
      true ->   p                   # already has tag. do nothing
      false ->  Map.put(p, :tags, [tag | tags])
    end
  end

  def delete_tag(primitive, tag)
  def delete_tag(%Primitive{tags: tags} = p, tag) do
    Enum.reject(tags, fn(x) -> x == tag end)
    |> ( &Map.put(p, :tags, &1) ).()
  end

  #============================================================================
  # event_filter
  # the event handler to use. must be an atom/module
  # I'm allowing the styles to not be present on the primitive, which is why
  # I'm not parsing it out in the function match

  def get_event_filter( primitive )
  def get_event_filter(%Primitive{} = p) do
    Map.get(p, :event_filter)
  end

  def put_event_filter(primitive, event_handler)
  def put_event_filter(%Primitive{} = p, nil) do
    Map.delete(p, :event_filter)
  end
  def put_event_filter(%Primitive{} = p, evtf) when is_function(evtf, 3) do
    Map.put(p, :event_filter, evtf)
  end
  def put_event_filter(%Primitive{} = p, {module, action})  when is_atom(module) and is_atom(action) do
    Map.put(p, :event_filter, {module, action})
  end

  #--------------------------------------------------------
  # same as setting put_event_filter to nil
  def delete_event_filter( %Primitive{} = p ) do
    Map.delete(p, :event_filter)
  end


  #============================================================================
  # styles
  # I'm allowing the styles to not be present on the primitive, which is why
  # I'm not parsing it out in the function match

  def get_styles( primitive )
  def get_styles( %Primitive{} = p ) do
    Map.get(p, :styles, %{})
  end

  def get_primitive_styles( primitive )
  def get_primitive_styles( %Primitive{} = p ) do
    Map.get(p, :styles, %{})
    |> Style.primitives()
  end

  def put_styles( primitve, styles )
  def put_styles( %Primitive{} = p, nil ), do: Map.delete(p, :styles)
  def put_styles( %Primitive{} = p, s ) when s == %{}, do: Map.delete(p, :styles)
  def put_styles( %Primitive{} = p, styles ) do
    Map.put(p, :styles, styles)
  end

  def get_style(primitive, type, default \\ nil)
  def get_style(%Primitive{} = p, type, default) do
    Map.get(p, :styles, %{})
    |> Map.get(type, default)
  end

  # the public facing put_style gives the primitive module a chance to filter the styles
  # do_put_style does the actual work
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

  def drop_style(primitive, type)
  def drop_style(%Primitive{} = p, type) when is_atom(type) do
    Map.get(p, :styles, %{})
    |> Map.delete( type )
    |> ( &put_styles(p, &1) ).()
  end


  #============================================================================
  # transforms
  # I'm allowing the transforms to not be present on the primitive, which is why
  # I'm not parsing it out in the function match

  def get_transforms( primitive )
  def get_transforms( %Primitive{} = p ) do
    Map.get(p, :transforms, %{})
  end

  def put_transforms( primitve, transforms )
  def put_transforms( %Primitive{} = p, nil ), do: Map.delete(p, :transforms)
  def put_transforms( %Primitive{} = p, t ) when t == %{}, do: Map.delete(p, :transforms)
  def put_transforms( %Primitive{} = p, txs ) do
    Map.put(p, :transforms, txs)
  end

  def get_transform(primitive, tx_type, default \\ nil)
  def get_transform(%Primitive{} = p, tx_type, default) do
    Map.get(p, :transforms, %{})
    |> Map.get(tx_type, default)
  end

  # the public facing put_style gives the primitive module a chance to filter the styles
  # do_put_style does the actual work
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

  def drop_transform(primitive, tx_type)
  def drop_transform(%Primitive{} = p, tx_type) when is_atom(tx_type) do
    Map.get(p, :transforms, %{})
    |> Map.delete( tx_type )
    |> ( &put_transforms(p, &1) ).()
  end


  #--------------------------------------------------------
  # calculates both the local and inverse transforms
  def calculate_transforms( %Primitive{} = p, parent_tx ) do
    Map.get( p, :transforms )
    |> Primitive.Transform.calculate_local()
    |> case do
      nil ->
        p
        |> Map.delete(:local_tx)
        |> Map.delete(:inverse_tx)

      local_tx ->
        inverse = Matrix.mul( parent_tx, local_tx )
        |> Matrix.invert()
        p
        |> Map.put(:local_tx, local_tx)
        |> Map.put(:inverse_tx, inverse)
    end
  end

  #--------------------------------------------------------
  # calculates only the inverse transform
  def calculate_inverse_transform( %Primitive{} = p, parent_tx ) do
    Map.get( p, :local_tx )
    |> case do
      # do nothing if no local_tx is present
      nil -> Map.delete(p, :inverse_tx)
      local_tx ->
        inverse = Matrix.mul( parent_tx, local_tx )
        |> Matrix.invert()
        Map.put(p, :inverse_tx, inverse)
    end
  end


  #============================================================================
  # primitive-specific data

  def get( primitive )
  def get( %Primitive{module: mod} = p ) do
    # give the primitive a chance to own the get
    mod.get(p)
  end

  def put_opts( primitive, opts )
  def put_opts( %Primitive{} = p, opts ) when is_list(opts) do
    apply_options( p, opts )
  end

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
  # app or template controlled state
  # I'm allowing the transforms to not be present on the primitive, which is why
  # I'm not parsing it out in the function match

  def get_state( primitive )
  def get_state( %Primitive{} = p ) do
    Map.get(p, :state)
  end

  def put_state( primitive, state )
  def put_state( %Primitive{} = p, nil ), do: Map.delete(p, :state)
  def put_state( %Primitive{} = p, state ) do
    Map.put(p, :state, state)
  end


  #============================================================================
  # reduce a primitive to its minimal form
  #--------------------------------------------------------
  def minimal( %Primitive{module: mod, data: data} = p ) do     #parent_uid: puid
      min_p = %{
        data:       {mod, data},
#        puid:       puid
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





  #============================================================================
  # the change script is for internal use between the graph and the view_port system
  # it records the deltas of change for primitives. the idea is to send the minimal
  # amount of information to the view_port (whose renderer may be remote).
  def delta_script( p_original, p_modified )
  def delta_script( p_o, p_m ) do
    p_o = minimal(p_o)
    p_m = minimal(p_m)
    Utilities.Map.difference(p_o, p_m)
  end


  def contains_point?( %Primitive{module: mod, data: data}, pt) do
    mod.contains_point?(data, pt)
  end
end























