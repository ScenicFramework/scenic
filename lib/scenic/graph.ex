#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#


# internal class to support a Scene's graph structure
# see Scenic.Primative to build and use elements themselves

# the graph comes in several parts

# { primitive_map, id_map, uid_tracker, style_map, get_update_list }

# The primitive_map is the collection of all primitive elements in the graph.
# primiative uids in the primitive_map are integers

# The id_map maps atom developer-friendly ids to the actual numeric ids in the primitive_map




defmodule Scenic.Graph do
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Group
#  alias Scenic.Primitive.StyleSet
  alias Scenic.Math.MatrixBin, as: Matrix

  import IEx

  # make reserved uids, 3 or shorter to avoid potential conflicts
  @root_uid               0

  @identity               Matrix.identity()


  defstruct primitive_map: %{}, id_map: %{}, next_uid: 1, deltas: %{},
    recurring_actions: [], last_recurring_action: nil, add_to: 0



  #===========================================================================
  # define a policy error here - not found or something like that
  defmodule Error do
    defexception [
      # expecting more appropriate messages when raising this
      message:    "Graph was unable to perform the operation",
      primitive:  nil,
      style:      nil
    ]
  end


  #============================================================================
  # access to the raw graph fields
  # concentrate all knowledge of the internal structure of the graph tuple here

  def get_root(%Graph{} = graph),                         do: get(graph, @root_uid)
#  defp put_root(graph, root),                       do: put(graph, @root_uid, root)

  def get_primitive_map(graph)
  def get_primitive_map(%Graph{primitive_map: primitive_map}), do: primitive_map

  defp put_primitive_map(graph, primitive_map)
  defp put_primitive_map(%Graph{} = graph, %{}=p_map) do
    Map.put(graph, :primitive_map, p_map)
  end

  def get_id_map(graph)
  def get_id_map(%Graph{id_map: id_map}),                 do: id_map

  defp put_id_map(graph, id_map)
  defp put_id_map(%Graph{} = graph, %{}=id_map) do
    Map.put(graph, :id_map, id_map)
  end

  def get_next_uid(graph)
  def get_next_uid(%Graph{next_uid: next_uid}),           do: next_uid

  defp put_next_uid(graph, next_uid)
  defp put_next_uid(%Graph{} = graph, next_uid) when is_integer(next_uid) do
    Map.put(graph, :next_uid, next_uid)
  end


#  def get_style_map(graph)
#  def get_style_set_map({_,_,_,style_map,_}),           do: style_map
#  def get_style_map(%{@style_map => style_map}),        do: style_map

#  defp put_style_map(graph, style_map)
#  defp put_style_set_map({pm,ids,nx,_,ul}, style_map) when is_map(style_map) do
#    {pm,ids,nx, style_map ,ul}
#  end
#  defp put_style_map(graph, %{}=style_map) do
#    Map.put(graph, @style_map, style_map)
#  end

#  def get_update_list(graph)
#  def get_update_list(%Graph{update_list: update_list}),  do: update_list
#
#  def put_update_list(graph, get_update_list)
#  def put_update_list(%Graph{} = graph, update_list) when is_list(update_list) do
#    Map.put(graph, :update_list, update_list)
#  end



  #============================================================================
  # shortcuts to modify a primitive

  # When building templates, (which are really just small graphs), it is convenient
  # have functions that provide access to notes indicated by uid. This is just
  # sugar, but tasty sugar at that...

  #--------------------------------------------------------
  # transform
#  def get_uid_transform( graph, uid ) do
#    graph
#    |> get(uid)
#    |> Primitive.get_transform()
#  end
#
#  def put_uid_transform( graph, uid, transform) do
#    modify(graph, uid, fn(p,_) ->
#      Primitive.put_transform( p, transform )
#    end)
#  end
#
#  def put_uid_transform( graph, uid, type, value) do
#    modify(graph, uid, fn(p,_) ->
#      Primitive.put_transform( p, type, value )
#    end)
#  end
#
#  #--------------------------------------------------------
#  # root blingy style list
#  def get_uid_styles( graph, uid ) do
#    graph
#    |> get(uid)
#    |> Primitive.get_styles()    
#  end
#
#  def put_uid_styles( graph, uid, styles ) do
#    modify(graph, uid, fn(p,_) ->
#      Primitive.put_styles( p, styles )
#    end)
#  end
#
#  def get_uid_style(graph, uid, style_type, default \\ nil) do
#    graph
#    |> get(uid)
#    |> Primitive.get_style( style_type, default )    
#  end
#
#  # the public facing put_style gives the primitive module a chance to filter the styles
#  # do_put_style does the actual work
#  def put_uid_style(graph, uid, style) do
#    modify(graph, uid, fn(p,_) ->
#      Primitive.put_style( p, style )
#    end)
#  end
#
#  def drop_uid_style(graph, uid, style_type) do
#    modify(graph, uid, fn(p,_) ->
#      Primitive.drop_style( p, style_type )
#    end)
#  end
#
#  #--------------------------------------------------------
#  # state - changes here do not affect the update list, thus
#  # it does not use the modify function to make the change
#  def get_uid_state(graph, uid)
#  def get_uid_state(graph, uid) when is_integer(uid) do
#    graph
#    |> get(uid)
#    |> Primitive.get_state()
#  end
#
#  def put_uid_state(graph, uid, state)
#  # note, changing the state doesn't affect what it drawn, don't use modify
#  def put_uid_state(graph, uid, state) when is_integer(uid) do
#    graph
#    |> get( uid)
#    |> Primitive.put_state( state )    
#    |> ( &put(graph, uid, &1) ).()
#  end

  #============================================================================
  # build a new graph, starting with the given element
  def build( opts \\ [] ) do
    root = Group.build( [], opts )
    |> Map.put(:uid, @root_uid)

    graph = %Graph{ primitive_map:  %{ @root_uid => root } }
    |> calculate_transforms( 0 )

    case opts[:id] do
      nil ->  graph
      id ->   map_id_to_uid( graph, id, @root_uid)
    end
  end



  #============================================================================
  # manage styles
  # add structure to the graph - requires a reset to the viewport to take effect

