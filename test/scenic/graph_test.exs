#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.GraphTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Group
  alias Scenic.Primitive.Text
  alias Scenic.Primitive.Rectangle
  alias Scenic.Primitive.Line
  alias Scenic.Primitive.Style
  alias Scenic.Template.Button

  alias Scenic.Primitive.Transform


#  import IEx

  @end_id_ref_marker      <<0xff, 0xff, 0xff, 0xff>>
  
  @root_uid               0

  @tx_pin                 {10,11}
  @tx_rot                 0.1
  @transform              %{pin: @tx_pin, rotate: @tx_rot}

  @empty_group            Group.build()

  @empty_root             Group.build() |> Primitive.put_uid(@root_uid)
  @primitive_map          %{ @root_uid => @empty_root }
  @id_map                 %{}
  @graph_empty            Graph.build()


  @filter_graph Graph.build()
    |>Primitive.Group.add_to_graph( fn(g) ->
      Rectangle.add_to_graph( g, {{0, 0}, 100, 200}, id: :rect )
    end, id: "group")

#      Rectangle.add_to_graph( g, {{0, 0}, 100, 200}, id: :rect )






  @find_outer_text  Text.build({{10,10}, "Some sample text"}, id: :outer_text, tags: ["outer", "text", :text_atom, :on_root] )
  @find_outer_line  Line.build({{10,10}, {100, 100}}, id: :outer_line, tags: ["outer", "line"] )
  @find_outer_btn   Button.build("Continue", id: :outer_btn, tags: ["outer"] )

  @find_inner_text  Text.build({{10,10}, "inner text"}, id: :inner_text, tags: ["inner", "text", :text_atom] )
  @find_inner_line  Line.build({{10,10}, {100, 100}}, id: :inner_line, tags: ["inner", "line"], state: {:abc, 123} )

  @graph_find       Graph.build()
    |> Graph.put_new( 0, @find_outer_text )
    |> Graph.put_new( 0, @find_outer_line )
    |> Graph.put_new( 0, @find_outer_btn )
    |> Graph.put_new( 0, Group.build(id: :group), fn(graph, parent_uid) ->
        graph
        |> Graph.put_new( parent_uid, @find_inner_text )
        |> Graph.put_new( parent_uid, @find_inner_line )
      end)

  @graph_ordered Graph.build()
      |> Graph.put_new( 0, Line.build({{10,10}, {100, 100}}, id: :line, tags: ["first"] ) )
      |> Graph.put_new( 0, Text.build({{20,20}, "text"}, id: :text ) )
      |> Graph.put_new( 0, Line.build({{30,30}, {300, 300}}, id: :line, tags: ["second"] ) )



  #============================================================================
  # access to the basics. These concentrate knowledge of the internal format
  # into just a few functions

  test "get_root returns the root node" do
    assert Graph.get_root(@graph_empty) == @empty_root
  end

  test "get_primitive_map returns primitive_map" do
    assert Graph.get_primitive_map(@graph_empty) == @primitive_map
  end

  test "get_id_map returns the id_map" do
    assert Graph.get_id_map(@graph_empty) == @id_map
  end

  test "get_next_uid uses the uid_tracker to find the next available uid" do
    assert Graph.get_next_uid( @graph_empty ) == 1
  end

  test "get_update_list returns the list of uids to update" do
    graph = Graph.put_update_list(@graph_empty, [1,2,3])
    assert Graph.get_update_list( graph ) == [1,2,3]
  end


  #============================================================================
  # build
  test "build builds a new graph" do
    %Graph{} = Graph.build()
  end

  test "build tells the root node that it has uid 0" do
    root = Graph.build() |> Graph.get(@root_uid)
    assert Primitive.get_uid( root ) == @root_uid
  end

  test "build builds accepts an id for the root node " do
    graph = Graph.build(id: :test_root)
    assert Graph.get_id_map(graph) == %{test_root: [0]}
  end

  test "new graphs start with id :root pointing to uid 0" do
    graph = Graph.build()
    assert Graph.count(graph) == 1
    assert Graph.get_id_map(graph) == %{}
  end

  test "build accepts and uses a builder callback" do
    assert Graph.build( builder: fn({graph, parent_id}) ->
      assert graph == @graph_empty
      assert parent_id == @root_uid
      {graph, parent_id}
    end) == @graph_empty
  end


  #============================================================================
  # queue_uid_update(graph, uid)

  test "queue_uid_update adds a uid to the update list" do
    graph = Graph.build()
    assert Graph.get_update_list( graph ) == []

    graph = Graph.queue_uid_update(graph, 123)
    assert Graph.get_update_list( graph ) == [123]
  end

  test "queue_uid_update rejects atoms as uids" do
    assert_raise FunctionClauseError, fn ->
      Graph.queue_uid_update(@graph_empty, :an_atom)
    end
  end

  #============================================================================
  # reset_update_list(graph)
  test "reset_update_list resets the update list" do
    graph = Graph.build()
    |> Graph.put_update_list([1,2,3,4,5])
    assert Graph.get_update_list( graph ) == [1,2,3,4,5]

    graph = Graph.reset_update_list( graph )
    assert Graph.get_update_list( graph ) == []
  end


  #============================================================================
  # map_id_to_uid(graph, id, uid)

  test "map_id_to_uid creates a new uid map for an id" do
    graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
    assert Graph.get_id_map(graph) == %{ test_id: [1] }
  end

  test "map_id_to_uid adds a new uid to an existing id map" do
    graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
      |> Graph.map_id_to_uid(:test_id, 2)
    assert Graph.get_id_map(graph) == %{ test_id: [2, 1] }
  end

  test "map_id_to_uid keeps the list uniq" do
    graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
      |> Graph.map_id_to_uid(:test_id, 1)
      |> Graph.map_id_to_uid(:test_id, 2)
      |> Graph.map_id_to_uid(:test_id, 2)
      |> Graph.map_id_to_uid(:test_id, 1)
    assert Graph.get_id_map(graph) == %{ test_id: [1,2]}
  end

  test "map a list of ids to a single uid" do
    graph = Graph.map_id_to_uid(@graph_empty, [:id1, :id2, :id3], 1)
    assert Graph.get_id_map(graph) == %{ id1: [1], id2: [1], id3: [1] }
  end

  #============================================================================
  # unmap_id_to_uid(graph, id, uid)
  test "unmap_id_to_uid removes a uid map" do
    graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
      |> Graph.map_id_to_uid(:test_id, 2)
      |> Graph.map_id_to_uid(:test_id, 3)
      |> Graph.unmap_id_to_uid(:test_id, 2)
    assert Graph.get_id_map(graph) == %{ test_id: [3, 1] }
  end

  test "unmap_id_to_uid does nothing if id is nil" do
    graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
      |> Graph.map_id_to_uid(:test_id, 2)
      |> Graph.map_id_to_uid(:test_id, 3)
      |> Graph.unmap_id_to_uid(nil, 2)
    assert Graph.get_id_map(graph) == %{ test_id: [3, 2, 1] }
  end

  test "unmap_id_to_uid does nothing if id is not mapped" do
    graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
      |> Graph.map_id_to_uid(:test_id, 2)
      |> Graph.map_id_to_uid(:test_id, 3)
      |> Graph.unmap_id_to_uid(:banana, 1)
    assert Graph.get_id_map(graph) == %{ test_id: [3, 2, 1] }
  end

  test "unmap_id_to_uid does nothing if uid is not in id map" do
    graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
      |> Graph.map_id_to_uid(:test_id, 2)
      |> Graph.map_id_to_uid(:test_id, 3)
      |> Graph.unmap_id_to_uid(:test_id, 123)
    assert Graph.get_id_map(graph) == %{ test_id: [3, 2, 1] }
  end


  #============================================================================
  # resolve_id
  test "resolve_id returns an uid in a list for a given id" do
    graph = Graph.map_id_to_uid(@graph_empty, :one, 1)
      |> Graph.map_id_to_uid(:two, 2)
      |> Graph.map_id_to_uid(:two, 4)
      |> Graph.map_id_to_uid(:two, 8)
    assert Graph.resolve_id(graph, :one) == [1]
  end

  test "resolve_id returns multiple uids in a list for a given id" do
    graph = Graph.map_id_to_uid(@graph_empty, :one, 1)
      |> Graph.map_id_to_uid(:two, 2)
      |> Graph.map_id_to_uid(:two, 4)
      |> Graph.map_id_to_uid(:two, 8)
    assert Graph.resolve_id(graph, :two) == [8, 4, 2]
  end

  test "resolve_id returns an empty list  for a missing id" do
    graph = Graph.map_id_to_uid(@graph_empty, :one, 1)
      |> Graph.map_id_to_uid(:two, 2)
      |> Graph.map_id_to_uid(:two, 4)
      |> Graph.map_id_to_uid(:two, 8)
    assert Graph.resolve_id(graph, :missing) == []
  end

  #============================================================================
  # count - all nodes
  test "count returns 1 if only the root node exists" do
    assert Graph.count(@graph_empty) == 1
  end

  test "count counts the items in the graph" do
    assert Enum.count( Graph.get_primitive_map(@graph_find) ) == 9
    assert Graph.count(@graph_find) == 9
  end

  test "count ignores primitives that are not in the hierarchy (parent == -1)" do
    graph = Graph.put_new(@graph_find, -1, Text.build({{10,10}, "Outside Tree"}) )
    assert Enum.count( Graph.get_primitive_map(graph) ) == 10
    assert Graph.count(graph) == 9
  end

  test "count includes everything if -1 is requested" do
    graph = Graph.put_new(@graph_find, -1, Text.build({{10,10}, "Outside Tree"}) )
    assert Enum.count( Graph.get_primitive_map(graph) ) == 10
    assert Graph.count(graph, -1) == 10
  end

  test "count counts the primitives with a given id" do
    assert Graph.count(@graph_ordered, :missing) == 0
    assert Graph.count(@graph_ordered, :text) == 1
    assert Graph.count(@graph_ordered, :line) == 2
  end

  #============================================================================
  # count - id nodes
  test "count by id returns the number of uids associated with an id" do
    graph = Graph.map_id_to_uid(@graph_empty, :one, 1)
      |> Graph.map_id_to_uid(:two, 2)
      |> Graph.map_id_to_uid(:two, 4)
      |> Graph.map_id_to_uid(:three, 3)
      |> Graph.map_id_to_uid(:three, 6)
      |> Graph.map_id_to_uid(:three, 9)

    assert Graph.count(graph, :one) == 1
    assert Graph.count(graph, :two) == 2
    assert Graph.count(graph, :three) == 3
    assert Graph.count(graph, :missing) == 0
  end

  #============================================================================
  # count - uid root
  test "count by root uid returns the number of elements in the tree via recursion" do
    {graph, _} = Graph.insert_at(@graph_empty, -1, @empty_group)
    {graph, uid_1} = Graph.insert_at(graph, -1, @empty_group)
    {graph, _} = Graph.insert_at({graph, uid_1}, -1, @empty_group)
    {graph, _} = Graph.insert_at(graph, -1, @empty_group)

    assert Graph.count(graph, @root_uid) == 5
  end

  test "count with uid returns the number of elements in the tree via recursion starting at uid" do
    {graph, _} = Graph.insert_at(@graph_empty, -1, @empty_group)
    {graph, uid_1} = Graph.insert_at(graph, -1, @empty_group)
    {graph, _} = Graph.insert_at({graph, uid_1}, -1, @empty_group)
    {graph, _} = Graph.insert_at(graph, -1, @empty_group)

    assert Graph.count(graph, uid_1) == 2
  end


  #============================================================================
  # put_new( graph, parent, primitive_or_fn )
  test "put_new adds a new primitive to a graph under the designated parent uid" do
    # first add an inner group under the root
    graph = Graph.put_new(@graph_empty, @root_uid, Group.build(id: :inner_group))
    [inner_uid] = Graph.resolve_id(graph, :inner_group)
    assert inner_uid == 1

    # next add a line to the inner group
    line = Line.build({{0,0},{10,10}}, id: :line)
    graph = Graph.put_new(graph, inner_uid, line)
    [line_uid] = Graph.resolve_id(graph, :line)
    assert line_uid == 2

    # finally, make sure the line is a child of the inner group
    inner_group = Graph.get(graph, inner_uid)
    assert Enum.member?(Group.get(inner_group), line_uid)
  end


  test "put_new adds a new primitive outside the graph if parent_uid is -1" do
    # add a line outside the graph
    line = Line.build({{0,0},{10,10}}, id: :line)
    graph = Graph.put_new(@graph_empty, -1, line)
    [line_uid] = Graph.resolve_id(graph, :line)
    assert line_uid == 1

    # finally, make sure the line is a child of the inner group
    root = Graph.get_root(graph)
    assert Group.get(root) == []
  end

  test "put_new uses the post_build callback with the added primitive's uid" do
    text = "This is some text."
    graph = Graph.put_new(@graph_empty, @root_uid, Text.build({{10, 16}, text}, id: :text), fn(g, uid) ->
      p = Graph.get(g, uid)
      assert Text.get(p) == {{10, 16}, text}
      g
    end)
    [uid] = Graph.resolve_id(graph, :text)
    p = Graph.get(graph, uid)
    assert Text.get(p) == {{10, 16}, text}
  end

  #============================================================================
  # put(graph, uid, primitive)

  test "put overwrites a primitive by uid" do
    line = Line.build({{0,0},{10,10}}, id: :line)
    graph = Graph.put_new(@graph_empty, -1, line)
    [uid] = Graph.resolve_id(graph, :line)
    assert Graph.get(graph, uid) |> Line.get() == {{0,0},{10,10}}

    graph = Graph.put(graph, uid, Line.build({{21,22},{123,124}}) )
    assert Graph.get(graph, uid) |> Line.get() == {{21,22},{123,124}}
  end

  test "put raises if the uid is not already a primitive" do
    assert_raise Graph.Error, fn ->
      Graph.put(@graph_empty, 123, Line.build({{21,22},{123,124}}))
    end
  end


  #============================================================================
  # get
  test "get gets the root by uid" do
    assert Graph.get(@graph_empty, @root_uid) == @empty_root
  end

  test "get gets a primnitve by uid" do
    empty_group = Primitive.do_put_id(@empty_group, :one)
    {graph, uid} = Graph.insert_at(@graph_empty, -1, empty_group)
    p = Graph.get(graph, uid)
    assert Primitive.get_parent_uid(p) == 0
    assert Primitive.get_module(p) == Group
    assert Primitive.get_data(p) == @end_id_ref_marker
  end

  test "get returns nil for missing if no default specified" do
    assert Graph.get(@graph_empty, 123) == nil
  end

  test "get returns default if missing" do
    assert Graph.get(@graph_empty, 123, :missing) == :missing
  end


  #============================================================================
  # get by developer id
  test "get gets an element by id" do
    empty_group = Primitive.do_put_id(@empty_group, :one)
    {graph, _uid} = Graph.insert_at(@graph_empty, -1, empty_group)
    [p] = Graph.get(graph, :one)
    assert Primitive.get_parent_uid(p) == 0
    assert Primitive.get_module(p) == Group
    assert Primitive.get_data(p) == @end_id_ref_marker
  end

  test "get gets multiple elements by id" do
    empty_group = Primitive.do_put_id(@empty_group, :one)

    {graph, uid_1} = Graph.insert_at(@graph_empty, -1, empty_group)
    {graph, uid_2} = Graph.insert_at({graph, uid_1}, -1, empty_group)

    [a, b] = Graph.get(graph, :one)

    assert Primitive.get_uid(a) == uid_1
    assert Primitive.get_parent_uid(a) == 0
    assert Primitive.get_module(a) == Group
    assert Primitive.get_data(a) == <<2, 0, 0, 0, @end_id_ref_marker>>

    assert Primitive.get_uid(b) == uid_2
    assert Primitive.get_parent_uid(b) == uid_1
    assert Primitive.get_module(b) == Group
    assert Primitive.get_data(b) == @end_id_ref_marker
  end


  #============================================================================
  # get!
  # similar to get, but no default. raises if not there
  test "get! gets the root by uid" do
    assert Graph.get!(@graph_empty, @root_uid) == @empty_root
  end

  test "get! gets an element by uid" do
    empty_group = Primitive.do_put_id(@empty_group, :one)
    {graph, uid} = Graph.insert_at(@graph_empty, -1, empty_group)
    p = Graph.get!(graph, uid)
    assert Primitive.get_parent_uid(p) == 0
    assert Primitive.get_module(p) == Group
    assert Primitive.get_data(p) == @end_id_ref_marker
  end

  test "get! raises if the uid is not present" do
    assert_raise KeyError, fn ->
      Graph.get!(@graph_empty, 123)
    end
  end


  #============================================================================
  # get_id
  # returns a list of objects with the given id
  test "get_id returns a list of primitives with the given id" do
    [first_uid, second_uid] = Graph.resolve_id(@graph_ordered, :line)
    [first, second] = Graph.get_id(@graph_ordered, :line)

    assert Primitive.get_uid(first) == first_uid
    assert Primitive.get_uid(second) == second_uid
  end


  #============================================================================
  # get_id_one returns a single object indicated by id

  test "get_id_one returns a single primitive matching the id" do
    text = Graph.get_id_one(@graph_ordered, :text)
    assert Primitive.get_module(text) == Text
  end

  test "get_id_one raises if it doesn't fine any prmitives" do
    assert_raise Graph.Error, fn ->
      Graph.get_id_one(@graph_ordered, :missing)
    end
  end

  test "get_id_one raises if finds more than one primitive" do
    assert_raise Graph.Error, fn ->
      Graph.get_id_one(@graph_ordered, :line)
    end
  end


  #============================================================================
  # find

  test "find returns top level items" do
    [uid] = Graph.resolve_id(@graph_find, :outer_text)
    [p] = Graph.find(@graph_find, 0, tags: ["outer", "text"])
    assert Primitive.get_uid(p) == uid
  end

  test "find returns nested items" do
    [uid] = Graph.resolve_id(@graph_find, :inner_text)
    [p] = Graph.find(@graph_find, 0, tags: ["inner", "text"])
    assert Primitive.get_uid(p) == uid
  end

  test "find with id shortcut works" do
    [uid] = Graph.resolve_id(@graph_find, :inner_text)
    [p] = Graph.find(@graph_find, 0, id: :inner_text)
    assert Primitive.get_uid(p) == uid

    [uid] = Graph.resolve_id(@graph_find, :outer_line)
    [p] = Graph.find(@graph_find, 0, id: :outer_line)
    assert Primitive.get_uid(p) == uid
  end

  test "find returns items by uid" do
    [uid] = Graph.resolve_id(@graph_find, :inner_text)
    [p] = Graph.find(@graph_find, 0, uid: uid)
    assert Primitive.get_uid(p) == uid

    [start_uid] = Graph.resolve_id(@graph_find, :group)
    [uid] = Graph.resolve_id(@graph_find, :inner_text)
    [p] = Graph.find(@graph_find, start_uid, uid: uid)
    assert Primitive.get_uid(p) == uid
  end

  test "find does not find valid uid that is outside the requested tree" do
    [start_uid] = Graph.resolve_id(@graph_find, :group)
    [uid] = Graph.resolve_id(@graph_find, :outer_text)
    [] = Graph.find(@graph_find, start_uid, uid: uid)
  end

  test "find returns multiple items" do
    [uid_line] = Graph.resolve_id(@graph_find, :inner_line)
    [uid_text] = Graph.resolve_id(@graph_find, :inner_text)
    plist = Graph.find(@graph_find, 0, tag: "inner")

    Enum.each(plist, fn(p) ->
      assert (Primitive.get_uid(p) == uid_line) || (Primitive.get_uid(p) == uid_text)
    end)
  end

  test "find returns items by id" do
    [uid] = Graph.resolve_id(@graph_find, :group)
    [p] = Graph.find(@graph_find, uid, id: :inner_text)
    [uid] = Graph.resolve_id(@graph_find, :inner_text)
    assert Primitive.get_uid(p) == uid
  end

  test "find returns items by primitive module/type" do
    [uid] = Graph.resolve_id(@graph_find, :outer_line)
    [p] = Graph.find(@graph_find, 0, tag: "outer", module: Line)
    assert Primitive.get_uid(p) == uid

    [uid] = Graph.resolve_id(@graph_find, :inner_line)
    [p] = Graph.find(@graph_find, 0, tag: "inner", type: Line)
    assert Primitive.get_uid(p) == uid
  end

  test "starts at arbitrary nodes in the tree" do
    [uid] = Graph.resolve_id(@graph_find, :group)
    [p] = Graph.find(@graph_find, uid, module: Line)
    [uid] = Graph.resolve_id(@graph_find, :inner_line)
    assert Primitive.get_uid(p) == uid
  end

  test "find returns items by a single assign value" do
    [uid] = Graph.resolve_id(@graph_find, :inner_line)
    [p] = Graph.find(@graph_find, 0, state: {:abc, 123})
    assert Primitive.get_uid(p) == uid
  end

  #============================================================================
  test "find_uids returns uids instead of the primitives" do
    [text_uid] = Graph.resolve_id(@graph_find, :inner_text)
    [line_uid] = Graph.resolve_id(@graph_find, :inner_line)
    [^text_uid, ^line_uid] = Graph.find_uids(@graph_find, 0, tag: "inner")
  end


  #============================================================================
  # insert_at(graph_and_parent, index, element, opts \\ [])
  test "insert_at inserts an element at the root with just a graph passed in and assigns a new uid - no id" do
    # insert - returns transformed graph and assigned uid
    {graph, uid} = Graph.insert_at(@graph_empty, -1, @empty_group)

    # check that the uid is the next uid
    assert uid == 1

    # extract the graph
    %Graph{primitive_map: p_map, next_uid: next_uid} = graph

    #check that it was added
    p = Map.get(p_map, uid)
    assert Primitive.get_parent_uid(p) == 0
    assert Primitive.get_module(p) == Group
    assert Primitive.get_data(p) == @end_id_ref_marker

    # check that the item's uid was updated
    assert Primitive.get_uid(p) == uid

    # check that the next_uid was incremented
    assert next_uid == 2

    # check that the root now includes it as a child
    assert Group.get( Graph.get_root(graph) ) == [uid]

    # check that no id_map was set
    assert Graph.get_id_map(graph) == %{}
  end

  test "insert_at inserts an element at the root with just a graph passed in and assigns a new uid and sets id" do
    # insert - returns transformed graph and assigned uid
    empty_group = Primitive.do_put_id( @empty_group, :test_id )
    {graph, uid} = Graph.insert_at(@graph_empty, -1, empty_group)

    #check that it was added
    p = Graph.get(graph, uid)
    assert Primitive.get_parent_uid(p) == 0
    assert Primitive.get_module(p) == Group
    assert Primitive.get_data(p) == @end_id_ref_marker

    # check that the item's uid was updated
    assert Primitive.get_uid(p) == uid

    # check that the id map was added
    assert Graph.get_id_map(graph) == %{test_id: [uid]}
  end

  test "insert_at inserts an element with parent_uid of -1, which means it is in the map but not the tree" do
    # insert - returns transformed graph and assigned uid
    empty_group = Primitive.do_put_id(@empty_group, :test_id)
    {graph, uid} = Graph.insert_at({@graph_empty, -1}, -1, empty_group)

    #check that it was added
    p = Graph.get(graph, uid)
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Group
    assert Primitive.get_data(p) == @end_id_ref_marker

    # check that the item's uid was updated
    assert Primitive.get_uid(p) == uid

    # check that the id map was added
    assert Graph.get_id_map(graph) == %{test_id: [uid]}

    # check that it is not in the root
    assert Graph.get(graph, 0) == @empty_root
  end

  test "insert_at inserts an element at the root with a :root id passed in" do
    graph = @graph_empty

    # insert - returns transformed graph and assigned uid
    {graph, uid} = Graph.insert_at({graph, @root_uid}, -1, @empty_group)

    # check that the uid is the next uid
    assert uid == 1

    #check that it was added
    p = Graph.get(graph, uid)
    assert Primitive.get_parent_uid(p) == 0
    assert Primitive.get_module(p) == Group
    assert Primitive.get_data(p) == @end_id_ref_marker

    # check that the item's uid was updated
    assert Primitive.get_uid(p) == uid

    # check that the root now includes it as a child
    assert Group.get( Graph.get_root(graph) ) == [uid]

    # check that no id_map was set
    assert Graph.get_id_map(graph) == %{}
  end


  test "insert_at inserts an element into a nested node indicated by the parent uid" do
    {graph, parent_uid} = Graph.insert_at(@graph_empty, -1, @empty_group)

    #check that the setup is ok
    assert parent_uid == 1
    p = Graph.get(graph, parent_uid)
    assert Primitive.get_parent_uid(p) == 0
    assert Primitive.get_module(p) == Group
    assert Primitive.get_data(p) == @end_id_ref_marker

    # insert the div - returns transformed graph and assigned uid
    {graph, uid} = Graph.insert_at({graph, parent_uid}, -1, @empty_group)

    #check that it was added
    p = Graph.get(graph, uid)
    assert Primitive.get_parent_uid(p) == parent_uid
    assert Primitive.get_module(p) == Group
    assert Primitive.get_data(p) == @end_id_ref_marker

    # check that the item's uid was updated
    assert Primitive.get_uid(p) == uid

    # check that the parent references the new element
    p = Graph.get(graph, parent_uid)
    assert Primitive.get_data(p) == <<uid :: integer-size(32)-native, @end_id_ref_marker>>

    # check that no id map was set
    assert Graph.get_id_map(graph) == %{}
  end

  test "insert_at inserts an element into a nested node indicated by the parent uid and sets id" do
    {graph, parent_uid} = Graph.insert_at(@graph_empty, -1, @empty_group)

    #check that the setup is ok
    assert parent_uid == 1
    p = Graph.get(graph, parent_uid)
    assert Primitive.get_parent_uid(p) == 0
    assert Primitive.get_module(p) == Group
    assert Primitive.get_data(p) == @end_id_ref_marker


    # insert the div - returns transformed graph and assigned uid
    empty_group = Primitive.do_put_id(@empty_group, :test_id)
    {graph, uid} = Graph.insert_at({graph, parent_uid}, -1, empty_group)

    #check that it was added
    p = Graph.get(graph, uid)
    assert Primitive.get_parent_uid(p) == parent_uid
    assert Primitive.get_module(p) == Group
    assert Primitive.get_data(p) == @end_id_ref_marker

    # check that the item's uid was updated
    assert Primitive.get_uid(p) == uid

    # check that the parent references the new element    
    p = Graph.get(graph, parent_uid)
    assert Primitive.get_data(p) == <<uid :: integer-size(32)-native, @end_id_ref_marker>>

    # check that the id map was added
    assert Graph.get_id_map(graph) == %{test_id: [uid]}
  end



  #============================================================================
  test "insert_at inserts a graph into a graph (this makes templates work)" do
    # create a simple graph to receive the incoming template
    graph = Graph.build()
    {graph, parent_uid} = Graph.insert_at(graph, -1, @empty_group)

    #check that the setup is ok
    assert Graph.count(graph) == 2
    assert Graph.get_next_uid(graph) == 2

    # create the "template" graph to insert
    empty_group_with_id = Primitive.do_put_id(@empty_group, :t_tree)

    graph_t =           Graph.build(id: :template)
    {graph_t, _} =      Graph.insert_at(graph_t, -1, @empty_group)
    {graph_t, uid_1} =  Graph.insert_at(graph_t, -1, empty_group_with_id)
    {graph_t, _} =      Graph.insert_at({graph_t, uid_1}, -1, @empty_group)
    {graph_t, _} =      Graph.insert_at(graph_t, -1, @empty_group)

    #check that the setup is ok
    assert Graph.count(graph_t, -1) == 5
    assert Graph.get_next_uid(graph_t) == 5

    #insert the template
    {merged, uid} = Graph.insert_at({graph, parent_uid}, -1, graph_t, id: :test_id)

    #check the result
    assert Graph.count(merged, -1) == 7

    [t_uid] = Graph.resolve_id(merged, :template)
    assert t_uid == uid
    assert t_uid == 2
    assert Graph.count(merged, t_uid) == 5
    assert Graph.resolve_id(merged, :test_id) == [t_uid]

    # check that the template group's internal id was updated
    p = Graph.get(merged, uid)
    assert Primitive.get_uid(p) == uid

    [t_tree_uid] = Graph.resolve_id(merged, :t_tree)
    assert Graph.count(merged, t_tree_uid) == 2

    assert Graph.get_next_uid(merged) == 7

    # make sure the added tree is referenced by its new parent
    assert Group.get( Graph.get(merged, parent_uid) ) == [t_uid]
    assert Primitive.get_parent_uid( Graph.get(merged, t_uid) ) == parent_uid
  end


  #============================================================================
  # def modify( graph, uid, action )
  test "modify transforms a single primitive by uid" do
    {graph, uid} = Graph.insert_at(@graph_empty, -1, @empty_group)

    # confirm setup
    assert Primitive.get_transform( Graph.get(graph, uid) ) == nil

    # modify the element by assigning a transform to it
    graph = Graph.modify(graph, uid, fn(p)->
      Primitive.put_transform( p, @transform )
    end)

    # confirm result
    assert Primitive.get_transform( Graph.get(graph, uid) ) == @transform
    assert Graph.get_update_list(graph) == [uid]
  end

  test "modify transforms a single primitive by developer id" do
    empty_group_with_id = Primitive.do_put_id(@empty_group, :test_id)

    graph =           Graph.build()
    {graph, _} =      Graph.insert_at(graph, -1, @empty_group)
    {graph, uid_1} =  Graph.insert_at(graph, -1, empty_group_with_id)
    {graph, uid_2} =  Graph.insert_at({graph, uid_1}, -1, @empty_group)
    {graph, uid_3} =  Graph.insert_at(graph, -1, empty_group_with_id)

    # confirm setup
    assert Primitive.get_transform( Graph.get(graph, uid_1) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_2) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_3) ) == nil

    # modify the element by assigning a transform to it
    graph = Graph.modify(graph, :test_id, fn(p)->
      Primitive.put_transform( p, @transform )
    end)

    # confirm result
    assert Primitive.get_transform( Graph.get(graph, uid_1) ) == @transform
    assert Primitive.get_transform( Graph.get(graph, uid_2) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_3) ) == @transform

    assert Enum.member?(Graph.get_update_list(graph), uid_1)
    assert Enum.member?(Graph.get_update_list(graph), uid_3)
  end

  test "modify works on a list of uids" do
    {graph, uid_1} = Graph.insert_at(@graph_empty, -1, @empty_group)
    {graph, uid_2} = Graph.insert_at(graph, -1, @empty_group)
    {graph, uid_3} = Graph.insert_at(graph, -1, @empty_group)

    # confirm setup
    assert Primitive.get_transform( Graph.get(graph, uid_1) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_2) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_3) ) == nil

    # modify the element by assigning a transform to it
    graph = Graph.modify(graph, [uid_1, uid_3], fn(p)->
      Primitive.put_transform( p, @transform )
    end)

    # confirm result
    assert Primitive.get_transform( Graph.get(graph, uid_1) ) == @transform
    assert Primitive.get_transform( Graph.get(graph, uid_2) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_3) ) == @transform

    assert Enum.member?(Graph.get_update_list(graph), uid_1)
    assert Enum.member?(Graph.get_update_list(graph), uid_3)
  end


  #============================================================================
  # find_modify(graph, start_uid, criteria, callback)

  test "find_modify modifies only the found primitives with a single criteria" do
    graph = @graph_find

    # confirm setup
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_line) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_line) ) == nil

    graph = Graph.find_modify(graph, 0, {:tag, "line"}, fn(p)->
      Primitive.put_transform( p, @transform )
    end)

    # confirm result
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_line) ) == @transform
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_line) ) == @transform

    # confirm update list
    up_list = Graph.get_update_list(graph)
    assert Enum.count(up_list) == 2
    assert Enum.member?(up_list, Primitive.get_uid(Graph.get_id_one(graph, :outer_line)))
    assert Enum.member?(up_list, Primitive.get_uid(Graph.get_id_one(graph, :inner_line)))
  end

  test "find_modify modifies only the found primitives with a criteria list" do
    graph = @graph_find

    # confirm setup
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_line) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_line) ) == nil

    graph = Graph.find_modify(graph, 0, [tag: "outer", type: Line], fn(p)->
      Primitive.put_transform( p, @transform )
    end)

    # confirm result
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_line) ) == @transform
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_line) ) == nil

    # confirm update list
    up_list = Graph.get_update_list(graph)
    assert up_list == [Primitive.get_uid(Graph.get_id_one(graph, :outer_line))]
  end

  test "find_modify modifies only the found primitives under start_uid" do
    graph = @graph_find
    [group_uid] = Graph.resolve_id(graph, :group)

    # confirm setup
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_line) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_line) ) == nil

    graph = Graph.find_modify(graph, group_uid, [tag: "line"], fn(p)->
      Primitive.put_transform( p, @transform )
    end)

    # confirm result
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :outer_line) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_text) ) == nil
    assert Primitive.get_transform( Graph.get_id_one(graph, :inner_line) ) == @transform

    # confirm update list
    up_list = Graph.get_update_list(graph)
    assert up_list == [Primitive.get_uid(Graph.get_id_one(graph, :inner_line))]
  end



  #============================================================================
  # reduce(graph, acc, action) - whole tree
  test "reduce recurses over entire tree" do
    {graph, _} =      Graph.insert_at(@graph_empty, -1, @empty_group)
    {graph, uid_1} =  Graph.insert_at(graph, -1, @empty_group)
    {graph, _} =      Graph.insert_at({graph, uid_1}, -1, @empty_group)
    {graph, _} =      Graph.insert_at(graph, -1, @empty_group)

    assert Graph.reduce(graph, 0, fn(_, acc) ->
      acc + 1
    end) == 5
  end

  #============================================================================
  # reduce(graph, uid, acc, action) - sub tree
  test "reduce recurses over sub tree" do
    {graph, _} =      Graph.insert_at(@graph_empty, -1, @empty_group)
    {graph, uid_1} =  Graph.insert_at(graph, -1, @empty_group)
    {graph, _} =      Graph.insert_at({graph, uid_1}, -1, @empty_group)
    {graph, _} =      Graph.insert_at(graph, -1, @empty_group)

    assert Graph.reduce(graph, uid_1, 0, fn(_, acc)->
      acc + 1
    end) == 2
  end

  test "reduce recurses over stand-alone node" do
    {graph, _} =      Graph.insert_at(@graph_empty, -1, @empty_group)
    {graph, uid_1} =  Graph.insert_at(graph, -1, @empty_group)
    {graph, _} =      Graph.insert_at({graph, uid_1}, -1, @empty_group)
    {graph, uid_2} =  Graph.insert_at(graph, -1, @empty_group)

    assert Graph.reduce(graph, uid_2, 0, fn(_, acc)->
      acc + 1
    end) == 1
  end

  #============================================================================
  # reduce(graph, id, acc, action) - just mapped to id
  test "reduce reduces just nodes mapped to a mapped id" do
    empty_group_id_one= Primitive.do_put_id(@empty_group, :one)
    empty_group_id_two= Primitive.do_put_id(@empty_group, :two)

    {graph, _} =      Graph.insert_at(@graph_empty, -1, empty_group_id_two)
    {graph, uid_1} =  Graph.insert_at(graph, -1, empty_group_id_one)
    {graph, _} =      Graph.insert_at({graph, uid_1}, -1, empty_group_id_two)
    {graph, _} =      Graph.insert_at(graph, -1, @empty_group)

    assert Graph.reduce(graph, :one, 0, fn(_, acc)->
      acc + 1
    end) == 1

    assert Graph.reduce(graph, :two, 0, fn(_, acc)->
      acc + 1
    end) == 2
  end



  #============================================================================
  # map(graph, action) - whole tree
  test "map recurses over entire tree" do
    {graph, uid_0} = Graph.insert_at(@graph_empty, -1, @empty_group)
    {graph, uid_1} = Graph.insert_at(graph, -1, @empty_group)
    {graph, uid_2} = Graph.insert_at({graph, uid_1}, -1, @empty_group)
    {graph, uid_3} = Graph.insert_at(graph, -1, @empty_group)

    # confirm setup
    assert Primitive.get_transform( Graph.get(graph, @root_uid) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_0) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_1) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_2) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_3) ) == nil

    graph = Graph.map(graph, fn(p) ->
      Primitive.put_transform( p, @transform )
    end)

    # confirm result
    assert Primitive.get_transform( Graph.get(graph, @root_uid) ) == @transform
    assert Primitive.get_transform( Graph.get(graph, uid_0) ) == @transform
    assert Primitive.get_transform( Graph.get(graph, uid_1) ) == @transform
    assert Primitive.get_transform( Graph.get(graph, uid_2) ) == @transform
    assert Primitive.get_transform( Graph.get(graph, uid_3) ) == @transform
  end

  #============================================================================
  # map(graph, uid, action) - sub tree
  test "map recurses over sub tree" do
    {graph, uid_0} = Graph.insert_at(@graph_empty, -1, @empty_group)
    {graph, uid_1} = Graph.insert_at(graph, -1, @empty_group)
    {graph, uid_2} = Graph.insert_at({graph, uid_1}, -1, @empty_group)
    {graph, uid_3} = Graph.insert_at(graph, -1, @empty_group)

    # confirm setup
    assert Primitive.get_transform( Graph.get(graph, @root_uid) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_0) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_1) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_2) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_3) ) == nil

    graph = Graph.map(graph, uid_1, fn(p) ->
      Primitive.put_transform( p, @transform )
    end)

    # confirm result
    assert Primitive.get_transform( Graph.get(graph, @root_uid) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_0) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_1) ) == @transform
    assert Primitive.get_transform( Graph.get(graph, uid_2) ) == @transform
    assert Primitive.get_transform( Graph.get(graph, uid_3) ) == nil
  end

  #============================================================================
  # map_id(graph, id, action) - just mapped to id
  test "map_id only maps nodes with a mapped id" do
    empty_group_with_id = Primitive.do_put_id( @empty_group, :test_id )

    {graph, uid_0} = Graph.insert_at(@graph_empty, -1, empty_group_with_id)
    {graph, uid_1} = Graph.insert_at(graph, -1, @empty_group)
    {graph, uid_2} = Graph.insert_at({graph, uid_1}, -1, empty_group_with_id)
    {graph, uid_3} = Graph.insert_at(graph, -1, @empty_group)

    # confirm setup
    assert Primitive.get_transform( Graph.get(graph, @root_uid) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_0) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_1) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_2) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_3) ) == nil

    graph = Graph.map(graph, :test_id, fn(p) ->
      Primitive.put_transform( p, @transform )
    end)

    # confirm result
    assert Primitive.get_transform( Graph.get(graph, @root_uid) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_0) ) == @transform
    assert Primitive.get_transform( Graph.get(graph, uid_1) ) == nil
    assert Primitive.get_transform( Graph.get(graph, uid_2) ) == @transform
    assert Primitive.get_transform( Graph.get(graph, uid_3) ) == nil
  end

  #============================================================================
  # put_event_filter(graph, id, handler)

  test "put_event_filter adds a function handler to the primitive indicated by id" do
    [uid] = Graph.resolve_id(@filter_graph, :rect)
    graph = Graph.put_event_filter(@filter_graph, :rect, fn(_a,_b,_c,_d) -> nil end)
    p = Graph.get(graph, uid)
    assert is_function(Primitive.get_event_filter(p), 4)
  end

  
  test "put_event_filter adds a function handler to the primitive indicated by uid" do
    [uid] = Graph.resolve_id(@filter_graph, :rect)
    graph = Graph.put_event_filter(@filter_graph, uid, fn(_a,_b,_c,_d) -> nil end)
    p = Graph.get(graph, uid)
    assert is_function(Primitive.get_event_filter(p), 4)
  end
  
  test "put_event_filter adds a {mod,fun} handler to the primitive indicated by id" do
    [uid] = Graph.resolve_id(@filter_graph, :rect)
    graph = Graph.put_event_filter(@filter_graph, :rect, { :mod, :act })
    p = Graph.get(graph, uid)
    assert Primitive.get_event_filter(p) == { :mod, :act }
  end

  test "put_event_filter adds a {mod,fun} handler to the primitive indicated by uid" do
    [uid] = Graph.resolve_id(@filter_graph, :rect)
    graph = Graph.put_event_filter(@filter_graph, uid, { :mod, :act })
    p = Graph.get(graph, uid)
    assert Primitive.get_event_filter(p) == { :mod, :act }
  end

  test "put_event_filter sets nil handler to the primitive indicated by id" do
    [uid] = Graph.resolve_id(@filter_graph, :rect)
    graph = Graph.put_event_filter(@filter_graph, :rect, { :mod, :act })
    p = Graph.get(graph, uid)
    assert Primitive.get_event_filter(p) == { :mod, :act }

    p = Graph.put_event_filter(graph, :rect, nil)
      |> Graph.get( uid )
    assert Primitive.get_event_filter(p) == nil
  end

  test "put_event_filter sets nil handler to the primitive indicated by uid" do
    [uid] = Graph.resolve_id(@filter_graph, :rect)
    graph = Graph.put_event_filter(@filter_graph, uid, { :mod, :act })
    p = Graph.get(graph, uid)
    assert Primitive.get_event_filter(p) == { :mod, :act }

    p = Graph.put_event_filter(graph, :rect, nil)
      |> Graph.get( uid )
    assert Primitive.get_event_filter(p) == nil
  end

  #============================================================================
  # filter_input(graph, event, uid)

  test "filter_input calls all the filters up the graph with :continue" do
    [rect_uid] = Graph.resolve_id(@filter_graph, :rect)
    [group_uid] = Graph.resolve_id(@filter_graph, "group")
    graph = @filter_graph
      |> Graph.put_event_filter(:rect, fn(event, id, primitive, graph) ->
        # make sure the rect was passed in
        assert id == :rect
        assert event == :event_start
        assert Primitive.get_uid(primitive) == rect_uid
        # post a message to self that we can check for at the end of the test
        Process.send( self(), :test_rect_callback, [])
        {:continue, :event_transformed, graph}
      end)
      |> Graph.put_event_filter("group", fn(event, id, primitive, graph) ->
        # make sure the rect was passed in
        assert id == "group"
        assert event == :event_transformed
        assert Primitive.get_uid(primitive) == group_uid
        # post a message to self that we can check for at the end of the test
        Process.send( self(), :test_group_callback, [])
        {:continue, event, graph}
      end)

    # send the message up the graph
    {:continue,_,_} = Graph.filter_input( graph, :event_start, rect_uid )

    # check messages here
    assert_received( :test_rect_callback  )
    assert_received( :test_group_callback  )
  end

  test "filter_input stops calling up the graph with :stop" do
    [rect_uid] = Graph.resolve_id(@filter_graph, :rect)
    [group_uid] = Graph.resolve_id(@filter_graph, "group")
    graph = @filter_graph
      |> Graph.put_event_filter(:rect, fn(event, id, primitive, graph) ->
        # make sure the rect was passed in
        assert id == :rect
        assert event == :event_start
        assert Primitive.get_uid(primitive) == rect_uid
        # post a message to self that we can check for at the end of the test
        Process.send( self(), :test_rect_callback, [])
        {:stop, graph}
      end)
      |> Graph.put_event_filter("group", fn(event, id, primitive, graph) ->
        # make sure the rect was passed in
        assert id == "group"
        assert event == :event_transformed
        assert Primitive.get_uid(primitive) == group_uid
        # post a message to self that we can check for at the end of the test
        Process.send( self(), :test_group_callback, [])
        {:continue, event, graph}
      end)

    # send the message up the graph
    {:stop,_} = Graph.filter_input( graph, :event_start, rect_uid )

    # check messages here
    assert_received( :test_rect_callback  )
    refute_received( :test_group_callback  )
  end


  def mod_action(_, _, _, g) do
    Process.send( self(), :test_mod_action, [])
    {:stop, g}
  end
  test "filter_input calls {mod,act} format handlers" do
    [rect_uid] = Graph.resolve_id(@filter_graph, :rect)
    graph = Graph.put_event_filter(@filter_graph, :rect, {__MODULE__,:mod_action})

    # send the message up the graph
    {:stop, _} = Graph.filter_input( graph, :event_start, rect_uid )

    # check messages here
    assert_received( :test_mod_action  )
  end


  # Graph.put_new( graph, parent, Rectangle.build({0, 0}, 100, 200, id: :rect) )
  test "filter_input lets the filter modify the graph" do
    [rect_uid] = Graph.resolve_id(@filter_graph, :rect)
    graph = @filter_graph
      |> Graph.put_event_filter(:rect, fn(_, id, _, graph) ->

        # modify the graph
        graph = Graph.modify(graph, id, fn(p) ->
          Rectangle.put(p, {1000, 1001}, 300, 400)
        end)

        {:stop, graph}
      end)

    # send the message up the graph
    {:stop, graph} = Graph.filter_input( graph, :event_start, rect_uid )

    rect = Graph.get(graph, rect_uid)
    assert Rectangle.get(rect) == {{1000, 1001}, 300, 400}

  end


  #============================================================================
  # put_hidden(graph, id, flag)

  test "put_style modifies the graph by adding the given style" do
    color_style = Style.Color.build(:bisque)

    graph = Graph.put_style(@filter_graph, :rect, color_style )
    rect = Graph.get_id_one(graph, :rect)
    assert Primitive.get_style(rect, Style.Color) == color_style
  end

  test "put_style modifies the graph by building and adding the given style" do
    color_style = Style.Color.build(:bisque)

    graph = Graph.put_style(@filter_graph, :rect, Style.Color, [:bisque] )
    rect = Graph.get_id_one(graph, :rect)
    assert Primitive.get_style(rect, Style.Color) == color_style
  end



  #============================================================================
  # schedule_recurring_action recurring action support

  def step(graph, _, 123) do
    {:continue, graph, 124}
  end

  def step(graph, _, 321) do
    {:stop, graph}
  end

  def test_action_zero_time(graph, 0, _args) do
    {:continue, graph, :zero_time}
  end

  def test_action_continue(graph, elapsed_time, args) do
    {:continue, graph, args + elapsed_time}
  end

  def test_action_stop(graph, _elapsed_time, _args) do
    {:stop, graph}
  end

  test "schedule_recurring_action adds a function callback recurring action" do
    %Graph{recurring_actions: actions} = graph = @graph_empty
    assert Enum.count(actions) == 0

    {:ok, graph, {:recurring_action_reference, ref}} = Graph.schedule_recurring_action(graph, 123, fn(_,_,_)-> nil end)
    %Graph{recurring_actions: actions} = graph
    [{_, _, 123}] = actions
    assert Enum.count(actions) == 1
    assert is_bitstring(ref)
  end

  test "schedule_recurring_action adds a standard module recurring action" do
    %Graph{recurring_actions: actions} = graph = @graph_empty
    assert Enum.count(actions) == 0

    {:ok, graph, {:recurring_action_reference, ref}} = Graph.schedule_recurring_action(graph, 123, __MODULE__)
    %Graph{recurring_actions: actions} = graph
    [{_, __MODULE__, 123}] = actions
    assert Enum.count(actions) == 1
    assert is_bitstring(ref)
  end

  test "schedule_recurring_action adds a mod/act recurring action" do
    %Graph{recurring_actions: actions} = graph = @graph_empty
    assert Enum.count(actions) == 0

    {:ok, graph, {:recurring_action_reference, ref}} = Graph.schedule_recurring_action(graph, 123, __MODULE__, :test_action_continue)
    %Graph{recurring_actions: actions} = graph
    [{_, {__MODULE__, :test_action_continue}, 123}] = actions
    assert Enum.count(actions) == 1
    assert is_bitstring(ref)
  end

  test "schedule_recurring_action! adds a function callback recurring action and returns just the graph" do
    %Graph{recurring_actions: actions} = graph = @graph_empty
    assert Enum.count(actions) == 0

    %Graph{recurring_actions: actions} = Graph.schedule_recurring_action!(graph, 123, fn(_,_,_)-> nil end)
    assert Enum.count(actions) == 1
  end

  test "schedule_recurring_action! adds a standard module recurring action" do
    %Graph{recurring_actions: actions} = graph = @graph_empty
    assert Enum.count(actions) == 0

    %Graph{recurring_actions: actions} = Graph.schedule_recurring_action!(graph, 123, __MODULE__)
    [{_, __MODULE__, 123}] = actions
    assert Enum.count(actions) == 1
  end

  test "schedule_recurring_action! adds a mod/act recurring action and returns just the graph" do
    %Graph{recurring_actions: actions} = graph = @graph_empty
    assert Enum.count(actions) == 0

    %Graph{recurring_actions: actions} = Graph.schedule_recurring_action!(graph, 123, __MODULE__, :test_action_continue)
    [{_, {__MODULE__, :test_action_continue}, 123}] = actions
    assert Enum.count(actions) == 1
  end

  #============================================================================
  # cancel_recurring_action cancel and remove a recurring action from the recurring action list

  test "cancel_recurring_action cancels a recurring action" do
    {:ok, graph, ref} = Graph.schedule_recurring_action(@graph_empty, 123, __MODULE__, :test_action_continue)
    %Graph{recurring_actions: actions} = graph
    assert Enum.count(actions) == 1

    graph = Graph.cancel_recurring_action(graph, ref)

    %Graph{recurring_actions: actions} = graph
    assert Enum.count(actions) == 0
  end

  test "cancel_recurring_action does nothing for an invalid reference" do
    {:ok, graph, _} = Graph.schedule_recurring_action(@graph_empty, 123, __MODULE__, :test_action_continue)
    %Graph{recurring_actions: actions} = graph
    assert Enum.count(actions) == 1

    assert Graph.cancel_recurring_action(graph, {:recurring_action_reference, make_ref()}) == graph
  end


  #============================================================================
  # tick_recurring_action cancel and remove a recurring action from the recurring action list


  test "tick_recurring_action calls a function callback - continue" do
    graph = Graph.schedule_recurring_action!(@graph_empty, 123, fn(g,elapsed_time,123)->
      assert elapsed_time >= 10
      {:continue, g, 123 + elapsed_time + 10}
    end)
    %Graph{recurring_actions: actions} = graph
    [{_, func, 123}] = actions
    assert is_function(func, 3)

    # fake in a last action time
    graph = Map.put(graph, :last_recurring_action, :os.system_time(:milli_seconds) - 10)

    %Graph{recurring_actions: actions} = Graph.tick_recurring_actions( graph )
    [{_, func2, inc}] = actions
    assert inc >= 143
    assert func == func2
  end

  test "tick_recurring_action calls the module callback - continue" do
    graph = Graph.schedule_recurring_action!(@graph_empty, 123, __MODULE__)
    %Graph{recurring_actions: actions} = graph
    [{_, __MODULE__, 123}] = actions

    # fake in a last action time
    graph = Map.put(graph, :last_recurring_action, :os.system_time(:milli_seconds) - 10)

    %Graph{recurring_actions: actions} = Graph.tick_recurring_actions( graph )
    [{_, __MODULE__, 124}] = actions
  end

  test "tick_recurring_action calls the mod/act callback - continue" do
    graph = Graph.schedule_recurring_action!(@graph_empty, 123, __MODULE__, :test_action_continue)
    %Graph{recurring_actions: actions} = graph
    [{_, {__MODULE__, :test_action_continue}, 123}] = actions

    # fake in a last action time
    graph = Map.put(graph, :last_recurring_action, :os.system_time(:milli_seconds) - 10)

    %Graph{recurring_actions: actions} = Graph.tick_recurring_actions( graph )
    [{_, {__MODULE__, :test_action_continue}, inc}] = actions
    assert inc >= 133
  end

  test "tick_recurring_action calls a function callback - stop" do
    graph = Graph.schedule_recurring_action!(@graph_empty, 123, fn(g,_,_)-> {:stop, g} end)
    %Graph{recurring_actions: actions} = graph
    [{_, func, 123}] = actions
    assert is_function(func, 3)

    %Graph{recurring_actions: actions} = Graph.tick_recurring_actions( graph )
    assert actions == []
  end

  test "tick_recurring_action calls the module callback - stop" do
    graph = Graph.schedule_recurring_action!(@graph_empty, 321, __MODULE__)
    %Graph{recurring_actions: actions} = graph
    [{_, __MODULE__, 321}] = actions

    # fake in a last action time
    graph = Map.put(graph, :last_recurring_action, :os.system_time(:milli_seconds) - 10)

    %Graph{recurring_actions: actions} = Graph.tick_recurring_actions( graph )
    assert actions == []
  end

  test "tick_recurring_action calls the mod/act callback - stop" do
    graph = Graph.schedule_recurring_action!(@graph_empty, 123, __MODULE__, :test_action_stop)
    %Graph{recurring_actions: actions} = graph
    [{_, {__MODULE__, :test_action_stop}, 123}] = actions

    %Graph{recurring_actions: actions} = Graph.tick_recurring_actions( graph )
    assert actions == []
  end

  test "tick_recurring_action calls the callback with 0 elapsed time if the last time is nil" do
    graph = Graph.schedule_recurring_action!(@graph_empty, 123, __MODULE__, :test_action_zero_time)
    %Graph{recurring_actions: actions} = graph
    [{_, {__MODULE__, :test_action_zero_time}, 123}] = actions

    %Graph{recurring_actions: actions} = Graph.tick_recurring_actions( graph )
    [{_, {__MODULE__, :test_action_zero_time}, :zero_time}] = actions
  end
end










