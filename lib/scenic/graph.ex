#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Graph do
  @moduledoc """
  Please see [`Graph Overview`](overview_graph.html) for a high-level description.

  ## What is a Graph

  There are many types of graphs in the world of computer science. There are graphs that
  show data to a user. There are graphs that give access to databases. Graphs that link
  people to a social network.

  In Scenic, a Graph is a graph in same way that the DOM in HTML is a graph. It is a
  hierarchical tree of data that describes a set of things to draw on the screen.

  You build a graph by appending primitives (individual things to draw) to the current
  node in the tree. Nodes are represented by the Group primitive in Scenic.

  The following example builds a simple graph that displays some text, creates a group,
  then adds more text and a rounded rectangle to it.

      @graph  Scenic.Graph.build()
      |> text( "This is some text", translate: {20, 20} )
      |> group( fn(graph) ->
        graph
        |> text( "This text is in a group", translate: {200, 24} )
        |> rounded_rectangle( {400, 30}, stroke: {2, :blue})
      end, translate: {20, 100}, text_align: :center)

  There is a fair amount going on in the example above, we we will break it down.
  The first line

      @graph  Scenic.Graph.build()

  builds an empty graph with only one group as the root node. By assigning it to the 
  compile directive @group, we know that this group will be built once at compile
  time and will be very fast to access later during runtime.

  The empty graph that is returned from `build()` is then passed to `text(...)`, which
  adds a text primitive to the root group. The resulting graph from that call is then
  passed again into the `group(...)` call. This creates a new group and has calls an
  anonymous function that you can use to add primitives to the newly created group.

  Notice that the anonymous "builder" function receives a graph as its only parameter.
  This is the same graph that we are building, except that it has a marker indicating
  that new primitives added to it are inserted into the new group instead of the
  root of the graph.

  Finally, when the group is finished, a translation matrix and a `:text_align` style
  are added to it. These properties are _inherited_ by the primitives in the group.

  ## Inheritance

  An important concept to understand is that both [styles](overview_styles.html) and
  [transforms](overview_styles.html) are inherited down the graph. This means that if
  you apply a style or transform to any group (including the root), then all primitives
  contained by that group will have those properties applied to them too. This is true
  even if the primitive is nested in several groups at the same time.

      @graph  Scenic.Graph.build(font: :roboto_mono)
      |> text( "This text inherits the font", translate: {20, 20} )
      |> group( fn(graph) ->
        graph
        |> text( "This text also inherits the font", translate: {200, 24} )
        |> text( "This text overrides the font", font: :roboto )
      end, translate: {20, 100}, text_align: :center)

  Transforms, such as translate, rotate, scale, also inherit down the graph, but do
  so slightly differently than the styles. With a style, when you set a specific value
  on a primitive, that overrides the inherited value of the same type.

  With a transform, the values multiply together. This allows you to position items
  within a group relative to the origin {0,0}, then move the group as a whole, keeping
  the interior positions unchanged.

  ## Modifying a Graph

  Scenic was written specifically for Erlang/Elixir, which is a functional programming
  model with immutable data.

  As such, once you make a graph, it stays in memory unchanged - until you transform it
  via `Graph.modify/3`. Technically you never change it (that's the immutable part),
  instead Graph.modify returns a new graph with different data in it.

  [Graph.modify/3](Scenic.Graph.html#modify/3) is the single Graph function that you
  will use the most.

  For example, lets go back to our graph with the two text items in it.

      @graph Graph.build(font: :roboto, font_size: 24, rotate: 0.4)
        |> text("Hello World", translate: {300, 300}, id: :small_text)
        |> text("Bigger Hello", font_size: 40, scale: 1.5, id: :big_text)

  This time, we've assigned ids to both of the text primitives. This makes it easy to
  find and modify that primitive in the graph.

      graph =
        @graph
        |> Graph.modify( :small_text, &text(&1, "Smaller Hello", font_size: 16))
        |> Graph.modify( :big_text, &text(&1, "Bigger Hello", font_size: 60))
        |> push_graph()

  Notice that the graph is modified multiple times in the pipeline. The `push_graph/1`
  function is relatively heavy when the graph references other scenes. The recommended
  pattern is to make multiple changes to the graph and then push once at the end.

  ## Accessing Primitives

  When using a Graph, it is extremely common to access and modify primitives. They way
  you do this is by putting an id on the primitives you care about in a graph.

      @graph Graph.build()
        |> text("small text", id: :small_text)
        |> text("bit text", id: :big_text)

  When you get primitives, or modify a graph, you specify them by id. This happens
  quickly, but at a cost of using a little memory. If you aren't going to access
  a primitive, then don't assign an id to them.

  One interesting note: There is nothing saying you have to use an atom as the id.
  In fact you can use any Erlang term you want. This can be very powerful, especially
  when used to identify components...
  """

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
          add_to: non_neg_integer
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
  @doc """
  Returns the root group of a graph as a primitive.
  Deprecated. Use `Graph.get!(graph, :_root_)` instead.
  """
  @deprecated "Use Graph.get!(graph, :_root_) instead"
  @spec get_root(graph :: t()) :: Primitive.t()
  def get_root(%__MODULE__{} = graph) do
    get!(graph, :_root_)
    # Map.delete(graph.primitives[@root_uid], :styles)
  end

  # ============================================================================
  # build a new graph, starting with the given element
  @doc """
  Builds and returns an empty graph.

  Just like any primitive, you can pass in an option list of styles and transforms.
  These will be applied to the otherwise empty root group in the new graph.
  """
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
  @doc """
  Add a pre-built primitive to the current group in the graph.

  This is usually called during graph construction. When add a new Group primitive
  to a Graph, it marks the new group as the current one before calling the group's
  builder function. This is what allows you to add primitives to the right place
  in the new Group.

  Note that all primitives added to a group are appended to the draw order.
  """
  @spec add(graph :: t(), primitive :: Primitive.t()) :: t()
  def add(graph, primitive)

  def add(%__MODULE__{add_to: puid} = g, %Primitive{} = p) do
    {graph, _uid} = insert_at({g, puid}, -1, p)
    graph
  end

  # build and add new primitives
  @doc """
  Build and add a primitive to the current group in the graph.

  This is usually called during graph construction. When add a new Group primitive
  to a Graph, it marks the new group as the current one before calling the group's
  builder function. This is what allows you to add primitives to the right place
  in the new Group.

  Note that all primitives added to a group are appended to the draw order.
  """
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
  @doc """
  Permanently delete a primitive from a group by id.

  This will remove a primitive (or many if they have the same id) from a graph. It
  then returns the modified graph.

  If you delete a group from a graph, then all primitives contained by that
  group are deleted as well.
  """
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
  # KEEP THIS AROUND FOR NOW
  # might want to put it back in...
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
  defp resolve_id(graph, id)

  defp resolve_id(%__MODULE__{ids: ids}, id) do
    Map.get(ids, id, [])
  end

  # ============================================================================
  # --------------------------------------------------------
  # count all the nodes in a graph.
  @doc """
  Returns a count of all the primitives in a graph.

  The root Group counts as a primitive, so an empty graph should have a count
  of 1.
  """
  @spec count(graph :: t()) :: integer
  def count(graph)

  def count(%__MODULE__{} = graph) do
    do_reduce(graph, 0, 0, fn _, acc -> acc + 1 end)
  end

  # --------------------------------------------------------
  # count the nodes associated with an id.
  @doc """
  Returns a count of all the primitives in a graph with a specific id.
  """
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
  @doc """
  Returns a list of primitives from a graph with a specific id.
  """
  @spec get(graph :: t(), id :: any) :: list(Primitive.t())
  def get(%__MODULE__{} = graph, id) do
    graph
    |> resolve_id(id)
    |> Enum.reduce([], fn uid, acc -> [get_by_uid(graph, uid) | acc] end)
    |> Enum.reverse()
  end

  # --------------------------------------------------------
  # get a single primitive by id. Raise error if it finds any count other than one
  @doc """
  Returns a single primitive from a graph with a specific id.

  This will raise an error if either none or multiple primitives are found with
  the specified id.
  """
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

  @doc """
  Find one or more primitives in a graph via a filter function.

  Pass in a function that accepts a primitive and returns a boolean.

  Returns a list of tuples containing the matching id at the primitive.

  `[{id, primitive}]`

  __Warning:__ This function crawls the entire graph and is thus slower than
  accessing items via a fully-specified id.
  """

  @spec find(graph :: t(), (any -> as_boolean(term()))) :: list({any, Primitive.t()})
  def find(graph, finder)

  # pass in an atom based id, and it will transform all mapped uids
  def find(%__MODULE__{} = graph, finder) when is_function(finder, 1) do
    reduce(graph, [], fn p, acc ->
      Map.get(p, :id)
      |> finder.()
      |> case do
        true -> [p | acc]
        false -> acc
      end
    end)
    |> Enum.reverse()
  end

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

  @doc """
  Modify one or more primitives in a graph.

  Retrieves the primitive (or primitives) specified by id and passes them to
  a callback function. The result of the callback function is stored as the new
  version of that primitive in the graph.

  If multiple primitives match the specified id, then each is passed, in turn,
  to the callback function.

  The id can be either
  * a term to match against (fast)
  * a filter function that returns a boolean (slower)

  Examples:

      graph
      |> Graph.modify( :explicit_id, &text("Updated Text 1") )
      |> Graph.modify( {:id, 123}, &text("Updated Text 2") )
      |> Graph.modify( &match?({:id,_},&1), &text("Updated Text 3") )
  """

  @spec modify(
          graph :: t(),
          id :: any | (any -> as_boolean(term())),
          action :: (any -> Primitive.t())
        ) :: t()
  def modify(graph, id, action)

  # pass in a finder function
  def modify(%__MODULE__{} = graph, finder, action) when is_function(finder, 1) do
    graph
    |> find(finder)
    |> Enum.map(fn %{id: id} -> id end)
    |> Enum.uniq()
    |> Enum.reduce(graph, &modify(&2, &1, action))
  end

  # pass in generic term id
  def modify(%__MODULE__{} = graph, id, action) do
    graph
    |> resolve_id(id)
    |> Enum.reduce(graph, &modify_by_uid(&2, &1, action))
  end

  # @doc """
  # Modify one or more primitives in a graph via a match pattern.

  # Retrieves the primitive (or primitives) that match a pattern and passes them to
  # a callback function. The result of the callback function is stored as the new
  # version of that primitive in the graph.

  # If multiple primitives match the specified id, then each is passed, in turn,
  # to the callback function.
  # """

  # @spec modify_match(graph :: t(), pattern :: any, action :: (... -> Primitive.t())) :: t()
  # def modify_match(graph, pattern, action)

  # # pass in an atom based id, and it will transform all mapped uids
  # def modify_match(%__MODULE__{} = graph, pattern, action) do
  #   graph
  #   |> find(pattern)
  #   |> Enum.reduce(graph, &modify_by_uid(&2, &1, action))
  # end

  # ============================================================================
  # map a graph via traversal from the root node
  @doc """
  Map all primitives in a graph into a new graph.

  Crawls through the entire graph, passing each primitive to the callback function.
  The result of the callback replaces that primitive in the graph. The updated
  graph is returned.
  """

  @spec map(graph :: t(), action :: function) :: t()
  def map(%__MODULE__{} = graph, action) when is_function(action, 1) do
    do_map(graph, @root_uid, action)
  end

  # ============================================================================
  @doc """
  Map all primitives in a graph that match a specified id into a new graph.

  Crawls through the entire graph, passing each primitive to the callback function.
  The result of the callback replaces that primitive in the graph. The updated
  graph is returned.

  This is so similar to the modify function that it may be deprecated in the future.
  For now I recommend you use `Graph.modify/3` instead of this.  
  """
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
  @doc """
  Invokes action for each primitive in the graph with the accumulator.

  Iterates over all primitives in a graph, passing each into the callback function
  with an accumulator. The return value of the callback is the new accumulator.

  This is extremely similar in behaviour to Elixir's Enum.reduce function, except
  that it understands now to navigate the tree structure of a Graph.
  """

  # reduce a graph via traversal from the root node
  @spec reduce(graph :: t(), acc :: any, action :: function) :: any
  def reduce(%__MODULE__{} = graph, acc, action) when is_function(action, 2) do
    do_reduce(graph, @root_uid, acc, action)
  end

  # ============================================================================
  @doc """
  Invokes action for each primitive that matches an id in the graph with the accumulator.

  Iterates over all primitives that match a specified id, passing each into the callback
  function with an accumulator.

  This is extremely similar in behaviour to Elixir's Enum.reduce function, except
  that it understands now to navigate the tree structure of a Graph.
  """
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