#  def put_style_set( graph, name, style_set_or_bling_list )
#  def put_style_set( graph, name, bling_list ) when is_list(bling_list) do
#    put_style_set(graph, name, StyleSet.build(bling_list) )
#  end
#  def put_style_set( graph, name, style_set ) when is_atom(name) or is_bitstring(name) do
#    {graph, uid} = insert_at({graph,-1}, -1, style_set)
#    map_style_set_to_uid(graph, name, uid)
#  end

#  def get_style_set(graph, style_name, default \\ nil)
#  def get_style_set(graph, name, default) when is_atom(name) or is_bitstring(name) do
#    case get_style_set_uid(graph, name) do
#      nil ->  default
#      uid ->  get(graph, uid)
#    end
#  end

#  def get_style_set_uid(graph, style_name)
#  def get_style_set_uid(graph, style_name) when is_atom(style_name) or is_bitstring(style_name) do
#    graph
#    |> get_style_map()
#    |> Map.get(style_name)
#  end

#  def map_style_set_to_uid(graph, style_name, uid)
#  def map_style_set_to_uid(graph, style_name, uid) when is_integer(uid) and (is_atom(style_name) or is_bitstring(style_name)) do
#    graph
#    |> get_style_map()
#    |> Map.put(style_name, uid)
#    |> ( &put_style_map(graph, &1) ).()
#   {p_map, id_map, uid_track, Map.put(style_map, name, uid),ul}
#  end


  #============================================================================
  # add new primitives directly or through a callback
#  def put_new( graph, parent, primitive, builder \\ nil, opts \\ [] )
#
#  # check if the parent id is an atom
#  def put_new(%Graph{} = graph, parent_id, primitive, builder, opts) when is_atom(parent_id) do
#    graph
#    |> resolve_id(parent_id)
#    |> Enum.reduce(graph, fn(uid, g) -> put_new(g, uid, primitive, builder, opts) end)
#  end
#
#  # main put_new functionality
#  def put_new( %Graph{} = graph, parent, primitive, builder, opts ) when is_integer(parent) do
#    {graph, uid} = insert_at({graph, parent}, -1, primitive, opts)
#
#    # run the optional builder
#    cond do
#      is_function(builder, 2) ->  builder.( graph, uid )
#      true ->                     graph
#    end
#  end


  #============================================================================
  # add a pre-built primitive
  def add( graph, primitive )
  def add( %Graph{add_to: puid} = g, %Primitive{} = p ) do
    {graph, _uid} = insert_at({g, puid}, -1, p)
    graph
  end

  # build and add new primitives
  def add( graph, primitive_module, primitive_data, opts \\ [])

  def add( %Graph{add_to: puid} = g, Group, builder, opts) when is_function(builder, 1) do
    p = Group.build([], opts)
    {graph, uid} = insert_at({g, puid}, -1, p, opts)

    graph
    # set the new group as the add_to target
    |> Map.put(:add_to, uid)
    # call the group builder callback
    |> builder.()
    # restore the add_to to puid
    |> Map.put(:add_to, puid)
  end

  def add( %Graph{add_to: puid} = g, mod, data, opts) when is_atom(mod) do
    p = mod.build(data, opts)
    {graph, _uid} = insert_at({g, puid}, -1, p, opts)
    graph
  end

  #============================================================================
  # add a pre-built primitive to an existing group in a graph
  def add_to( graph, id, primitive )
  def add_to( %Graph{} = graph, id, p ) when not is_integer(id) do
    get(graph, id)
    |> Enum.reduce( graph, fn(uid, g) ->
      case get(g, uid) do
        %Primitive{module: Group} ->
          {graph, _uid} = insert_at({g, uid}, -1, p)
          graph
        _ ->
          raise "Can only add primitives to Group nodes"
      end
    end)
  end

  # build and add a new primitive to an existing group in a graph
  def add_to( graph, id, primitive_module, primitive_data, opts \\ [])
  def add_to( %Graph{add_to: puid} = graph, id, primitive_module, primitive_data, opts) when not is_integer(id) do
    get(graph, id)
    |> Enum.reduce( graph, fn(uid, g) ->
      case get(graph, uid) do
        %Primitive{module: Group} ->
          g
          # set the new group as the add_to target
          |> Map.put(:add_to, uid)
          # add the new primitive
          |> add( primitive_module, primitive_data, opts )
        _ ->
          raise "Can only add primitives to Group nodes"
      end
    end)
    # restore the add_to back to whatever it was before
    |> Map.put(:add_to, puid)
  end


  #============================================================================
  # put an existing element by uid
  # do NOT let NEW primitives be added this way as it messes up the next_uid counter
