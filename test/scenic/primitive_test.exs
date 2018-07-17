#
#  Created by Boyd Multerer on 5/7/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.PrimitiveTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Group
  alias Scenic.Math.Matrix

#  import IEx

  defmodule TestStyle do
    def get(_), do: :test_style_getter
  end


  @identity     Matrix.identity()


  @tx_pin             {10,11}
  @tx_rotate          0.1
  @transforms         %{pin: @tx_pin, rotate: @tx_rotate}

  @styles             %{fill: :yellow, stroke: {10, :green}}

  @parent_uid         123
  @type_module        Group
  @event_filter       {:module, :action}
  @tag_list           ["tag0", :tag1]
  @state              {:app,:state}
  @data               [1,2,3,4,5]


  @primitive %Primitive{
    module:       @type_module,
    uid:          nil,
    parent_uid:   @parent_uid,
    data:         @data,
    id:           :test_id,
    tags:         @tag_list,
    event_filter: @event_filter,
    state:        @state,
    transforms:   @transforms,
    styles:       @styles,
  }

  @minimal_primitive   %{
    data:       {Group, @data},
    styles:     %{
      fill: {:color, {255, 255, 0, 255}},
      stroke: {10, {:color, {0, 128, 0, 255}}}
      },
    transforms: %{pin: {10, 11}, rotate: 0.1},
    id: :test_id
  }

  #============================================================================
  # build( data, module, opts \\ [] )

  test "basic primitive build works" do
    assert Primitive.build(Group, @data) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data
    }
  end

  # test "build sets the optional event handler" do
  #   assert Primitive.build(Group, @data, event_filter: @event_filter) == %{
  #     __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
  #     event_filter: @event_filter
  #   }
  # end

  test "build sets the optional tag list" do
    assert Primitive.build(Group, @data, tags: [:one, "two"]) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
      tags: [:one, "two"]
    }
  end

  test "build adds transform options" do
    assert Primitive.build(Group, @data, pin: {10,11}, rotate: 0.1) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
      transforms: @transforms
    }
  end


  test "build adds the style opts" do
    assert Primitive.build(Group, @data, fill: :yellow, stroke: {10, :green}) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
      styles: @styles
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
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
      id: :test_id
    }
  end

  test "build sets a non-atom id" do
    assert Primitive.build(Group, @data, id: {:test_id, 123}) == %{
      __struct__: Primitive, module: Group, uid: nil, parent_uid: -1, data: @data,
      id: {:test_id, 123}
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

  #============================================================================
  # structure

  #--------------------------------------------------------
  # put

  test "put updates a primitives data field" do
    assert Primitive.put(@primitive, [1,2,5,6]).data == [1,2,5,6]
  end

  test "put rejects invalid data for a primitive" do
    assert_raise Primitive.Error, fn ->
      Primitive.put(@primitive, :banana)
    end
  end

  test "put updates the options on a primitive" do
    assert Primitive.put(@primitive, [1,2,5,6], fill: :blue).styles == %{
      fill: :blue,
      stroke: {10, :green}
    }
  end

  test "put rejects invalid options" do
    assert_raise Primitive.Error, fn ->
      Primitive.put(@primitive, [1,2,5,6], [id: [:invalid]])
    end
  end

  #--------------------------------------------------------
  # put

  test "put_opts updates only the options on a primitive" do
    assert Primitive.put_opts(@primitive, fill: :blue).styles == %{
      fill: :blue,
      stroke: {10, :green}
    }
  end

  test "put_opts rejects invalid options" do
    assert_raise Primitive.Error, fn ->
      Primitive.put_opts(@primitive, [id: [:invalid]])
    end
  end


  #--------------------------------------------------------
  # module

  test "get_module returns the type module" do
    assert Primitive.get_module(@primitive) == @type_module
  end

  #--------------------------------------------------------
  # uid

  test "get_uid and do_put_uid manipulate the internal uid" do
    assert Primitive.put_uid(@primitive, 987) |> Primitive.get_uid() == 987
  end

  #--------------------------------------------------------
  # the parent group uid in the graph
  
  test "get_parent_uid returns the uid of the parent." do
    assert Primitive.get_parent_uid(@primitive) == @parent_uid
  end

  test "put_parent_uid sets a parent uid into place" do
    assert Primitive.put_parent_uid(@primitive, 987) |> Primitive.get_parent_uid() == 987
  end

  #--------------------------------------------------------
  # id

  test "get_id returns the internal id." do
    assert Primitive.get_id(@primitive) == :test_id
  end

  test "do_put_id sets the internal id" do
    assert Primitive.put_id(@primitive, :other) |> Primitive.get_id() == :other
  end

  #--------------------------------------------------------
  # searchable tags - can be strings or atoms or integers

  test "get_tags returns the tags" do
    assert Primitive.get_tags(@primitive) == @tag_list
  end

  test "put_tags sets the tag list" do
    tags = ["new", :list, 123]
    primitive = Primitive.put_tags(@primitive, tags)
    assert Primitive.get_tags(primitive) == tags
  end

  test "has_tag? returns true if the tag is in the tag list" do
    assert Primitive.has_tag?(@primitive, "tag0") == true
    assert Primitive.has_tag?(@primitive, :tag1) == true
  end

  test "has_tag? returns false if the tag is not the tag list" do
    assert Primitive.has_tag?(@primitive, "missing") == false
    assert Primitive.has_tag?(@primitive, :missing) == false
  end

  test "put_tag adds a tag to the front of the tag list" do
    assert Primitive.put_tag(@primitive, "new") |> Primitive.get_tags() == ["new" | @tag_list]
    assert Primitive.put_tag(@primitive, :new)  |> Primitive.get_tags() == [:new | @tag_list]
    assert Primitive.put_tag(@primitive, 123)   |> Primitive.get_tags() == [123 | @tag_list]
  end

  test "put_tag does nothing if the tag is already in the list" do
    assert Primitive.put_tag(@primitive, "tag0") |> Primitive.get_tags()  == @tag_list
    assert Primitive.put_tag(@primitive, :tag1)  |> Primitive.get_tags()  == @tag_list
  end

  test "delete_tag deletes a tag from the tag list" do
    assert (Primitive.delete_tag(@primitive, "tag0") |> Primitive.get_tags()) == [:tag1]
    assert (Primitive.delete_tag(@primitive, :tag1)  |> Primitive.get_tags()) == ["tag0"]
  end


  #--------------------------------------------------------
  # the handler for input events

  # test "get_event_filter returns the event handler." do
  #   assert Primitive.get_event_filter(@primitive) == @event_filter
  # end

  # test "put_event_filter sets the event handler as {module,action}" do
  #   p = Primitive.put_event_filter(@primitive, { :mod, :act } )
  #   assert Primitive.get_event_filter(p) == { :mod, :act }
  # end

  # test "put_event_filter sets the event handler to a function" do
  #   p = Primitive.put_event_filter(@primitive, fn(_a,_b,_c) -> nil end)
  #   assert is_function(Primitive.get_event_filter(p), 3)
  # end

  # test "put_event_filter sets the event handler to nil" do
  #   p = Primitive.put_event_filter(@primitive, { :mod, :act } )
  #   assert Primitive.get_event_filter(p) == { :mod, :act }
  #   p = Primitive.put_event_filter(@primitive, nil )
  #   assert Primitive.get_event_filter(p) == nil
  # end

  # #--------------------------------------------------------
  # test "delete_event_filter sets the event filter to nil" do
  #   p = Primitive.put_event_filter(@primitive, { :mod, :act } )
  #   assert Primitive.get_event_filter(p) == { :mod, :act }
  #   p = Primitive.delete_event_filter( @primitive )
  #   assert Primitive.get_event_filter(p) == nil
  # end

  #============================================================================
  # transform field

  test "get_transforms returns the transforms" do
    assert Primitive.get_transforms(@primitive) == @transforms
  end

  test "get_transform returns the transform" do
    assert Primitive.get_transform(@primitive, :pin) == @tx_pin
  end

  test "put_transform sets the transform" do
    p = Primitive.put_transform(@primitive, :pin, {987,654})
    assert Primitive.get_transform(p, :pin) == {987,654}
  end

  test "put_transform puts a list of transforms" do
    p = Primitive.put_transform(@primitive, [pin: {1,2}, scale: 1.2] )
    assert Primitive.get_transforms(p) == %{
      pin:    {1,2},
      scale:  1.2,
      rotate: @tx_rotate
    }
  end

  test "put_transform deletes the transform type if setting to nil" do
    p = Primitive.put_transform(@primitive, :pin, nil)
    assert Primitive.get_transforms(p) == %{ rotate: @tx_rotate }
  end

  test "put_transforms sets the transform to nil" do
    p = Primitive.put_transforms(@primitive, nil)
    assert Map.get(p, :transforms) == nil
  end


  test "calculate_transforms calculates both the local and inverse transforms" do
    refute Map.get(@primitive, :local_tx)
    refute Map.get(@primitive, :inverse_tx)

    p = Primitive.calculate_transforms( @primitive, @identity )

    assert Map.get(p, :local_tx)
    assert Map.get(p, :inverse_tx)
  end


  test "calculate_transforms deletes existing local_tx and inverse_tx if transforms is now empty or nil" do
    p = Primitive.calculate_transforms( @primitive, @identity )
    assert Map.get(p, :local_tx)
    assert Map.get(p, :inverse_tx)

    # delete the transforms map without actually deleting local_tx and inverse_tx
    p = Map.delete( p, :transforms )
    p = Primitive.calculate_transforms( p, @identity )

    refute Map.get(p, :local_tx)
    refute Map.get(p, :inverse_tx)
  end


  test "calculate_inverse_transform calculates only the inverse transform" do
    p = Primitive.calculate_transforms( @primitive, @identity )
    original_local   = Map.get(p, :local_tx)
    original_inverse = Map.get(p, :inverse_tx)
    assert original_local
    assert original_inverse

    # change the transform map, so that local would change if this was calculate_transforms
    p = Map.put(p, :transforms, %{scale: 1.7})

    # calculate the inverse transform with some parent_tx other than identity
    other_tx = Matrix.build_rotation(0.387)
    p = Primitive.calculate_inverse_transform(p, other_tx)
    after_local   = Map.get(p, :local_tx)
    after_inverse = Map.get(p, :inverse_tx)

    # assert that the inverse changed, but that local did not
    assert original_local == after_local
    assert original_inverse != after_inverse
  end

  test "calculate_inverse_transform does nothing if the local_tx is nil" do
    refute Map.get(@primitive, :local_tx)
    refute Map.get(@primitive, :inverse_tx)

    p = Primitive.calculate_inverse_transform( @primitive, @identity )

    refute Map.get(p, :local_tx)
    refute Map.get(p, :inverse_tx)
  end


  #============================================================================
  # style field

  #--------------------------------------------------------
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
    p = Primitive.put_style(@primitive, :font, :roboto )
    assert Primitive.get_styles(p) == %{
      font: :roboto,
      fill: :yellow,
      stroke: {10, :green}
    }
  end

  test "put_style replaces a style in the style map" do
    p = @primitive
      |> Primitive.put_style( :fill, :khaki )
      |> Primitive.put_style( :fill, :cornsilk )
    assert Primitive.get_styles(p) == %{fill: :cornsilk, stroke: {10, :green}}
  end

  test "put_style a list of styles" do
    new_styles = %{fill: :magenta, stroke: {4, :green}}
    p = Primitive.put_style(@primitive, [fill: :magenta, stroke: {4, :green}] )
    assert Primitive.get_styles(p) == new_styles
  end

  test "drop_style removes a style in the style list" do
    assert Primitive.drop_style(@primitive, :fill )
    |> Primitive.get_styles() == %{stroke: {10, :green}}
  end


  #============================================================================
  # data field

  #--------------------------------------------------------
  # compiled primitive-specific data

  test "get_data returns the primitive-specific compiled data" do
    assert Primitive.get(@primitive) == @data
  end

  test "put_data replaces the primitive-specific compiled data" do
    new_data = [1,2,3,4,5,6,7,8,9,10]
    p = Primitive.put(@primitive, new_data )
    assert Primitive.get(p) == new_data
  end

  #--------------------------------------------------------
  # app controlled state

  test "get_state gets the application state" do
    assert Primitive.get_state(@primitive) == @state
  end

  test "put_state replaces the application state" do
    p = Primitive.put_state(@primitive, {:def, 123})
    assert Primitive.get_state(p) == {:def, 123}
  end

  #============================================================================
  # data for the viewport

  #--------------------------------------------------------
  # minimal
  test "minimal returns the minimal version of the prmitive" do
    assert Primitive.minimal(@primitive) == @minimal_primitive
  end


  #--------------------------------------------------------
  # delta_script
  test "delta_script returns an empty list if there is no change" do
    assert Primitive.delta_script(@primitive, @primitive) == []
  end

  test "delta_script picks up change to data" do
    p = Primitive.put(@primitive, [1,2,3])
    assert Primitive.delta_script(@primitive, p) == [{:put, :data, {Group, [1, 2, 3]}}]
  end

  test "delta_script picks up change to module" do
    p = Map.put(@primitive, :module, Primitive.Line)
    assert Primitive.delta_script(@primitive, p) == [{:put, :data, {Scenic.Primitive.Line, [1, 2, 3, 4, 5]}}]
  end

  # test "delta_script picks up change to parent uid" do
  #   p = Map.put(@primitive, :parent_uid, 12)
  #   assert Primitive.delta_script(@primitive, p) == [{:put, :puid, 12}]
  # end

  test "delta_script picks up addition to style" do
    p = Primitive.put_style(@primitive, :hidden, true)
    assert Primitive.delta_script(@primitive, p) == [{:put, {:styles, :hidden}, true}]
  end

  test "delta_script picks up style deletion" do
    p = Primitive.put_style(@primitive, :fill, nil)
    assert Primitive.delta_script(@primitive, p) == [{:del, {:styles, :fill}}]
  end

  test "delta_script picks up addition to transforms" do
    p = Primitive.put_transform(@primitive, :translate, {12,23})
    assert Primitive.delta_script(@primitive, p) == [{:put, {:transforms, :translate}, {12, 23}}]
  end

  test "delta_script picks up transform deletion" do
    p = Primitive.put_transform(@primitive, :translate, {12,23})
    pd = Primitive.put_transform(@primitive, :translate, nil)
    assert Primitive.delta_script(p, pd) == [del: {:transforms, :translate}]
  end

end

















