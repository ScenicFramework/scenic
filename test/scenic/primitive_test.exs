#
#  Created by Boyd Multerer on 2017-05-07.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.PrimitiveTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive

  alias Scenic.Primitive
  alias Scenic.Primitive.Group

  #  import IEx

  defmodule TestStyle do
    def get(_), do: :test_style_getter
  end

  @tx_pin {10, 11}
  @tx_rotate 0.1
  @transforms %{pin: @tx_pin, rotate: @tx_rotate}

  @styles %{line_height: 2}

  @type_module Group
  @data [1, 2, 3, 4, 5]

  @primitive %Primitive{
    module: @type_module,
    data: @data,
    id: :test_id,
    transforms: @transforms,
    styles: @styles
  }

  # ============================================================================
  # build( data, module, opts \\ [] )

  test "basic primitive build works" do
    assert Primitive.build(Group, @data) == %{
             __struct__: Primitive,
             module: Group,
             data: @data,
             parent_uid: -1,
             id: nil,
             opts: [],
             styles: %{},
             transforms: %{},
             default_pin: {0, 0}
           }
  end

  test "build sets the optional parameters" do
    assert Primitive.build(Group, @data, custom_field: 123) == %{
             __struct__: Primitive,
             module: Group,
             data: @data,
             parent_uid: -1,
             id: nil,
             opts: [custom_field: 123],
             styles: %{},
             transforms: %{},
             default_pin: {0, 0}
           }
  end

  test "build adds transform options" do
    assert Primitive.build(Group, @data, pin: {10, 11}, rotate: 0.1) == %{
             __struct__: Primitive,
             module: Group,
             data: @data,
             parent_uid: -1,
             id: nil,
             opts: [],
             styles: %{},
             transforms: %{pin: {10, 11}, rotate: 0.1},
             default_pin: {0, 0}
           }
  end

  test "build adds the style opts" do
    assert Primitive.build(Group, @data, fill: :yellow) == %{
             __struct__: Primitive,
             module: Group,
             data: @data,
             parent_uid: -1,
             id: nil,
             opts: [],
             styles: %{fill: {:color, {:color_rgba, {255, 255, 0, 255}}}},
             transforms: %{},
             default_pin: {0, 0}
           }
  end

  test "build sets the optional id" do
    assert Primitive.build(Group, @data, id: :test_id) == %{
             __struct__: Primitive,
             module: Group,
             data: @data,
             parent_uid: -1,
             id: :test_id,
             opts: [],
             styles: %{},
             transforms: %{},
             default_pin: {0, 0}
           }
  end

  test "build sets a non-atom id" do
    assert Primitive.build(Group, @data, id: {:test_id, 123}) == %{
             __struct__: Primitive,
             module: Group,
             data: @data,
             parent_uid: -1,
             id: {:test_id, 123},
             opts: [],
             styles: %{},
             transforms: %{},
             default_pin: {0, 0}
           }
  end

  test "build raises on bad tx" do
    assert_raise RuntimeError, fn ->
      Primitive.build(Group, @data, rotate: :invalid)
    end
  end

  test "build raises on bad style" do
    assert_raise RuntimeError, fn ->
      Primitive.build(Group, @data, fill: :invalid)
    end
  end

  # ============================================================================
  # structure

  # --------------------------------------------------------
  # put

  test "put updates a primitives data field" do
    assert Primitive.put(@primitive, [1, 2, 5, 6]).data == [1, 2, 5, 6]
  end

  test "put rejects invalid data for a primitive" do
    assert_raise RuntimeError, fn ->
      Primitive.put(@primitive, :banana)
    end
  end

  test "put updates the options on a primitive" do
    assert Primitive.put(@primitive, [1, 2, 5, 6], fill: :blue).styles == %{
             fill: {:color, {:color_rgba, {0, 0, 255, 255}}},
             line_height: 2
           }
  end

  test "put rejects invalid style" do
    assert_raise RuntimeError, fn ->
      Primitive.put(@primitive, [1, 2, 5, 6], fill: :invalid)
    end
  end

  test "put rejects invalid transform" do
    assert_raise RuntimeError, fn ->
      Primitive.put(@primitive, [1, 2, 5, 6], rotate: :invalid)
    end
  end

  # --------------------------------------------------------
  # merge_opts

  test "merge_opts updates only the options on a primitive" do
    assert Primitive.merge_opts(@primitive, fill: :blue).styles == %{
             fill: {:color, {:color_rgba, {0, 0, 255, 255}}},
             line_height: 2
           }
  end

  test "merge_opts rejects invalid style" do
    assert_raise RuntimeError, fn ->
      Primitive.merge_opts(@primitive, fill: :invalid)
    end
  end

  test "merge_opts rejects invalid transform" do
    # assert_raise Primitive.Transform.FormatError, fn ->
    assert_raise RuntimeError, fn ->
      Primitive.merge_opts(@primitive, rotate: :invalid)
    end
  end

  # ============================================================================
  # transform field

  test "get_transforms returns the transforms" do
    assert Primitive.get_transforms(@primitive) == @transforms
  end

  test "get_transform returns the transform" do
    assert Primitive.get_transform(@primitive, :pin) == @tx_pin
  end

  test "put_transform sets the transform" do
    p = Primitive.put_transform(@primitive, :pin, {987, 654})
    assert Primitive.get_transform(p, :pin) == {987, 654}
  end

  # deprecated - use merge_opts
  # test "put_transform puts a list of transforms" do
  #   p = Primitive.put_transform(@primitive, pin: {1, 2}, scale: 1.2)

  #   assert Primitive.get_transforms(p) == %{
  #            pin: {1, 2},
  #            scale: 1.2,
  #            rotate: @tx_rotate
  #          }
  # end

  test "put_transform deletes the transform type if setting to nil" do
    p = Primitive.put_transform(@primitive, :pin, nil)
    assert Primitive.get_transforms(p) == %{rotate: @tx_rotate}
  end

  test "put_transforms sets the transform to nil" do
    p = Primitive.put_transforms(@primitive, nil)
    assert Map.get(p, :transforms) == nil
  end

  test "delete_transform removes a transform" do
    assert Primitive.delete_transform(@primitive, :pin)
           |> Primitive.get_transforms() == %{rotate: 0.1}
  end

  # ============================================================================
  # style field

  # --------------------------------------------------------
  # styles

  test "get_styles returns the transform list" do
    assert Primitive.get_styles(@primitive) == @styles
  end

  test "get_style returns a style by key" do
    assert Primitive.get_style(@primitive, :line_height) == 2
  end

  test "get_style returns nil if missing by default" do
    assert Primitive.get_style(@primitive, :missing) == nil
  end

  test "get_style returns default if missing" do
    assert Primitive.get_style(@primitive, :missing, "default") == "default"
  end

  test "put_style adds to the style map" do
    p = Primitive.put_style(@primitive, :font, :roboto)

    assert Primitive.get_styles(p) == %{
             font: :roboto,
             line_height: 2
           }
  end

  test "put_style replaces a style in the style map" do
    p =
      @primitive
      |> Primitive.put_style(:line_height, 3)
      |> Primitive.put_style(:fill, :blue)
      |> Primitive.put_style(:fill, :cornsilk)

    assert Primitive.get_styles(p) ==
             %{fill: {:color, {:color_rgba, {255, 248, 220, 255}}}, line_height: 3}
  end

  test "delete_style removes a style in the style list" do
    assert Primitive.delete_style(@primitive, :line_height)
           |> Primitive.get_styles() == %{}
  end

  test "merge_opts sets a list of styles" do
    p = Primitive.merge_opts(@primitive, fill: :magenta, stroke: {2, :green})

    assert Primitive.get_styles(p) == %{
             fill: {:color, {:color_rgba, {255, 0, 255, 255}}},
             stroke: {2, {:color, {:color_rgba, {0, 128, 0, 255}}}},
             line_height: 2
           }
  end

  test "merge_opts sets a list of transforms" do
    new_txs = %{translate: {1, 2}, rotate: 1.23, pin: {10, 11}}
    p = Primitive.merge_opts(@primitive, translate: {1, 2}, rotate: 1.23)
    assert Primitive.get_transforms(p) == new_txs
  end

  # ============================================================================
  # data field

  # --------------------------------------------------------
  # compiled primitive-specific data

  test "get_data returns the primitive-specific compiled data" do
    assert Primitive.get(@primitive) == @data
  end

  test "put_data replaces the primitive-specific compiled data" do
    new_data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    p = Primitive.put(@primitive, new_data)
    assert Primitive.get(p) == new_data
  end
end