#  def put(graph, uid, primitive)
#  def put({p_map, id_map, uid_track, sm}, 0, p) do
#    case Primitive.get_module(p) do
#      Primitive.Group -> { Map.put(p_map, 0, p), id_map, uid_track, sm }
#      _ -> raise "can only put a Group into uid 0. Did you mean put_new?"
#    end
#  end
#  def put({p_map, id_map, uid_track, sm}, uid, p) when is_integer(uid) do
#    case Map.get(p_map, uid) do
#      nil ->  raise "Can only put primitives by uid if they already exist in the map"
#      _ ->    { Map.put(p_map, uid, p), id_map, uid_track, sm }
#    end
#  end

  #============================================================================
  # put an element by uid
  def put(graph, uid, primitive)
  def put(graph, uid, primitive) when is_integer(uid) do
    case get(graph, uid) do
      nil -> raise Error, message: "Graph.put can only update existing items. Use put_new instead"
      _ ->
        graph
        |> get_primitive_map()
        |> Map.put(uid, primitive)
        |> ( &put_primitive_map(graph, &1) ).()
    end
  end


  #============================================================================
  # create an entry in the id_map
  def map_id_to_uid( graph, id, uid)

  def map_id_to_uid( %Graph{} = graph, ids, uid) when is_list(ids) do
    Enum.reduce(ids, graph, fn(id, acc) -> map_id_to_uid( acc, id, uid) end)
  end

  def map_id_to_uid( %Graph{id_map: id_map} = graph, id, uid) when
      (is_atom(id) or is_bitstring(id)) and is_integer(uid) do
    Map.put(
      graph,
      :id_map,
      do_map_id_to_uid(id_map, id, uid)
    )
  end

  defp do_map_id_to_uid( %{} = id_map, id, uid) when
      (is_atom(id) or is_bitstring(id)) and is_integer(uid) do
    uid_list = [uid | Map.get(id_map, id, [])] |> Enum.uniq()
    Map.put( id_map, id, uid_list )
  end

  #============================================================================
  # remove an entry in the id_map
  def unmap_id_to_uid(graph, id, uid)
  def unmap_id_to_uid(graph, nil, _uid),  do: graph
  def unmap_id_to_uid(graph, _id, nil),   do: graph
  def unmap_id_to_uid(graph, id, uid) when
      (is_atom(id) or is_bitstring(id)) and is_integer(uid) do
    id_map = get_id_map( graph )

    uid_list = Map.get(id_map, id, [])
      |> Enum.reject(fn(mapped_uid)-> mapped_uid == uid end)

    id_map = case uid_list do
      []   -> Map.delete(id_map, id)
      uids -> Map.put(id_map, id, uids)
    end

    put_id_map( graph, id_map )
  end


  #============================================================================
  def resolve_id( graph, id )
  def resolve_id( graph, id ) when (is_atom(id) or is_bitstring(id)) do
    graph
    |> get_id_map()
    |> Map.get(id, [])
