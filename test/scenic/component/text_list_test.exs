defmodule Scenic.Component.TextListTest do
  use ExUnit.Case, async: true
  doctest Scenic

  # alias Scenic.Component
  alias Scenic.Graph
  alias Scenic.Component.TextList

  # ============================================================================
  # info

  test "info works" do
    assert is_bitstring(TextList.info(:bad_data))
    assert TextList.info(:bad_data) =~ ":bad_data"
  end

  # ============================================================================
  # verify

  test "verify passes valid data" do
    assert TextList.verify(["A", "B"]) == {:ok, ["A", "B"]}
  end

  test "verify fails invalid data" do
    assert TextList.verify(:banana) == :invalid_data
  end

  # ============================================================================
  # init

  test "init works with simple list" do
    {:ok, state, push: graph} = TextList.init(["A", "B"], styles: %{})
    %Graph{} = state.graph
    assert graph == state.graph
  end

  test "init builds a group of text primitives from list" do
    {:ok, _state, push: graph} = TextList.init(["A", "B"], styles: %{})
    assert Enum.count(graph.primitives) == 3
    assert graph.primitives[0].module == Scenic.Primitive.Group
    assert graph.primitives[1].module == Scenic.Primitive.Text
    assert graph.primitives[2].module == Scenic.Primitive.Text
  end

  test "init passes styles to text primitives" do
    styles = %{font_size: 24, fill: :green}
    {:ok, _state, push: graph} = TextList.init(["A", "B"], styles: styles)
    assert graph.primitives[1].styles.fill == :green
    assert graph.primitives[2].styles.fill == :green
    assert graph.primitives[1].styles.font_size == 24
    assert graph.primitives[2].styles.font_size == 24
  end

  test "init passes transforms to text primitives and they increment correctly" do
    styles = %{font_size: 18, t: {0, 20}}
    {:ok, _state, push: graph} = TextList.init(["A", "B"], styles: styles)
    assert graph.primitives[1].transforms.translate == {0, 20}
    assert graph.primitives[2].transforms.translate == {0, 40}
  end

end
