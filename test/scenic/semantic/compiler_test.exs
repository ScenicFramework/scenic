defmodule Scenic.Semantic.CompilerTest do
  use ExUnit.Case
  alias Scenic.Graph
  alias Scenic.Primitives
  alias Scenic.Semantic.Compiler
  alias Scenic.Semantic.Compiler.Entry

  describe "compile/2" do
    test "compiles empty graph" do
      graph = Graph.build()
      {:ok, entries} = Compiler.compile(graph)
      # Root group has no ID, so not registered
      assert entries == []
    end

    test "compiles rectangle with ID" do
      graph =
        Graph.build()
        |> Primitives.rectangle({100, 50}, id: :my_rect)

      {:ok, entries} = Compiler.compile(graph)

      assert length(entries) == 1
      entry = hd(entries)

      assert entry.id == :my_rect
      assert entry.type == :rect
      assert entry.module == Scenic.Primitive.Rectangle
      assert entry.local_bounds == %{left: 0, top: 0, width: 100, height: 50}
    end

    test "compiles circle with ID" do
      graph =
        Graph.build()
        |> Primitives.circle(25, id: :my_circle)

      {:ok, entries} = Compiler.compile(graph)

      assert length(entries) == 1
      entry = hd(entries)

      assert entry.id == :my_circle
      assert entry.type == :circle
      # Circle bounds centered at origin
      assert entry.local_bounds == %{left: -25, top: -25, width: 50, height: 50}
    end

    test "compiles text with semantic label" do
      graph =
        Graph.build()
        |> Primitives.text("Hello", id: :my_text)

      {:ok, entries} = Compiler.compile(graph)

      assert length(entries) == 1
      entry = hd(entries)

      assert entry.id == :my_text
      assert entry.type == :text
      assert entry.label == "Hello"
    end

    test "ignores primitives without ID" do
      graph =
        Graph.build()
        |> Primitives.rectangle({100, 50})
        |> Primitives.circle(25)

      {:ok, entries} = Compiler.compile(graph)

      # No IDs, so nothing should be registered
      assert entries == []
    end

    test "compiles primitive with explicit semantic metadata" do
      graph =
        Graph.build()
        |> Primitives.rectangle(
          {100, 50},
          semantic: %{
            id: :custom_button,
            type: :button,
            clickable: true,
            label: "Click Me"
          }
        )

      {:ok, entries} = Compiler.compile(graph)

      assert length(entries) == 1
      entry = hd(entries)

      assert entry.id == :custom_button
      assert entry.type == :button
      assert entry.clickable == true
      assert entry.label == "Click Me"
    end

    test "compiles group with multiple children" do
      graph =
        Graph.build()
        |> Primitives.group(
          fn g ->
            g
            |> Primitives.rectangle({100, 50}, id: :rect1)
            |> Primitives.rectangle({200, 100}, id: :rect2)
          end,
          id: :my_group
        )

      {:ok, entries} = Compiler.compile(graph)

      # Should have 3 entries: group + 2 rectangles
      assert length(entries) == 3

      # Find the group entry
      group_entry = Enum.find(entries, fn e -> e.id == :my_group end)
      assert group_entry != nil
      assert group_entry.type == :group

      # Find the rectangle entries
      rect1 = Enum.find(entries, fn e -> e.id == :rect1 end)
      assert rect1 != nil
      assert rect1.parent_id == :my_group

      rect2 = Enum.find(entries, fn e -> e.id == :rect2 end)
      assert rect2 != nil
      assert rect2.parent_id == :my_group
    end

    test "handles hidden primitives" do
      graph =
        Graph.build()
        |> Primitives.rectangle(
          {100, 50},
          id: :hidden_rect,
          hidden: true
        )

      {:ok, entries} = Compiler.compile(graph)

      assert length(entries) == 1
      entry = hd(entries)

      assert entry.id == :hidden_rect
      assert entry.hidden == true
    end

    test "sets z_index based on tree depth" do
      graph =
        Graph.build()
        |> Primitives.rectangle({100, 50}, id: :rect1)
        |> Primitives.group(
          fn g ->
            g
            |> Primitives.rectangle({200, 100}, id: :rect2)
          end,
          id: :group1
        )

      {:ok, entries} = Compiler.compile(graph)

      rect1 = Enum.find(entries, fn e -> e.id == :rect1 end)
      group1 = Enum.find(entries, fn e -> e.id == :group1 end)
      rect2 = Enum.find(entries, fn e -> e.id == :rect2 end)

      # rect1 is at root level (z=0), group1 at z=1, rect2 at z=2
      assert rect1.z_index == 0
      assert group1.z_index == 1
      assert rect2.z_index == 2
    end
  end

  describe "Entry struct" do
    test "has sensible defaults" do
      entry = %Entry{id: :test}

      assert entry.id == :test
      assert entry.clickable == false
      assert entry.focusable == false
      assert entry.hidden == false
      assert entry.z_index == 0
      assert entry.children == []
      assert entry.local_bounds == %{left: 0, top: 0, width: 0, height: 0}
    end
  end
end