#    |> Enum.reverse()
  end


  #============================================================================
  # count all the nodes in a graph. Count traverses the tree as it
  # counts the total number of valid nodes. Note that this might be different
  # than the number of nodes in the graph map if there is some garbage.
  def count(graph, id_or_uid \\ 0)

  #--------------------------------------------------------
  # shortcut for everything in the entire primitive map
  def count(graph, -1) do
    graph
    |> get_primitive_map()
    |> Enum.count()
  end

  #--------------------------------------------------------
  # shortcut for everything under the root node.
  def count(graph, 0) do
    graph
    |> get_primitive_map()
    |> Enum.reduce(1, fn({_,p},acc) ->
      case Primitive.get_parent_uid(p) do
        -1 -> acc
        _ -> acc + 1
      end
    end)
  end

  #--------------------------------------------------------
  # count all the nodes in a graph starting at uid. Count traverses the tree as it
  # counts the total number of valid nodes. This might be different
  # than the number of nodes in the graph map
  def count(graph, uid) when is_integer(uid) do
    reduce(graph, uid, 0, fn(_, acc) -> acc + 1 end)
  end

  #--------------------------------------------------------
  # count the nodes associated with an id.
  def count(graph, id)
  def count(graph, id) when (is_atom(id) or is_bitstring(id)) do
    graph
    |> get_id_map()
    |> Map.get(id, [])
    |> Enum.count()
  end



  #============================================================================
  # get an element by uid. Return default if not there
  def get(graph, uid, default \\ nil)

  def get(graph, uid, default) when is_integer(uid) do
    graph
    |> get_primitive_map()
    |> Map.get(uid, default)
  end

  def get(graph, id, _) when (is_atom(id) or is_bitstring(id)) do
    resolve_id(graph, id)
    |> Enum.reduce([], fn(uid, acc) ->
      case get(graph, uid) do
        nil -> acc
        p -> [p | acc]
      end
    end)
  end

  #--------------------------------------------------------
  # get an element by uid. Raise error if not there
  def get!(graph, uid)
  def get!(graph, uid) do
    graph
    |> get_primitive_map()
    |> Map.fetch!(uid)
  end


  #============================================================================
  # get a list of elements by id
  def get_id(graph, id) do
    graph
    |> resolve_id( id )
    |> Enum.reduce([], fn(uid,acc)-> [get(graph, uid) | acc] end)
    |> Enum.reverse()
  end

  #--------------------------------------------------------
  # get a single element by id. Raise error if it finds any count other than one
  def get_id_one(graph, id) do
    case resolve_id(graph, id) do
      [uid] ->  get( graph, uid )
      _ ->      raise Error, message: "Graph.get_id_one expected to find one and only one element with id: #{inspect(id)}"
    end
  end


  #============================================================================
  # All criteria in the list must pass for a primitive to match

  #--------------------------------------------------------
  def find( graph, below_uid, criteria )

  # allow for a single criteria, not in a list...
  def find( graph, uid, {k, v} ), do: find(graph, uid, [{k,v}] )

  # shortcut to just resolve the id - way faster than traversing the tree
  def find( graph, 0, [{:id, id}] ) when (is_atom(id) or is_bitstring(id)) do
    get(graph, id)
  end

  # generic case
  def find( graph, below_uid, crit ) when is_list(crit) do
    reduce(graph, below_uid, [], fn(p, acc) ->
      case Enum.all?( crit, fn({c,v}) -> find_test(p, c, v) end) do
        true -> [ p | acc]
        _ -> acc
      end
    end)
    |> Enum.reverse()
  end

  #--------------------------------------------------------
  def find_uids( graph, below_uid, criteria )

  # shortcut to just resolve the id - way faster than traversing the tree
  def find_uids( graph, 0, [{:id, id}] ) when (is_atom(id) or is_bitstring(id)) do
    resolve_id(graph, id)
  end

  # generic case
  def find_uids( graph, below_uid, crit ) when is_list(crit) do
    reduce(graph, below_uid, [], fn(p, acc) ->
      case Enum.all?( crit, fn({c,v}) -> find_test(p, c, v) end) do
        true -> [ Primitive.get_uid(p) | acc]
        _ -> acc
      end
    end)
    |> Enum.reverse()
  end

  #--------------------------------------------------------
  defp find_test( primitive, criteria, value )

  defp find_test( primitive, :tag, tag ) do
    primitive
    |> Primitive.get_tags()
    |> Enum.member?( tag )
  end

  defp find_test( primitive, :tags, tag_list ) when is_list(tag_list) do
    tag_list
    |> Enum.all?( fn(tag) -> find_test(primitive, :tag, tag) end)
  end

  defp find_test( primitive, :id, id ) when (is_atom(id) or is_bitstring(id)) do
    Primitive.get_id(primitive) == id
  end

  defp find_test( primitive, :type, type ) when is_atom(type) do
    find_test( primitive, :module, type )
  end

  defp find_test( primitive, :module, module) when is_atom(module) do
    Primitive.get_module(primitive) == module
  end

  defp find_test( primitive, :uid, uid) when is_integer(uid) do
    Primitive.get_uid(primitive) == uid
  end

  defp find_test( primitive, :state, value) do
    Primitive.get_state( primitive ) == value
  end


  #============================================================================
  # insert an element into the graph under the given parent
  # returns the uid and transformed graph with the added element
  # {graph, uid}
  def insert_at(graph_and_parent, index, element, opts \\ [])

  #--------------------------------------------------------
  # main version - force it to be a new item via -1 parent id
#  def insert_at({{p_map, id_map, next_uid, sm, ul}, parent_uid}, index, {m,str,sty,d}, opts) when is_integer(index) do
  def insert_at({graph, parent_uid}, index, %Primitive{} = p, _opts) when is_integer(index) do

    # uid for the new item
    next_uid = get_next_uid( graph )
    uid = next_uid

    # prepare the primitive
    primitive = p
      |> Map.put(:uid, uid)
      |> Map.put(:parent_uid, parent_uid)
