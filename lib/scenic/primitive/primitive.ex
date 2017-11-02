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

  import IEx

  @callback add_to_graph(map, any, list) :: map

  @callback valid_styles() :: list
  @callback filter_styles( map ) :: map

  @callback info() :: bitstring
  @callback verify( any ) :: boolean
  @callback serialize( any, atom ) :: binary
  @callback deserialize( binary, atom ) :: any

  @callback default_pin( any ) :: {integer, integer}
  @callback expand( any ) :: any

  @callback contains_point?( any, {integer, integer} ) :: true | false



  @not_styles       [:module, :uid, :parent_uid, :id, :tags, :event_filter,
    :state, :builder, :data, :styles, :transforms, :pin, :rotate, :matrix,
    :scale, :translate]

  @transform_types [:pin, :rotate, :matrix, :scale, :translate]


  # note: the following fields are all optional on a primitive.
  # :id, :tags, :event_filter, :state, :styles, :transforms
  defstruct module: nil, uid: -1, parent_uid: -1, data: nil,
    id: nil, tags: [], event_filter: nil, state: nil, styles: %{}, transforms: %{},
    local_tx: nil, inverse_tx: nil



  #===========================================================================
  defmodule Error do
    defexception [ message: nil ]
  end


  #===========================================================================
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Primitive

      def build(data \\ nil, opts \\ [])
      def build(data, opts) do
        verify!( data )
        Primitive.build(__MODULE__, data, opts)
      end

      def add_to_graph(graph, data \\ nil, opts \\ [])
      def add_to_graph(%Scenic.Graph{} = graph, data, opts) do
        Graph.add(graph, __MODULE__, data, opts )
      end

      def verify!( data ) do
        case verify(data) do
          true -> data
          false -> info()
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

      #--------------------------------------------------------
      defoverridable [
        build:            2,
        add_to_graph:     3,
        filter_styles:    1,
        expand:           1,
        contains_point?:  2
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
    |> put_if_set( :id,            prep_id_opt( opts[:id] ) )
    |> put_if_set( :tags,          prep_tags_opt(opts[:tags]) )
    |> put_if_set( :event_filter,  prep_event_filter_opt( opts[:event_filter]) )
    |> put_if_set( :state,         prep_state_opt( opts[:state]) )
    |> put_if_set( :styles,        prep_styles( module, opts ) )
    |> put_if_set( :transforms,    prep_transforms( opts ) )
  end

  defp put_if_set(p, k, nil),                  do: Map.delete(p, k)
  defp put_if_set(p, k, map) when map == %{},  do: Map.delete(p, k)
  defp put_if_set(p, k, list) when list == [], do: Map.delete(p, k)
  defp put_if_set(p, k, v),                    do: Map.put(p, k, v)

  defp prep_state_opt( state )
  defp prep_state_opt( state ),                 do: state

  defp prep_event_filter_opt( event_handler )
  defp prep_event_filter_opt( nil ),            do: nil
  defp prep_event_filter_opt( {mod,act} )       when is_atom(mod) and is_atom(act), do: {mod,act}
  defp prep_event_filter_opt( handler )         when is_function(handler, 4), do: handler
  defp prep_event_filter_opt( _ ) do
    raise Error, message: "event_handler option must be a function or {module, action}"
  end

  defp prep_tags_opt( tag_list )
  defp prep_tags_opt( nil ),                              do: []
  defp prep_tags_opt( tag_list ) when is_list(tag_list),  do: tag_list
  defp prep_tags_opt( _ ) do
    raise Error, message: "tags option must be a list"
  end

  defp prep_id_opt( id )
  defp prep_id_opt( nil ),                                          do: nil
  defp prep_id_opt( id ) when (is_atom(id) or is_bitstring(id)),    do: id
  defp prep_id_opt( _ ) do
    raise Error, message: "id option must be an atom"
  end

  defp prep_styles( module, opts ) do
    # strip out any reserved options
    Enum.reduce(@not_styles, opts, &Keyword.delete(&2, &1) )
    # build the new styles map using the given data. verify the data.
    |> Enum.reduce( %{}, fn({k,v},acc) ->
      Style.verify!( k, v )
      Map.put(acc, k, v)
    end)
    |> module.filter_styles()
  end

  defp prep_transforms( opts ) do
    # extract the transforms from the opts
    txs = Enum.reduce(@transform_types, %{}, fn(type, acc) ->
      put_if_set(acc, type, Keyword.get(opts, type))
    end)

    # verify the transforms
    Enum.each(txs, fn{k,v} -> Transform.verify!( k, v ) end)

    # return the verified transforms
    txs
  end


  #============================================================================
  # type / module

  def type_code(primitive),           do: get_module(primitive).type_code()

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
  def put_id( %Primitive{} = p, id ) when (is_atom(id) or is_bitstring(id)) do
    put_if_set(p, :id, id)
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
  def put_tags(%Primitive{} = p, tags)  when is_nil(tags) or is_list(tags) do
    put_if_set(p, :tags, tags)
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
  def put_event_filter(%Primitive{} = p, evtf) when is_function(evtf, 4) do
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
  def put_styles( %Primitive{} = p, styles ) do
    put_if_set(p, :styles, styles)
  end

  def get_style(primitive, type, default \\ nil)
  def get_style(%Primitive{} = p, type, default) do
    Map.get(p, :styles, %{})
    |> Map.get(type, default)
  end

  # the public facing put_style gives the primitive module a chance to filter the styles
  # do_put_style does the actual work
  def put_style(%Primitive{} = p, type, data) when is_atom(type) do
    Map.get(p, :styles, %{})
    |> put_if_set(type, data)
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
  def put_transforms( %Primitive{} = p, txs ) do
    put_if_set(p, :transforms, txs)
  end

  def get_transform(primitive, tx_type, default \\ nil)
  def get_transform(%Primitive{} = p, tx_type, default) do
    Map.get(p, :transforms, %{})
    |> Map.get(tx_type, default)
  end

  # the public facing put_style gives the primitive module a chance to filter the styles
  # do_put_style does the actual work
  def put_transform(%Primitive{} = p, tx_type, data) when is_atom(tx_type) do
    Map.get(p, :transforms, %{})
    |> put_if_set(tx_type, data)
    |> ( &put_transforms(p, &1) ).()
  end

  def drop_transform(primitive, tx_type)
  def drop_transform(%Primitive{} = p, tx_type) when is_atom(tx_type) do
    Map.get(p, :transforms, %{})
    |> Map.delete( tx_type )
    |> ( &put_transforms(p, &1) ).()
  end


  #============================================================================
  # primitive-specific data

  def get( primitive )
  def get( %Primitive{data: data} ), do: data

  def put( primitive, data )
  def put( %Primitive{module: mod} = p, data ) do
    mod.verify!( data )
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
  def put_state( %Primitive{} = p, state ) do
    put_if_set(p, :state, state)
  end


  #============================================================================
  # reduce a primitive to its minimal form
  #--------------------------------------------------------
  def minimal( %Primitive{module: mod, data: data, parent_uid: puid} = p ) do
      min_p = %{
        module:     mod,
        data:       data,
        puid:       puid
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

      # add transforms, if any are set
      case Map.get(p, :transforms) do
        nil -> min_p
        txs -> Map.put(min_p, :transforms, txs)
      end
  end


  #============================================================================
  # the change script is for internal use between the graph and the view_port system
  # it records the deltas of change for primitives. the idea is to send the minimal
  # amount of information to the view_port (whose rendere may be remote).
  def delta_script( p_original, p_modified )
  def delta_script( p_o, p_m ) do
    p_o = minimal(p_o)
    p_m = minimal(p_m)
    Utilities.Map.difference(p_o, p_m)
  end

end























