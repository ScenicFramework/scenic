#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.GraphTest do
  use ExUnit.Case, async: true
  doctest Scenic

  # alias Scenic.Math.Matrix
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Group
  alias Scenic.Primitive.Text
  alias Scenic.Primitive.Rectangle
  alias Scenic.Primitive.Line

 # import IEx
  
  @root_uid               0

  @tx_pin                 {10,11}
  @tx_rot                 0.1
  @transform              %{pin: @tx_pin, rotate: @tx_rot}


  @empty_root             Group.build() #|> Primitive.put_uid(@root_uid)
  @graph_empty            Graph.build()

  @graph_find       Graph.build()
    |> Text.add_to_graph( "Some sample text", id: :outer_text  )
    |> Line.add_to_graph( {{10,10}, {100, 100}}, id: :outer_line )
    |> Group.add_to_graph( fn(g) ->
      g
      |> Text.add_to_graph("inner text", id: :inner_text)
      |> Line.add_to_graph({{10,10}, {100, 100}}, id: :inner_line)
    end, id: :group)

  @graph_ordered Graph.build()
    |> Line.add_to_graph( {{10,10}, {100, 100}}, id: :line )
    |> Text.add_to_graph( "text", id: :text )
    |> Line.add_to_graph( {{30,30}, {300, 300}}, id: :line )



  #============================================================================
  # access to the basics. These concentrate knowledge of the internal format
  # into just a few functions

  test "get_root returns the root node" do
    assert Graph.get_root(@graph_empty) == @empty_root
  end


  #============================================================================
  # build
  test "build builds a new graph" do
    %Graph{} = Graph.build()
  end

  test "build builds accepts an id for the root node " do
    graph = Graph.build(id: :test_root)
    assert graph.ids == %{test_root: [0]}
  end

  test "new graphs start with id :root pointing to uid 0" do
    graph = Graph.build()
    assert Graph.count(graph) == 1
    assert graph.ids == %{}
  end

  test "build accepts and uses a builder callback" do
    assert Graph.build( builder: fn({graph, parent_id}) ->
      assert graph == @graph_empty
      assert parent_id == @root_uid
      {graph, parent_id}
    end) == @graph_empty
  end

  test "build puts styles on the root node" do
    graph = Graph.build( clear_color: :dark_slate_blue )
    assert graph.primitives[@root_uid]
    |> Primitive.get_styles()  == %{clear_color: :dark_slate_blue}
  end

  test "build puts transforms on the root node" do
    graph = Graph.build( rotate: 1.3 )
    assert graph.primitives[@root_uid]
    |> Primitive.get_transforms()  == %{rotate: 1.3}
  end

  test "build accepts the :max_depth option" do
    graph = Graph.build(max_depth: 1)
    assert Map.get(graph, :max_depth) == 1
  end


  #============================================================================
  # map_id_to_uid(graph, id, uid)

  # test "map_id_to_uid creates a new uid map for an id" do
  #   graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
  #   assert graph.ids == %{ test_id: [1] }
  # end

  # test "map_id_to_uid adds a new uid to an existing id map" do
  #   graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
  #     |> Graph.map_id_to_uid(:test_id, 2)
  #   assert graph.ids == %{ test_id: [2, 1] }
  # end

  # test "map_id_to_uid keeps the list uniq" do
  #   graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
  #     |> Graph.map_id_to_uid(:test_id, 1)
  #     |> Graph.map_id_to_uid(:test_id, 2)
  #     |> Graph.map_id_to_uid(:test_id, 2)
  #     |> Graph.map_id_to_uid(:test_id, 1)
  #   assert graph.ids == %{ test_id: [1,2]}
  # end


  #============================================================================
  # unmap_id_to_uid(graph, id, uid)
  # test "unmap_id_to_uid removes a uid map" do
  #   graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
  #     |> Graph.map_id_to_uid(:test_id, 2)
  #     |> Graph.map_id_to_uid(:test_id, 3)
  #     |> Graph.unmap_id_to_uid(:test_id, 2)
  #   assert graph.ids == %{ test_id: [3, 1] }
  # end

  # test "unmap_id_to_uid does nothing if id is nil" do
  #   graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
  #     |> Graph.map_id_to_uid(:test_id, 2)
  #     |> Graph.map_id_to_uid(:test_id, 3)
  #     |> Graph.unmap_id_to_uid(nil, 2)
  #   assert graph.ids == %{ test_id: [3, 2, 1] }
  # end

  # test "unmap_id_to_uid does nothing if id is not mapped" do
  #   graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
  #     |> Graph.map_id_to_uid(:test_id, 2)
  #     |> Graph.map_id_to_uid(:test_id, 3)
  #     |> Graph.unmap_id_to_uid(:banana, 1)
  #   assert graph.ids == %{ test_id: [3, 2, 1] }
  # end

  # test "unmap_id_to_uid does nothing if uid is not in id map" do
  #   graph = Graph.map_id_to_uid(@graph_empty, :test_id, 1)
  #     |> Graph.map_id_to_uid(:test_id, 2)
  #     |> Graph.map_id_to_uid(:test_id, 3)
  #     |> Graph.unmap_id_to_uid(:test_id, 123)
  #   assert graph.ids == %{ test_id: [3, 2, 1] }
  # end


  #============================================================================
  # resolve_id

  # test "resolve_id returns multiple uids in a list for a given id" do
  #   assert Graph.resolve_id(@graph_ordered, :line) == [3, 1]
  # end

  # test "resolve_id returns an empty list  for a missing id" do
  #   assert Graph.resolve_id(@graph_ordered, :missing) == []
  # end

  #============================================================================
  # count - all nodes
  test "count returns 1 if only the root node exists" do
    assert Graph.count(@graph_empty) == 1
  end

  test "count counts the items in the graph" do
    assert Enum.count( @graph_find.primitives ) == 6
    assert Graph.count(@graph_find) == 6
  end

  test "count counts the primitives with a given id" do
    assert Graph.count(@graph_ordered, :missing) == 0
    assert Graph.count(@graph_ordered, :text) == 1
    assert Graph.count(@graph_ordered, :line) == 2
  end


  #============================================================================
  # count from the root
  test "count by root returns the number of elements in the tree via recursion" do
    assert Graph.count(@graph_find) == 6
  end

  #============================================================================
  # get_id by developer id
  test "get gets an element by id" do
    [uid] = @graph_find.ids[:outer_text]
    p = Graph.get_id(@graph_find, :outer_text)
    assert [@graph_find.primitives[uid]] == p
  end

  test "get gets multiple elements by id" do
    [first_uid, second_uid] = @graph_ordered.ids[:line]

    gotten = Graph.get_id(@graph_ordered, :line)

    assert Enum.member?(gotten, @graph_ordered.primitives[first_uid])
    assert Enum.member?(gotten, @graph_ordered.primitives[second_uid])
  end

  #============================================================================
  # get_id
  # returns a list of objects with the given id
  test "get_id returns a list of primitives with the given id" do
    [first_uid, second_uid] = @graph_ordered.ids[:line]
    [first, second] = Graph.get_id(@graph_ordered, :line)

    assert @graph_ordered.primitives[first_uid] == first
    assert @graph_ordered.primitives[second_uid] == second
  end


  #============================================================================
  # get_id! returns a single object indicated by id

  test "get_id! returns a single primitive matching the id" do
    text = Graph.get_id!(@graph_ordered, :text)
    assert text.module == Text
  end

  test "get_id! raises if it doesn't fine any prmitives" do
    assert_raise Graph.Error, fn ->
      Graph.get_id!(@graph_ordered, :missing)
    end
  end

  test "get_id! raises if finds more than one primitive" do
    assert_raise Graph.Error, fn ->
      Graph.get_id!(@graph_ordered, :line)
    end
  end


  #============================================================================
  # insert_at(graph_and_parent, index, element, opts \\ [])
  # test "insert_at inserts an element at the root with just a graph passed in and assigns a new uid - no id" do
  #   # insert - returns transformed graph and assigned uid
  #   {graph, uid} = Graph.insert_at(@graph_empty, -1, @empty_group)

  #   # check that the uid is the next uid
  #   assert uid == 1

  #   # extract the graph
  #   %Graph{primitives: p_map, next_uid: next_uid} = graph

  #   #check that it was added
  #   p = Map.get(p_map, uid)
  #   # assert Primitive.get_parent_uid(p) == 0
  #   assert Primitive.get_module(p) == Group

  #   # check that the item's uid was updated
  #   # assert Primitive.get_uid(p) == uid

  #   # check that the next_uid was incremented
  #   assert next_uid == 2

  #   # check that the root now includes it as a child
  #   assert Primitive.get( Graph.get_root(graph) ) == [uid]

  #   # check that no ids was set
  #   assert graph.ids == %{}
  # end

  # test "insert_at inserts an element at the root with just a graph passed in and assigns a new uid and sets id" do
  #   # insert - returns transformed graph and assigned uid
  #   empty_group = Primitive.put_id( @empty_group, :test_id )
  #   {graph, uid} = Graph.insert_at(@graph_empty, -1, empty_group)

  #   #check that it was added
  #   p = graph.primitives[uid]
  #   # assert Primitive.get_parent_uid(p) == 0
  #   assert Primitive.get_module(p) == Group

  #   # check that the item's uid was updated
  #   # assert Primitive.get_uid(p) == uid

  #   # check that the id map was added
  #   assert graph.ids == %{test_id: [uid]}
  # end

  # test "insert_at inserts an element with parent_uid of -1, which means it is in the map but not the tree" do
  #   # insert - returns transformed graph and assigned uid
  #   empty_group = Primitive.put_id(@empty_group, :test_id)
  #   {graph, uid} = Graph.insert_at({@graph_empty, -1}, -1, empty_group)

  #   #check that it was added
  #   p = graph.primitives[uid]
  #   # assert Primitive.get_parent_uid(p) == -1
  #   assert Primitive.get_module(p) == Group

  #   # check that the item's uid was updated
  #   # assert Primitive.get_uid(p) == uid

  #   # check that the id map was added
  #   assert graph.ids == %{test_id: [uid]}

  #   # check that it is not in the root
  #   assert graph.primitives[0]== @empty_root
  # end

  # test "insert_at inserts an element at the root with a :root id passed in" do
  #   graph = @graph_empty

  #   # insert - returns transformed graph and assigned uid
  #   {graph, uid} = Graph.insert_at({graph, @root_uid}, -1, @empty_group)

  #   # check that the uid is the next uid
  #   assert uid == 1

  #   #check that it was added
  #   p = graph.primitives[uid]
  #   # assert Primitive.get_parent_uid(p) == 0
  #   assert Primitive.get_module(p) == Group

  #   # check that the item's uid was updated
  #   # assert Primitive.get_uid(p) == uid

  #   # check that the root now includes it as a child
  #   assert Primitive.get( Graph.get_root(graph) ) == [uid]

  #   # check that no ids was set
  #   assert graph.ids == %{}
  # end


  # test "insert_at inserts an element into a nested node indicated by the parent uid" do
  #   {graph, parent_uid} = Graph.insert_at(@graph_empty, -1, @empty_group)

  #   #check that the setup is ok
  #   assert parent_uid == 1
  #   p = graph.primitives[parent_uid]
  #   # assert Primitive.get_parent_uid(p) == 0
  #   assert Primitive.get_module(p) == Group

  #   # insert the div - returns transformed graph and assigned uid
  #   {graph, uid} = Graph.insert_at({graph, parent_uid}, -1, @empty_group)

  #   #check that it was added
  #   p = graph.primitives[uid]
  #   # assert Primitive.get_parent_uid(p) == parent_uid
  #   assert Primitive.get_module(p) == Group

  #   # check that the item's uid was updated
  #   # assert Primitive.get_uid(p) == uid

  #   # check that the parent references the new element
  #   p = graph.primitives[parent_uid]
  #   assert Primitive.get(p) == [uid]

  #   # check that no id map was set
  #   assert graph.ids == %{}
  # end

  # test "insert_at inserts an element into a nested node indicated by the parent uid and sets id" do
  #   {graph, parent_uid} = Graph.insert_at(@graph_empty, -1, @empty_group)

  #   #check that the setup is ok
  #   assert parent_uid == 1
  #   p = graph.primitives[parent_uid]
  #   # assert Primitive.get_parent_uid(p) == 0
  #   assert Primitive.get_module(p) == Group


  #   # insert the div - returns transformed graph and assigned uid
  #   empty_group = Primitive.put_id(@empty_group, :test_id)
  #   {graph, uid} = Graph.insert_at({graph, parent_uid}, -1, empty_group)

  #   #check that it was added
  #   p = graph.primitives[uid]
  #   # assert Primitive.get_parent_uid(p) == parent_uid
  #   assert Primitive.get_module(p) == Group

  #   # check that the item's uid was updated
  #   # assert Primitive.get_uid(p) == uid

  #   # check that the parent references the new element    
  #   p = graph.primitives[parent_uid]
  #   assert Primitive.get(p) == [uid]

  #   # check that the id map was added
  #   assert graph.ids == %{test_id: [uid]}
  # end

  # #============================================================================
  # test "insert_at inserts a graph into a graph (this makes templates work)" do
  #   # create a simple graph to receive the incoming template
  #   graph = Graph.build()
  #   {graph, parent_uid} = Graph.insert_at(graph, -1, @empty_group)

  #   # give the parent graph a single input request
  #   # graph = Graph.request_input(graph, [:key, :char])

  #   #check that the setup is ok
  #   assert Graph.count(graph) == 2
  #   assert Graph.get_next_uid(graph) == 2

  #   # create the "template" graph to insert
  #   empty_group_with_id = Primitive.put_id(@empty_group, :t_tree)

  #   graph_t =           Graph.build(id: :template)
  #   {graph_t, _} =      Graph.insert_at(graph_t, -1, @empty_group)
  #   {graph_t, uid_1} =  Graph.insert_at(graph_t, -1, empty_group_with_id)
  #   {graph_t, _} =      Graph.insert_at({graph_t, uid_1}, -1, @empty_group)
  #   {graph_t, _} =      Graph.insert_at(graph_t, -1, @empty_group)

  #   # add a request for input
  #   # graph_t = Graph.request_input(graph_t, [:key, :cursor_down])

  #   #check that the setup is ok
  #   assert Graph.count(graph_t, -1) == 5
  #   assert Graph.get_next_uid(graph_t) == 5

  #   #insert the template
  #   {merged, uid} = Graph.insert_at({graph, parent_uid}, -1, graph_t, id: :test_id)

  #   #check the result
  #   assert Graph.count(merged, -1) == 7

  #   [t_uid] = Graph.resolve_id(merged, :template)
  #   assert t_uid == uid
  #   assert t_uid == 2
  #   assert Graph.count(merged, t_uid) == 5
  #   assert Graph.resolve_id(merged, :test_id) == [t_uid]

  #   # check that the template group's internal id was updated
  #   p = Graph.get(merged, uid)
  #   assert Primitive.get_uid(p) == uid

  #   [t_tree_uid] = Graph.resolve_id(merged, :t_tree)
  #   assert Graph.count(merged, t_tree_uid) == 2

  #   assert Graph.get_next_uid(merged) == 7

  #   # make sure the added tree is referenced by its new parent
  #   assert Primitive.get( Graph.get(merged, parent_uid) ) == [t_uid]
  #   assert Primitive.get_parent_uid( Graph.get(merged, t_uid) ) == parent_uid

  #   # make sure the template's input request was merged in without duplicates
  #   # assert Map.get(merged, :input) == [:key, :char, :cursor_down]
  # end


  #============================================================================
  # def modify( graph, uid, action )

  test "modify transforms a single primitive by developer id" do
    # confirm setup
    assert Map.get( Graph.get_id!(@graph_find, :inner_text), :transforms ) == nil

    # modify the element by assigning a transform to it
    graph = Graph.modify(@graph_find, :inner_text, fn(p)->
      Primitive.put_transforms( p, @transform )
    end)

    # confirm result
    assert Map.get( Graph.get_id!(graph, :inner_text), :transforms ) == @transform
  end

  test "modify transforms a multiple primitives by developer id" do
    graph = Graph.build()
    |> Text.add_to_graph( "Some text", id: :text  )
    |> Text.add_to_graph( "More text", id: :text)

    [uid_0, uid_1] = graph.ids[:text]

    # confirm setup
    assert Map.get( graph.primitives[uid_0], :transforms ) == nil
    assert Map.get( graph.primitives[uid_1], :transforms ) == nil

    # modify the element by assigning a transform to it
    graph = Graph.modify(graph, :text, fn(p)->
      Primitive.put_transforms( p, @transform )
    end)

    # confirm result
    assert Map.get( graph.primitives[uid_0], :transforms ) == @transform
    assert Map.get( graph.primitives[uid_1], :transforms ) == @transform
  end

  test "modify modifies transforms" do
    graph = Graph.build( rotate: 1.1 )
    |> Rectangle.add_to_graph({100, 200}, id: :rect, translate: {10,11})
    [uid] = graph.ids[:rect]

    graph = Graph.modify(graph, :rect, fn(p)->
      Primitive.put_transform(p, :rotate, 2.0)
    end)

    rect = graph.primitives[uid]
    assert Primitive.get_transforms(rect) == %{translate: {10,11}, rotate: 2.0}
  end

  test "modify modifies styles" do
    graph = Graph.build( rotate: 1.1 )
    |> Rectangle.add_to_graph({100, 200}, id: :rect, fill: :red)
    [uid] = graph.ids[:rect]

    graph = Graph.modify(graph, :rect, fn(p)->
      Primitive.put_style(p, :stroke, {10, :blue})
    end)

    rect = graph.primitives[uid]
    assert Primitive.get_styles(rect) == %{fill: :red, stroke: {10, :blue}}
  end

  #============================================================================
  # reduce(graph, acc, action) - whole tree

  test "reduce recurses over entire tree" do
    assert Graph.reduce(@graph_find, 0, fn(_, acc) ->
      acc + 1
    end) == 6
  end

  # reduce(graph, id, acc, action) - just mapped to id
  test "reduce reduces just nodes mapped to a mapped id" do
    graph = Graph.build()
    |> Text.add_to_graph( "Some text", id: :text  )
    |> Text.add_to_graph( "More text", id: :text  )
    |> Text.add_to_graph( "Other text", id: :other_text  )

    assert Graph.reduce(graph, :text, 0, fn(_, acc)->
      acc + 1
    end) == 2

    assert Graph.reduce(graph, :other_text, 0, fn(_, acc)->
      acc + 1
    end) == 1 
  end


  test "reduce honors max_depth" do
    graph = Map.put(@graph_find, :max_depth, 1)
        
    assert_raise Graph.Error, fn ->
      Graph.reduce(graph, 0, fn(_, acc)-> acc + 1 end)
    end
  end

  test "reduce honors max_depth default - with circular graph" do
    # set up a very simple circular graph
    graph = Graph.build()
    root = graph.primitives[@root_uid]
    |> Map.put(:data, [0])

    primitives = graph.primitives
    |> Map.put(@root_uid, root)
    graph = Map.put(graph, :primitives, primitives)

    assert_raise Graph.Error, fn ->
      Graph.reduce(graph, 0, fn(_, acc)-> acc + 1 end)
    end
  end


  #============================================================================
  # map(graph, action) - whole tree
  test "map recurses over entire tree" do
    # confirm setup
    assert Graph.reduce(@graph_find, true, fn(p,f) ->
      f && Map.get(p, :transforms) == nil
    end)

    graph = Graph.map(@graph_find, fn(p) ->
      Primitive.put_transforms( p, @transform )
    end)

    # confirm result
    assert Graph.reduce(graph, true, fn(p,f) ->
      f && Map.get(p, :transforms) == @transform
    end)
  end

  test "map honors max_depth" do
    graph = Map.put(@graph_find, :max_depth, 1)
        
    assert_raise Graph.Error, fn ->
      Graph.map(graph, fn(p)-> p end)
    end
  end

  test "map honors max_depth default - with circular graph" do
    # set up a very simple circular graph
    graph = Graph.build()
    root = graph.primitives[@root_uid]
    |> Map.put(:data, [0])
    primitives = graph.primitives
    |> Map.put(@root_uid, root)
    graph = Map.put(graph, :primitives, primitives)
    
    assert_raise Graph.Error, fn ->
      Graph.map(graph, fn(p)-> p end)
    end
  end

  #============================================================================
  # map_id(graph, id, action) - just mapped to id
  test "map_id only maps nodes with a mapped id" do
    graph = Graph.build()
    |> Text.add_to_graph( "Some text", id: :text  )
    |> Text.add_to_graph( "More text", id: :text  )
    |> Text.add_to_graph( "Other text", id: :other_text  )

    [t0, t1] = graph.ids[:text]
    [other] = graph.ids[:other_text]

    # confirm setup
    assert Map.get( graph.primitives[t0], :transforms )     == nil
    assert Map.get( graph.primitives[t1], :transforms )     == nil
    assert Map.get( graph.primitives[other], :transforms )  == nil

    graph = Graph.map(graph, :text, fn(p) ->
      Primitive.put_transforms( p, @transform )
    end)

    # confirm result
    assert Map.get( graph.primitives[t0], :transforms )     == @transform
    assert Map.get( graph.primitives[t1], :transforms )     == @transform
    assert Map.get( graph.primitives[other], :transforms )  == nil
  end

end











