#      |> Primitive.put_parent_uid( parent_uid )
#      |> Primitive.do_put_uid( uid )

    # add the element to the primitives map, setting parent_uid into place
    graph = graph
      |> get_primitive_map()
      |> Map.put(uid, primitive)
      |> ( &put_primitive_map(graph, &1) ).()

    # if a parent is requested, reference the element from the parent at the right position
    graph = case parent_uid do
      -1 -> graph
      puid ->
        p_map = get_primitive_map(graph)
        Map.get( p_map, puid )
        |> Group.insert_at( index, uid )
        |> (&Map.put(p_map, puid, &1)).()
        |> ( &put_primitive_map(graph, &1) ).()
    end

    # if the incoming primitive has an id set on it, map it to the uid
    graph = case Primitive.get_id(primitive) do
      nil -> graph
      id ->   map_id_to_uid(graph, id, uid)
    end
    |> calculate_transforms( uid )

    # increment the next uid and gen the completed graph
    {put_next_uid(graph, next_uid + 1), uid}
  end

  #--------------------------------------------------------
  # insert a template, which is a graph that has relative uids
  # can't just merge the various maps. map the incoming graph into an id space that 
  # starts with next_uid, then bump up next_uid to account for everything in the updated graph 
  def insert_at({%Graph{primitive_map: p_map, id_map: id_map, next_uid: next_uid} = graph, parent_uid},
      index,
      %Graph{primitive_map: t_p_map, id_map: t_id_map, next_uid: t_next_uid},
      opts) when is_integer(index) do

    # uid for the new item
    uid = next_uid

    # start by mapping and adding the primitives to the receiver
    p_map = Enum.reduce(t_p_map, p_map, fn({uid, primitive}, acc_g) ->
      # map the uid
      uid = uid + next_uid

      # map the parent id
      primitive = case Primitive.get_parent_uid(primitive) do
        -1 -> primitive              # not in the tree. no change
        parent_id -> Primitive.put_parent_uid(primitive, parent_id + next_uid)
      end

      # if this is a group, increment its children's references
      primitive = case Primitive.get_module(primitive) do
        Group ->  Group.increment( primitive, next_uid )
        _ ->      primitive           # not a Group, do nothing.
      end

      # finally, update the internal uid of the primitive
      primitive = Primitive.put_uid( primitive, uid )

      # add the mapped primitive to the receiver's p_map
      Map.put(acc_g, uid, primitive)
    end)
    
    # if the incoming tree was requested to be inserted into an existing group, then fix that up too
    p_map = if (parent_uid >= 0) do
      # we know the root of the added tree is at next_uid
      p_map = Map.get(p_map, next_uid)
      |> Primitive.put_parent_uid( parent_uid )
      |> ( &Map.put(p_map, next_uid, &1) ).()

      # also need to add the tree as a child to the parent
      Map.get( p_map, parent_uid )
      |> Group.insert_at(index, next_uid)
      |> ( &Map.put(p_map, parent_uid, &1) ).()
    else
      p_map       # do nothing
    end


    # offset the t_id_map, mapping into id_map as we go
    id_map = Enum.reduce(t_id_map, id_map, fn({id,uid_list}, acc_idm) ->
      Enum.reduce(uid_list, acc_idm, fn(uid, acc_acc_idm) ->
        do_map_id_to_uid( acc_acc_idm, id, uid + next_uid)
      end)
    end)

    # if an id was given, map it to the uid
    id_map = case opts[:id] do
      nil ->  id_map
      id ->   do_map_id_to_uid(id_map, id, uid)
    end

    # offset the next_uid
    next_uid = next_uid + t_next_uid

    # return the merged graph
    graph = graph
    |> Map.put(:primitive_map, p_map)
    |> Map.put(:id_map, id_map)
    |> Map.put(:next_uid, next_uid)
    |> calculate_transforms( uid )
    {graph, uid}
  end

  #--------------------------------------------------------
  # insert at the root - graph itself passed in
  def insert_at(%Graph{} = graph, index, element, opts) do
    insert_at({graph, @root_uid}, index, element, opts)
  end


  #============================================================================
  # apis to modify the specified elements in a graph
  # this is different from map in that it does not walk the tree below the given uid

  #--------------------------------------------------------
  def modify( graph, uid, action )

  # transform a single primitive by uid
  def modify( graph, uid, action ) when is_integer(uid) and is_function(action, 1) do
    case get(graph, uid) do
      nil ->  graph                       # not found - do nothing
      p_original ->                       # transform
        case action.(p_original) do
          # no change. do nothing
          ^p_original -> graph

          # change. record it
          %Primitive{module: mod} = p_modified ->
            # filter the styles
            styles = Map.get(p_modified, :styles, %{})
            |> mod.filter_styles( )

            p_modified = Map.put(p_modified, :styles, styles)

            graph
            |> put_delta_base( uid, p_original )
            |> put( uid, p_modified )
            |> calculate_transforms( uid )

          _ ->  raise Error, message: "Action must return a valid primitive"
        end
    end
  end

  # pass in an atom based id, and it will transform all mapped uids
  def modify( graph, id, action ) when (is_atom(id) or is_bitstring(id)) do
    resolve_id(graph, id)
    |> (&modify(graph, &1, action)).()
  end

  # pass in a list of uids to transform
  def modify( graph, uid_list, action ) when is_list(uid_list) do
    Enum.reduce(uid_list, graph, fn(uid, g)-> modify( g, uid, action ) end)
  end

  #--------------------------------------------------------
  # find and modify primitives in one pass
  def find_modify( graph, below_uid, criteria, action )

  def find_modify( graph, below_uid, {k,v}, action ) do
    find_modify( graph, below_uid, [{k,v}], action )
  end

  # shortcut to the regular (faster) modify operation
  def find_modify( graph, 0, [{:id, id}], action )
      when (is_atom(id) or is_bitstring(id)) do
    modify(graph, id, action)
  end

  # main version, which finds and modifies in one pass
  def find_modify( graph, below_uid, crit, action ) when 
      is_integer(below_uid) and is_list(crit) and is_function(action, 1) do
    
    reduce( graph, below_uid, graph, fn(p, g) ->
      # all the criteria must pass to call the action
      case Enum.all?( crit, fn({c,v}) -> find_test(p, c, v) end) do
        true -> modify(g, Primitive.get_uid(p), action)
        _ -> g
      end
    end)

  end


  #============================================================================
  # map a graph via traversal from the root node
  def map(graph, action) when is_function(action, 1) do
    map(graph, @root_uid, action)
  end

  #--------------------------------------------------------
  # map a graph via traversal starting at the node named by uid
  def map(graph, uid, action) when is_integer(uid) and is_function(action, 1) do
    # retreive this node
    primitive = get!(graph, uid)

    # retreive and map this node
    graph = primitive
    |> action.()
    |> (&put(graph, uid, &1)).()


    # if this is a group, map its children
    case Primitive.get_module(primitive) do
      Group ->
        # map it's children by reducing the graph
        Enum.reduce( Primitive.get(primitive), graph, fn(uid, acc) ->
          map(acc, uid, action)
        end)
      _ -> graph        # do nothing
    end
  end

  #============================================================================
  # map a graph, but only those elements mapped to the id
  def map(graph, id, action) when
      (is_atom(id) or is_bitstring(id)) and is_function(action, 1) do
    # resolve the id into a list of uids
    uids = resolve_id(graph, id)

    # map those elements via reduction
    Enum.reduce(uids, graph, fn(uid, acc)->
      # retreive and map this node
      get!(acc, uid)
      |> action.()
      |> (&put(acc, uid, &1)).()
    end)
  end


  #============================================================================
  # reduce a graph via traversal from the root node
  def reduce(graph, acc, action) when is_function(action, 2) do
    reduce(graph, @root_uid, acc, action)
  end

  #--------------------------------------------------------
  # reduce a graph via traversal starting at the node named by uid
  def reduce(graph, uid, acc, action) when is_integer(uid) and is_function(action, 2) do
    # retreive this node
    primitive = get!(graph, uid)

    # if this is a group, reduce its children
    acc = case Primitive.get_module(primitive) do
      Group ->
        Enum.reduce( Primitive.get(primitive), acc, fn(uid, acc) ->
          reduce(graph, uid, acc, action)
        end)
      _ -> acc        # do nothing
    end

    # reduce the node itself, returns the final accumulator
    action.( primitive, acc )
  end

  #============================================================================
  # reduce a graph, but only for nodes mapped to the given id
  def reduce(graph, id, acc, action) when
      (is_atom(id) or is_bitstring(id)) and is_function(action, 2) do
    # resolve the id into a list of uids
    uids = resolve_id(graph, id)

    # reduce on that list of uids
    Enum.reduce(uids, acc, fn(uid, acc) ->
      graph
      |> get!(uid)
      |> action.(acc)
    end)
  end


  #============================================================================
  # send an event to the primitives for handling
  
  def filter_input(graph, event, uid )
  def filter_input(graph, event, nil),  do: {:continue, event, graph}
  def filter_input(graph, event, -1),   do: {:continue, event, graph}

  def filter_input(graph, event, uid) when is_integer(uid) do
    do_filter_input(
      event,
      get( graph, uid ),
      graph
    )
  end

  defp do_filter_input(event, nil, graph), do: {:continue, event, graph}
  defp do_filter_input(event, primitive, graph) do
    id =      Primitive.get_id(primitive)
    filter =  Primitive.get_event_filter(primitive)

    case send_event_to_filter(event, id, primitive, graph, filter) do
      {:stop, graph} ->   {:stop, graph}
      {:continue, event, graph} ->
        parent = primitive
          |> Primitive.get_parent_uid()
          |> ( &get(graph, &1) ).()
        do_filter_input(event, parent, graph)
    end
  end

  defp send_event_to_filter( event, id, primitive, graph, handler )
  defp send_event_to_filter( event, _, _, graph, nil ), do: {:continue, event, graph}
  defp send_event_to_filter( event, id, primitive, graph, {module, action} ) do
    Kernel.apply(module, action, [event, id, primitive, graph])
  end
  defp send_event_to_filter( event, id, primitive, graph, handler ) when is_function(handler, 4) do
    handler.(event, id, primitive, graph)
  end

  #============================================================================
  # graph level shortcut for setting a handler on a primitive

  def put_event_filter(graph, uid, handler)

  def put_event_filter(graph, uid, handler) when is_integer(uid) do
    # don't use modify here as it does not invalidate the draw parameters.
    graph
    |> get( uid )
    |> Primitive.put_event_filter( handler )
    |> ( &put(graph, uid, &1) ).()
  end

  def put_event_filter(graph, id, handler) when (is_atom(id) or is_bitstring(id)) do
    graph
    |> resolve_id( id )
    |> Enum.reduce( graph, fn(uid, acc) ->
      put_event_filter(acc, uid, handler)
    end)
  end


  #============================================================================
  # apply style shortcuts

