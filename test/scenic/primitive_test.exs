#
#  Created by Boyd Multerer on 5/7/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.PrimitiveTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive

  alias Scenic.Primitive
  alias Scenic.Primitive.Group
  # alias Scenic.Math.Matrix

  #  import IEx

  defmodule TestStyle do
    def get(_), do: :test_style_getter
  end

  # @identity     Matrix.identity()

  @tx_pin {10, 11}
  @tx_rotate 0.1
  @transforms %{pin: @tx_pin, rotate: @tx_rotate}

  @styles %{fill: :yellow, stroke: {10, :green}}

  # @parent_uid         123
  @type_module Group
  @data [1, 2, 3, 4, 5]

  @primitive %Primitive{
    module: @type_module,
    # uid:          nil,
    # parent_uid:   @parent_uid,
    data: @data,
    id: :test_id,
    transforms: @transforms,
    styles: @styles
  }
  @minimal_primitive %{
    data: {Group, @data},
    styles: %{
      fill: {:color, {255, 255, 0, 255}},
      stroke: {10, {:color, {0, 128, 0, 255}}}
    },
    transforms: %{pin: {10, 11}, rotate: 0.1},
    id: :test_id
  }

  @boring_primitive %Primitive{
    module: @type_module,
    data: []
  }
  @minimal_boring_primitive %{
    data: {Group, []},
    transforms: %{}
  }

  # @primitive_2 %Primitive{
  #   module:       @type_module,
  #   data:         @data,
  #   id:           {:test_id, 123},
  #   transforms:   @transforms,
  #   styles:       @styles,
  # }

  # ============================================================================
  # build( data, module, opts \\ [] )

  test "basic primitive build works" do
    assert Primitive.build(Group, @data) == %{
             __struct__: Primitive,
             module: Group,
             data: @data,
             parent_uid: -1
           }
  end

  # test "build sets the optional tag list" do
  #   assert Primitive.build(Group, @data, tags: [:one, "two"]) == %{
  #     __struct__: Primitive, module: Group, data: @data,
  #     tags: [:one, "two"]
  #   }
  # end

  test "build adds transform options" do
    assert Primitive.build(Group, @data, pin: {10, 11}, rotate: 0.1) == %{
             __struct__: Primitive,
             module: Group,
             data: @data,
             transforms: @transforms,
             parent_uid: -1
           }
  end

  test "build adds the style opts" do
    assert Primitive.build(Group, @data, fill: :yellow, stroke: {10, :green}) == %{
             __struct__: Primitive,
             module: Group,
             data: @data,
             styles: @styles,
             parent_uid: -1
           }
  end

  # test "build sets the optional state" do
  #   assert Primitive.build(Group, @data, state: @state) == %{
  #     __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
  #     state: @state
  #   }
  # end

  test "build sets the optional id" do
    assert Primitive.build(Group, @data, id: :test_id) == %{
             __struct__: Primitive,
             module: Group,
             data: @data,
             id: :test_id,
             parent_uid: -1
           }
  end

  test "build sets a non-atom id" do
    assert Primitive.build(Group, @data, id: {:test_id, 123}) == %{
             __struct__: Primitive,
             module: Group,
             data: @data,
             id: {:test_id, 123},
             parent_uid: -1
           }
  end

  test "build raises on bad tx" do
    assert_raise Primitive.Transform.FormatError, fn ->
      Primitive.build(Group, @data, rotate: :invalid)
    end
  end

  test "build raises on bad style" do
    assert_raise Primitive.Style.FormatError, fn ->
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
    assert_raise Primitive.Error, fn ->
      Primitive.put(@primitive, :banana)
    end
  end

  test "put updates the options on a primitive" do
    assert Primitive.put(@primitive, [1, 2, 5, 6], fill: :blue).styles == %{
             fill: :blue,
             stroke: {10, :green}
           }
  end

  test "put rejects invalid style" do
    assert_raise Primitive.Style.FormatError, fn ->
      Primitive.put(@primitive, [1, 2, 5, 6], fill: :invalid)
    end
  end

  test "put rejects invalid transform" do
    assert_raise Primitive.Transform.FormatError, fn ->
      Primitive.put(@primitive, [1, 2, 5, 6], rotate: :invalid)
    end
  end

  # --------------------------------------------------------
  # put

  test "put_opts updates only the options on a primitive" do
    assert Primitive.put_opts(@primitive, fill: :blue).styles == %{
             fill: :blue,
             stroke: {10, :green}
           }
  end

  test "put_opts rejects invalid style" do
    assert_raise Primitive.Style.FormatError, fn ->
      Primitive.put_opts(@primitive, fill: :invalid)
    end
  end

  test "put_opts rejects invalid transform" do
    assert_raise Primitive.Transform.FormatError, fn ->
      Primitive.put_opts(@primitive, rotate: :invalid)
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

  test "put_transform puts a list of transforms" do
    p = Primitive.put_transform(@primitive, pin: {1, 2}, scale: 1.2)

    assert Primitive.get_transforms(p) == %{
             pin: {1, 2},
             scale: 1.2,
             rotate: @tx_rotate
           }
  end

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
    assert Primitive.get_style(@primitive, :fill) == :yellow
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
             fill: :yellow,
             stroke: {10, :green}
           }
  end

  test "put_style replaces a style in the style map" do
    p =
      @primitive
      |> Primitive.put_style(:fill, :khaki)
      |> Primitive.put_style(:fill, :cornsilk)

    assert Primitive.get_styles(p) == %{fill: :cornsilk, stroke: {10, :green}}
  end

  test "put_style a list of styles" do
    new_styles = %{fill: :magenta, stroke: {4, :green}}
    p = Primitive.put_style(@primitive, fill: :magenta, stroke: {4, :green})
    assert Primitive.get_styles(p) == new_styles
  end

  test "delete_style removes a style in the style list" do
    assert Primitive.delete_style(@primitive, :fill)
           |> Primitive.get_styles() == %{stroke: {10, :green}}
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

  # ============================================================================
  # data for the viewport

  # --------------------------------------------------------
  # minimal
  test "minimal returns the minimal version of the prmitive" do
    assert Primitive.minimal(@primitive) == @minimal_primitive
  end

  test "minimal returns the minimal version of a boring primitive" do
    assert Primitive.minimal(@boring_primitive) == @minimal_boring_primitive
  end

  # --------------------------------------------------------
  # NOTE: KEEP THIS AROUND for now

  # delta_script
  # test "delta_script returns an empty list if there is no change" do
  #   assert Primitive.delta_script(@primitive, @primitive) == []
  # end

  # test "delta_script picks up change to data" do
  #   p = Primitive.put(@primitive, [1,2,3])
  #   assert Primitive.delta_script(@primitive, p) == [{:put, :data, {Group, [1, 2, 3]}}]
  # end

  # test "delta_script picks up change to module" do
  #   p = Map.put(@primitive, :module, Primitive.Line)
  #   assert Primitive.delta_script(@primitive, p) == [{:put, :data, {Scenic.Primitive.Line, [1, 2, 3, 4, 5]}}]
  # end

  # test "delta_script picks up addition to style" do
  #   p = Primitive.put_style(@primitive, :hidden, true)
  #   assert Primitive.delta_script(@primitive, p) == [{:put, {:styles, :hidden}, true}]
  # end

  # test "delta_script picks up style deletion" do
  #   p = Primitive.put_style(@primitive, :fill, nil)
  #   assert Primitive.delta_script(@primitive, p) == [{:del, {:styles, :fill}}]
  # end

  # test "delta_script picks up addition to transforms" do
  #   p = Primitive.put_transform(@primitive, :translate, {12,23})
  #   assert Primitive.delta_script(@primitive, p) == [{:put, {:transforms, :translate}, {12, 23}}]
  # end

  # test "delta_script picks up transform deletion" do
  #   p = Primitive.put_transform(@primitive, :translate, {12,23})
  #   pd = Primitive.put_transform(@primitive, :translate, nil)
  #   assert Primitive.delta_script(p, pd) == [del: {:transforms, :translate}]
  # end
end
