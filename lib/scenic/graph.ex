#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Graph do
  @moduledoc false

  alias Scenic.Primitive
  alias Scenic.Primitive.Group

  # make reserved uids, 3 or shorter to avoid potential conflicts
  @root_uid 0

  @default_max_depth 128

  @default_font :roboto
  @default_font_size 24

  @root_id :_root_

  defstruct primitives: %{}, ids: %{}, next_uid: 1, add_to: 0

  @type t :: %__MODULE__{
          primitives: map,
          ids: map,
          next_uid: pos_integer,
          add_to: pos_integer
        }

  @type key :: {:graph, Scenic.Scene.ref(), any}

  # ===========================================================================
  # define a policy error here - not found or something like that
  defmodule Error do
    @moduledoc false
    defexception message: "Graph was unable to perform the operation",
                 # expecting more appropriate messages when raising this
                 primitive: nil,
                 style: nil
  end

  @err_msg_depth "Graph too deep. Possible circular reference!"
  @err_msg_depth_option "The :max_depth option must be a positive integer"
  # @err_msg_group "Can only add primitives to Group nodes"
  @err_msg_put "Graph.put can only update existing items."
  @err_msg_get_id_one "Graph.get! expected to find one and only one element"

  # ============================================================================
  # access to the raw graph fields
  # concentrate all knowledge of the internal structure of the graph tuple here

  @spec get_root(graph :: t()) :: Primitive.t()
  def get_root(%__MODULE__{} = graph) do
    Map.delete(graph.primitives[@root_uid], :styles)
  end

  # ============================================================================
  # build a new graph, starting with the given element
  @spec build(opts :: keyword) :: t()
  def build(opts \\ []) do
    opts = handle_options(opts)

    []
    |> Group.build(opts)
    |> new()
    |> set_id(opts[:id])
    |> set_max_depth(opts[:max_depth])
  end

  # ============================================================================
  # add a pre-built primitive
  @spec add(graph :: t(), primitive :: Primitive.t()) :: t()
  def add(graph, primitive)

  def add(%__MODULE__{add_to: puid} = g, %Primitive{} = p) do
    {graph, _uid} = insert_at({g, puid}, -1, p)
    graph
  end

  # build and add new primitives
  @spec add(graph :: t(), module :: atom, data :: any, opts :: keyword) :: t()
  def add(graph, primitive_module, primitive_data, opts \\ [])

  def add(%__MODULE__{add_to: puid} = g, Group, builder, opts) when is_function(builder, 1) do
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

  def add(%__MODULE__{add_to: puid} = g, mod, data, opts) when is_atom(mod) do
    p = mod.build(data, opts)
    {graph, _uid} = insert_at({g, puid}, -1, p, opts)
    graph
  end

  # ============================================================================
  # delete a primitive/s from a graph
  @spec delete(graph :: t(), id :: any) :: t()
  def delete(%__MODULE__{primitives: primitives, ids: ids} = graph, id) do
    # resolve the id into a list of uids
    uids = Map.get(ids, id, [])

    # delete each uid
    primitives =
      Enum.reduce(uids, primitives, fn uid, prims ->
        # get the uid of the parent group
        %Primitive{parent_uid: puid} = prims[uid]

        prims[puid]
        |> remove_reference_from_parent(prims, uid, puid)
        # delete the primitive itself
        |> Map.delete(uid)
      end)

    # delete the ids
    ids = Map.delete(ids, id)

    # reassemble the graph
    %{graph | primitives: primitives, ids: ids}
  end

  # no parent
  defp remove_reference_from_parent(-1, prims, _uid, _puid), do: prims

  defp remove_reference_from_parent(
         %Primitive{module: Group, data: children} = p,
         prims,
         uid,
         puid
       ) do
    children = Enum.reject(children, fn cuid -> cuid == uid end)
    Map.put(prims, puid, %{p | data: children})
  end

  # ============================================================================
  # add a pre-built primitive to an existing group in a graph
  # def add_to( graph, id, primitive )

  # def add_to( %Graph{} = graph, id, p ) when not is_integer(id) do
  #   get_by_uid(graph, id)
  #   |> Enum.reduce( graph, fn(uid, g) ->
  #     case get_by_uid(g, uid) do
  #       %Primitive{module: Group} ->
  #         {graph, _uid} = insert_at({g, uid}, -1, p)
  #         graph
  #       _ ->
  #         raise @err_msg_group
  #     end
  #   end)
  # end

  # build and add a new primitive to an existing group in a graph
  # def add_to( graph, id, primitive_module, primitive_data, opts \\ [])
  # def add_to( %Graph{add_to: puid} = graph, id, primitive_module, primitive_data, opts) when not is_integer(id) do
  #   get_id(graph, id)
  #   |> Enum.reduce( graph, fn(uid, g) ->
  #     case get_by_uid(graph, uid) do
  #       %Primitive{module: Group} ->
  #         g
  #         # set the new group as the add_to target
  #         |> Map.put(:add_to, uid)
  #         # add the new primitive
  #         |> add( primitive_module, primitive_data, opts )
  #       _ ->
  #         raise @err_msg_group
  #     end
  #   end)
  #   # restore the add_to back to whatever it was before
  #   |> Map.put(:add_to, puid)
  # end

  # ============================================================================
  # put an element by uid - internal use
  defp put_by_uid(graph, uid, primitive)

  defp put_by_uid(%__MODULE__{primitives: primitives} = graph, uid, primitive)
       when is_integer(uid) do
    case get_by_uid(graph, uid) do
      nil ->
        raise Error, message: @err_msg_put

      _ ->
        Map.put(
          graph,
          :primitives,
          Map.put(primitives, uid, primitive)
        )
    end
  end

  # handle options helper
  defp handle_options(opts) do
    font = opts[:font] || @default_font
    font_size = opts[:font_size] || @default_font_size

    Keyword.merge(opts, font: font, font_size: font_size)
  end

  # new
  defp new(root) do
    %__MODULE__{
      primitives: %{@root_uid => root},
      # pre-map the root
      ids: %{@root_id => [0]}
    }
  end

  # Set Graph ID
  defp set_id(%__MODULE__{} = graph, nil), do: graph
  defp set_id(%__MODULE__{} = graph, id), do: map_id_to_uid(graph, id, @root_uid)

  # Set Graph max depth
  defp set_max_depth(%__MODULE__{} = graph, nil), do: graph

  defp set_max_depth(%__MODULE__{} = graph, max) when is_integer(max) and max > 0,
    do: Map.put(graph, :max_depth, max)

  defp set_max_depth(_, _), do: raise(Error, message: @err_msg_depth_option)

  # ============================================================================
  # create an entry in the ids
  defp map_id_to_uid(graph, id, uid)

  defp map_id_to_uid(%__MODULE__{ids: ids} = graph, id, uid) when is_integer(uid) do
    Map.put(
      graph,
      :ids,
      do_map_id_to_uid(ids, id, uid)
    )
  end

  defp do_map_id_to_uid(%{} = ids, id, uid) when is_integer(uid) do
    uid_list = Enum.uniq([uid | Map.get(ids, id, [])])
    Map.put(ids, id, uid_list)
  end

  # ============================================================================
  # remove an entry in the ids
  # defp unmap_id_to_uid(graph, id, uid)
  # defp unmap_id_to_uid(graph, nil, _uid),  do: graph
  # defp unmap_id_to_uid(graph, _id, nil),   do: graph
  # defp unmap_id_to_uid(%Graph{ids: ids} = graph, id, uid) when is_integer(uid) do

  #   uid_list = Map.get(ids, id, [])
  #     |> Enum.reject(fn(mapped_uid)-> mapped_uid == uid end)

  #   ids = case uid_list do
  #     []   -> Map.delete(ids, id)
  #     uids -> Map.put(ids, id, uids)
  #   end

  #   %{graph | ids: ids}
  # end

  # ============================================================================
  defp resolve_id(graph, id)

  defp resolve_id(%__MODULE__{ids: ids}, id) do
    Map.get(ids, id, [])
  end

  # ============================================================================
  # --------------------------------------------------------
  # count all the nodes in a graph.
  @spec count(graph :: t()) :: integer
  def count(graph)

  def count(%__MODULE__{} = graph) do
    do_reduce(graph, 0, 0, fn _, acc -> acc + 1 end)
  end

  # --------------------------------------------------------
  # count the nodes associated with an id.
  @spec count(graph :: t(), id :: any) :: integer
  def count(graph, id)

  def count(%__MODULE__{ids: ids}, id) do
    ids
    |> Map.get(id, [])
    |> Enum.count()
  end

  # ============================================================================
  # get an element by uid. Used internally
  defp get_by_uid(graph, uid, default \\ nil)

  defp get_by_uid(%__MODULE__{primitives: primitives}, uid, default) when is_integer(uid) do
    Map.get(primitives, uid, default)
  end

  # --------------------------------------------------------
  # get an element by uid. Raise error if not there
  defp get_by_uid!(graph, uid)

  defp get_by_uid!(%__MODULE__{primitives: primitives}, uid) do
    Map.fetch!(primitives, uid)
  end

  # ============================================================================
  # get a list of primitives by id
  @spec get(graph :: t(), id :: any) :: list(Primitive.t())
  def get(%__MODULE__{} = graph, id) do
    graph
    |> resolve_id(id)
    |> Enum.reduce([], fn uid, acc -> [get_by_uid(graph, uid) | acc] end)
    |> Enum.reverse()
  end

  # --------------------------------------------------------
  # get a single primitive by id. Raise error if it finds any count other than one
  @spec get!(graph :: t(), id :: any) :: Primitive.t()
  def get!(%__MODULE__{} = graph, id) do
    case resolve_id(graph, id) do
      [uid] -> get_by_uid(graph, uid)
      _ -> raise Error, message: @err_msg_get_id_one
    end
  end

  # ============================================================================
  # insert an element into the graph under the given parent
  # returns the uid and transformed graph with the added element
  # {graph, uid}

  # NOTE: not sure this will stay private. May need to expose if I need to
  # bring back templates

  defp insert_at(graph_and_parent, index, element, opts \\ [])

  # --------------------------------------------------------
  # main version - force it to be a new item via -1 parent id
  defp insert_at(
         {%__MODULE__{primitives: primitives} = graph, parent_uid},
         index,
         %Primitive{} = primitive,
         _opts
       )
       when is_integer(index) do
    # uid for the new item
    uid = next_uid = graph.next_uid

    # prepare the primitive
    primitive = Map.put(primitive, :parent_uid, parent_uid)

    # add the element to the primitives map, setting parent_uid into place
    primitives = Map.put(primitives, uid, primitive)
    graph = Map.put(graph, :primitives, primitives)

    # if a parent is requested, reference the element from the parent at the right position
    graph =
      case parent_uid do
        -1 ->
          graph

        puid ->
          p_map = graph.primitives

          p_map
          |> Map.get(puid)
          |> Group.insert_at(index, uid)
          |> (&Map.put(p_map, puid, &1)).()
          |> (&Map.put(graph, :primitives, &1)).()
      end

    # if the incoming primitive has an id set on it, map it to the uid
    graph =
      case Map.get(primitive, :id) do
        nil -> graph
        id -> map_id_to_uid(graph, id, uid)
      end

    # increment the next uid and gen the completed graph
    {Map.put(graph, :next_uid, next_uid + 1), uid}
  end

  # KEEP THIS AROUND FOR NOW
  # In case I want to reintroduce templates.
  #   #--------------------------------------------------------
  #   # insert a template, which is a graph that has relative uids
  #   # can't just merge the various maps. map the incoming graph into an id space that
  #   # starts with next_uid, then bump up next_uid to account for everything in the updated graph
  #   defp insert_at({%Graph{primitives: p_map, ids: ids, next_uid: next_uid} = graph, parent_uid},
  #       index,
  #       %Graph{primitives: t_p_map, ids: t_ids, next_uid: t_next_uid} = t_graph,
  #       opts) when is_integer(index) do
  # IO.puts "insert_at template"
  #     # uid for the new item
  #     uid = next_uid

  #     # start by mapping and adding the primitives to the receiver
  #     p_map = Enum.reduce(t_p_map, p_map, fn({uid, primitive}, acc_g) ->
  #       # map the uid
  #       uid = uid + next_uid

  #       # map the parent id
  #       primitive = case Primitive.get_parent_uid(primitive) do
  #         -1 -> primitive              # not in the tree. no change
  #         parent_id -> Primitive.put_parent_uid(primitive, parent_id + next_uid)
  #       end

  #       # if this is a group, increment its children's references
  #       primitive = case Primitive.get_module(primitive) do
  #         Group ->  Group.increment( primitive, next_uid )
  #         _ ->      primitive           # not a Group, do nothing.
  #       end

  #       # finally, update the internal uid of the primitive
  #       primitive = Primitive.put_uid( primitive, uid )

  #       # add the mapped primitive to the receiver's p_map
  #       Map.put(acc_g, uid, primitive)
  #     end)

  #     # if the incoming tree was requested to be inserted into an existing group, then fix that up too
  #     p_map = if (parent_uid >= 0) do
  #       # we know the root of the added tree is at next_uid
  #       p_map = Map.get(p_map, next_uid)
  #       |> Primitive.put_parent_uid( parent_uid )
  #       |> ( &Map.put(p_map, next_uid, &1) ).()

  #       # also need to add the tree as a child to the parent
  #       Map.get( p_map, parent_uid )
  #       |> Group.insert_at(index, next_uid)
  #       |> ( &Map.put(p_map, parent_uid, &1) ).()
  #     else
  #       p_map       # do nothing
  #     end

  #     # offset the t_ids, mapping into ids as we go
  #     ids = Enum.reduce(t_ids, ids, fn({id,uid_list}, acc_idm) ->
  #       Enum.reduce(uid_list, acc_idm, fn(uid, acc_acc_idm) ->
  #         do_map_id_to_uid( acc_acc_idm, id, uid + next_uid)
  #       end)
  #     end)

  #     # if an id was given, map it to the uid
  #     ids = case opts[:id] do
  #       nil ->  ids
  #       id ->   do_map_id_to_uid(ids, id, uid)
  #     end

  #     # merge any requested inputs - is optional, so must work if not actually there
  #     input = [
  #       Map.get(graph, :input, []),
  #       Map.get(t_graph, :input, []),
  #     ]
  #     |> List.flatten()
  #     |> Enum.uniq()

  #     # offset the next_uid
  #     next_uid = next_uid + t_next_uid

  #     # return the merged graph
  #     graph = graph
  #     |> Map.put(:primitives, p_map)
  #     |> Map.put(:ids, ids)
  #     |> Map.put(:next_uid, next_uid)
  #     # |> calculate_transforms( uid )

  #     # add the input in only if there is some to add in
  #     graph = case input do
  #       []    -> Map.delete(graph, :input)
  #       input -> Map.put(graph, :input, input)
  #     end

  #     {graph, uid}
  #   end

  # --------------------------------------------------------
  # insert at the root - graph itself passed in
  # defp insert_at(%Graph{} = graph, index, element, opts) do
  #   insert_at({graph, @root_uid}, index, element, opts)
  # end

  # ============================================================================
  # apis to modify the specified elements in a graph
  # this is different from map in that it does not walk the tree below the given uid

  # --------------------------------------------------------
  # transform a single primitive by uid
  # pass in a list of uids to transform

  defp modify_by_uid(graph, uid, action) when is_integer(uid) and is_function(action, 1) do
    case get_by_uid(graph, uid) do
      # not found - do nothing
      nil ->
        graph

      # transform
      p_original ->
        case action.(p_original) do
          # no change. do nothing
          ^p_original ->
            graph

          # change. record it
          %Primitive{module: mod} = p_modified ->
            # filter the styles
            styles =
              p_modified
              |> Map.get(:styles, %{})
              |> mod.filter_styles()

            p_modified = Map.put(p_modified, :styles, styles)

            graph
            |> put_by_uid(uid, p_modified)

          _ ->
            raise Error, message: "Action must return a valid primitive"
        end
    end
  end

  @spec modify(graph :: t(), id :: any, action :: (... -> Primitive.t())) :: t()
  def modify(graph, id, action)

  # pass in an atom based id, and it will transform all mapped uids
  def modify(%__MODULE__{} = graph, id, action) do
    graph
    |> resolve_id(id)
    |> Enum.reduce(graph, &modify_by_uid(&2, &1, action))
  end

  # ============================================================================
  # map a graph via traversal from the root node
  @spec map(graph :: t(), action :: function) :: t()
  def map(%__MODULE__{} = graph, action) when is_function(action, 1) do
    do_map(graph, @root_uid, action)
  end

  # ============================================================================
  # map a graph, but only those elements mapped to the id
  @spec map(graph :: t(), id :: any, action :: function) :: t()
  def map(%__MODULE__{} = graph, id, action) when is_function(action, 1) do
    # resolve the id into a list of uids
    uids = resolve_id(graph, id)

    # map those elements via reduction
    Enum.reduce(uids, graph, fn uid, acc ->
      # retrieve and map this node
      acc
      |> get_by_uid!(uid)
      |> action.()
      |> (&put_by_uid(acc, uid, &1)).()
    end)
  end

  # --------------------------------------------------------
  # map a graph via traversal starting at the node named by uid
  defp do_map(graph, uid, action, depth_remaining \\ nil)

  defp do_map(graph, uid, action, nil) do
    max_depth = Map.get(graph, :max_depth, @default_max_depth)
    do_map(graph, uid, action, max_depth)
  end

  defp do_map(_, _, _, 0), do: raise(Error, message: @err_msg_depth)

  defp do_map(graph, uid, action, depth_remaining) do
    # retrieve this node
    primitive = get_by_uid!(graph, uid)

    # retrieve and map this node
    graph =
      primitive
      |> action.()
      |> (&put_by_uid(graph, uid, &1)).()

    # if this is a group, map its children
    case primitive.module do
      Group ->
        # map its children by reducing the graph
        Enum.reduce(Primitive.get(primitive), graph, fn uid, acc ->
          do_map(acc, uid, action, depth_remaining - 1)
        end)

      # do nothing
      _ ->
        graph
    end
  end

  # ============================================================================
  # reduce a graph via traversal from the root node
  @spec reduce(graph :: t(), acc :: any, action :: function) :: any
  def reduce(%__MODULE__{} = graph, acc, action) when is_function(action, 2) do
    do_reduce(graph, @root_uid, acc, action)
  end

  # ============================================================================
  # reduce a graph, but only for nodes mapped to the given id
  @spec reduce(graph :: t(), id :: any, acc :: any, action :: function) :: any
  def reduce(%__MODULE__{} = graph, id, acc, action) when is_function(action, 2) do
    # resolve the id into a list of uids
    uids = resolve_id(graph, id)

    # reduce on that list of uids
    Enum.reduce(uids, acc, fn uid, acc ->
      graph
      |> get_by_uid!(uid)
      |> action.(acc)
    end)
  end

  # --------------------------------------------------------
  # do_reduce is where max_depth is honored
  defp do_reduce(graph, uid, acc, action, depth_remaining \\ nil)

  defp do_reduce(graph, uid, acc, action, nil) do
    max_depth = Map.get(graph, :max_depth, @default_max_depth)
    do_reduce(graph, uid, acc, action, max_depth)
  end

  defp do_reduce(_, _, _, _, 0), do: raise(Error, message: @err_msg_depth)

  defp do_reduce(graph, uid, acc, action, depth_remaining) when depth_remaining > 0 do
    # retrieve this node
    primitive = get_by_uid!(graph, uid)

    # if this is a group, reduce its children
    acc =
      case primitive.module do
        Group ->
          Enum.reduce(Primitive.get(primitive), acc, fn uid, acc ->
            do_reduce(graph, uid, acc, action, depth_remaining - 1)
          end)

        # do nothing
        _ ->
          acc
      end

    # reduce the node itself, returns the final accumulator
    action.(primitive, acc)
  end

  # ============================================================================
  @doc false
  @spec style_stack(graph :: t(), uid :: integer) :: map
  def style_stack(%__MODULE__{primitives: p_map} = graph, uid) when is_integer(uid) do
    # get the target primitive
    case p_map[uid] do
      nil ->
        %{}

      %{parent_uid: -1} = p ->
        Primitive.get_styles(p)

      %{parent_uid: puid} = p ->
        # merge the local styles into the parent styles
        graph
        |> style_stack(puid)
        |> Map.merge(Primitive.get_styles(p))
    end
  end
end