#  def put_style(graph, id, style)
#  def put_style(graph, id, {mod, data}) when is_atom(mod) and is_binary(data) do
#    modify(graph, id, fn(p) ->
#      Primitive.put_style( p, {mod, data} )
#    end)
#  end
#
#  def put_style(graph, id, style_module, build_args)
#  def put_style(graph, id, mod, args) when is_atom(mod) and is_list(args) do
#    modify(graph, id, fn(p) ->
#      Primitive.put_style( p, Kernel.apply(mod, :build, args) )
#    end)
#  end



  #============================================================================
  # support for recurring actions
  # recurring_actions: [{ref, call, data}]

  #--------------------------------------------------------
  def schedule_recurring_action(graph, args, callback_or_module)
  def schedule_recurring_action(%Graph{} = graph, args, callback) when is_function(callback, 3) do
    do_schedule_recurring_action(graph, args, callback)
  end
  def schedule_recurring_action(%Graph{} = graph, args, module) when is_atom(module) do
    do_schedule_recurring_action(graph, args, module)
  end
  def schedule_recurring_action(%Graph{} = graph, args, module, action) when is_atom(module) and is_atom(action) do
    do_schedule_recurring_action(graph, args, {module, action})
  end
  def schedule_recurring_action!(graph, args, callback_or_module) do
    {:ok, graph, _} = schedule_recurring_action(graph, args, callback_or_module)
    graph
  end
  def schedule_recurring_action!(graph, args, mod, action) do
    {:ok, graph, _} = schedule_recurring_action(graph, args, mod, action)
    graph
  end
  defp do_schedule_recurring_action(%Graph{recurring_actions: actions} = graph, args, action) do
    ref = make_action_ref(actions)
    {
      :ok,
      Map.put(graph, :recurring_actions, [ {ref, action, args} | actions ]),
      {:recurring_action_reference, ref}
    }    
  end

  # doesn't need to be a globally unique reference from make_ref. Just something that is unique
  # to this list of actions. If there is a collision, increase length by 1, which should sort it
  defp make_action_ref(actions, ref_length \\ 4) do
    ref = :crypto.strong_rand_bytes(ref_length)
      |> Base.encode64(padding: false)
      |> binary_part(0, ref_length)

    # if it isn't unique, try again
    case Enum.find(actions, false, fn({r,_,_})-> r == ref end) do
      false -> ref
      _ -> make_action_ref(actions, ref_length + 1 )
    end
  end

  #--------------------------------------------------------
  def cancel_recurring_action(%Graph{recurring_actions: actions} = graph, {:recurring_action_reference, reference}) do
    Enum.reject(actions, fn({ref,_,_})-> ref == reference end)
    |> ( &Map.put(graph, :recurring_actions, &1) ).()
  end

  #--------------------------------------------------------
  def tick_recurring_actions(%Graph{recurring_actions: actions, last_recurring_action: last_time} = graph) do
    # calculate the time
    current_time = :os.system_time(:milli_seconds)
    elapsed_time = case last_time do
      nil -> 0
      last_time -> current_time - last_time
    end

    {actions, graph} = Scenic.Utilities.Enum.filter_map_reduce(actions, graph, fn({ref, action, args}, g_acc)->
      case call_recurring_action(g_acc, elapsed_time, action, args) do
        {:continue, %Graph{} = graph_out, args_out} -> {true, {ref, action, args_out}, graph_out }
        {:stop, %Graph{} = graph_out} ->               {false, graph_out}
      end
    end)

    # still need to put the filter_mapped actions back into the graph and save the time
    graph
    |> Map.put( :recurring_actions, actions )
    |> Map.put( :last_recurring_action, current_time )
  end

  #--------------------------------------------------------
  defp call_recurring_action(graph, elapsed_time, callback, data)
  defp call_recurring_action(graph, elapsed_time, callback, data) when is_function(callback, 3) do
    callback.(graph, elapsed_time, data)
  end
  defp call_recurring_action(graph, elapsed_time, module, data) when is_atom(module) do
    module.step(graph, elapsed_time, data)
  end
  defp call_recurring_action(graph, elapsed_time, {module, action}, data) do
    Kernel.apply(module, action, [graph, elapsed_time, data])
  end


  #============================================================================
  # update list

#  def reset_update_list(graph)
#  def reset_update_list( graph ) do
#    put_update_list( graph, [] )
#  end

#  def queue_uid_update(graph, uid)
#  def queue_uid_update(graph, uid) when is_integer(uid) do
#    graph
#    |> get_update_list()
#    |> ( &put_update_list( graph, [uid | &1] ) ).()
#  end


  #============================================================================
  # the change script is for internal use between the graph and the view_port system
  # it records the deltas of change for primitives. the idea is to send the minimal
  # amount of information to the view_port (whose rendere may be remote).


  defp put_delta_base(graph, uid, primitive)
  defp put_delta_base(%Graph{deltas: deltas} = graph, uid, primitive) do
    Map.get(deltas, uid)
    |> case do
      nil ->
        # no baseline saved for this primitive. save it.
        primitive
        |> ( &Map.put(deltas, uid, &1) ).()
        |> ( &Map.put(graph, :deltas, &1) ).()

      _   ->
        # already saved, do nothing
        graph
    end
  end

  def reset_deltas(graph)
  def reset_deltas( %Graph{} = g ),       do: Map.put(g, :deltas, %{})


  def get_delta_scripts( graph )
  def get_delta_scripts( %Graph{primitive_map: p_map, deltas: deltas} ) do
    Enum.reduce(deltas, [], fn({uid,p_original}, acc)->
      case Map.get(p_map, uid) do
        nil -> acc
        p_modified ->
          [ {uid, Primitive.delta_script(p_original, p_modified)} | acc ]
      end
    end)
  end


  #============================================================================
  # get the primitive map as a list of minimal primitives - used to send the actual
  # drawable primitives to the viewport

  def minimal( %Graph{primitive_map: p_map} ) do
    Enum.map(p_map, fn({k,p})-> { k, Primitive.minimal(p) } end)
  end




  #============================================================================
  def calculate_transforms( graph, uid, parent_tx \\ nil )
  def calculate_transforms( %Graph{} = graph, uid, nil ) do
    case get(graph, uid) do
      nil ->
        graph
      %Primitive{parent_uid: puid} ->
        calculate_transforms(
          graph,
          uid,
          get_merged_tx(graph, puid)
        )
    end
  end
  def calculate_transforms( graph, uid, parent_tx ) do
    case get(graph, uid) do
      nil -> graph
      %Primitive{module: mod, data: data} = p ->
        p = do_calculate_transforms( p, parent_tx )
        graph = put(graph, uid, p)

        # if this is a group, recurse it's children
        case mod do
          Group ->
            p_tx = Map.get(p, :local_tx, parent_tx)
            Enum.reduce(data, graph, fn(id, g) ->
              calculate_transforms( g, id, p_tx )
            end)
          _ ->
            graph
        end
      end
  end


  #--------------------------------------------------------
  defp do_calculate_transforms( %Primitive{} = p, parent_tx ) do
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
  def get_merged_tx(graph, id)
  def get_merged_tx(_, -1), do: @identity
  def get_merged_tx(graph, id) do
    case Map.get(graph, id) do
      nil -> @identity
      %{parent_uid: puid} = p ->
        merged = get_merged_tx(graph, puid)
        case Map.get(p, :local_tx) do
          nil ->  merged
          tx  ->  Matrix.mul( merged, tx )
        end
    end
  end


  #--------------------------------------------------------
  # possible optimization here by rolling into a custom traversal that keeps track
  # of the current inverse_tx without having to walk backwards to find it for each
  # primitive.
  def find_by_screen_point(%Graph{} = graph, {x,y}) when is_number(x) and is_number(y) do
    reduce(graph, nil, fn(%Primitive{module: mod, data: data} = p,acc) ->
      # get the local (or inherited) inverse tx for this primitive
      # then project the point by that matrix to get the local point
      local_point = get_inverse_tx(graph, p)
      |> Matrix.project_vector( {x, y} )

      # test if the point is in the primitive
      case mod.contains_point?( data, local_point ) do
        true  -> p
        false -> acc
      end
    end)
  end


  #--------------------------------------------------------
  # not good enough to get the inverse tx directly off of p.
  # the inverse tx can be inherited from groups above this
  defp get_inverse_tx(graph, nil), do: @identity
  defp get_inverse_tx(graph, %Primitive{parent_uid: puid} = p) do
    case Map.get(p, :inverse_tx) do
      nil -> get_inverse_tx(graph, Graph.get(graph, puid))
      tx -> tx
    end
  end

end































