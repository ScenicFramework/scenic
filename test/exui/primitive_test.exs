#
#  Created by Boyd Multerer on 5/7/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.PrimitiveTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Group
  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Transform
  alias Scenic.Math.MatrixBin

#  import IEx

  defmodule TestStyle do
    def get(_), do: :test_style_getter
  end


  @tx_pin             {10,11}
  @tx_rot             0.1
  @transform          Transform.build(pin: @tx_pin, rot: @tx_rot)

  @style_1            Style.LineWidth.build(3)
  @style_2            Style.Color2.build(:red, :yellow)
  @styles             [@style_1, @style_2]

  @parent_uid         123
  @type_module        Group
  @event_filter       {:module, :action}
  @tag_list           ["tag0", :tag1]
  @state              {:app,:state}
  @compiled_data      "test compiled data"


  @primitive %{
    __struct__:   Primitive,
    module:       @type_module,
    uid:          nil,
    parent_uid:   @parent_uid,
    id:           :test_id,
    tags:         @tag_list,
    event_filter: @event_filter,
    transform:    @transform,
    styles:       @styles,
    compiled:     @compiled_data,
    state:        @state
  }


  #============================================================================
  # shared stuff
  test "type_code gets the correct type code for the primitive" do
    assert Primitive.type_code(@primitive) == Group.type_code()
  end

  #============================================================================
  # build( data, module, opts \\ [] )

  test "basic primitive build works" do
    %Primitive{
      module: Group, uid: nil, parent_uid: -1, id: nil, tags: [],
      event_filter: nil, transform: nil, styles: [],
      compiled: "test data", state: nil
    } = Primitive.build("test data", Group)
  end

  test "build sets the optional event handler" do
    %Primitive{
      module: Group, uid: nil, parent_uid: -1, id: nil, tags: [],
      event_filter: @event_filter, transform: nil, styles: [],
      compiled: "td", state: nil
    } = Primitive.build("td", Group, event_filter: @event_filter)
  end

  test "build sets the optional tag list" do
    %Primitive{
      module: Group, uid: nil, parent_uid: -1, id: nil, tags: [:one, "two"],
      event_filter: nil, transform: nil, styles: [],
      compiled: "td", state: nil
    } = Primitive.build("td", Group, tags: [:one, "two"])
  end

  test "build passes transform options through" do
    %Primitive{
      module: Group, uid: nil, parent_uid: -1, id: nil, tags: [],
      event_filter: nil, transform: @transform, styles: [],
      compiled: "td", state: nil
    } = Primitive.build("td", Group, pin: @tx_pin, rot: @tx_rot)
  end

  test "build treats empty transform list as nil" do
    %Primitive{
      module: Group, uid: nil, parent_uid: -1, id: nil, tags: [],
      event_filter: nil, transform: nil, styles: [],
      compiled: "td", state: nil
    } = Primitive.build("td", Group, transforms: [])
  end


  test "build accepts the position option and treats it as a translation" do
    mx = Transform.build(translation: {123,456})

    %Primitive{
      module: Group, uid: nil, parent_uid: -1, id: nil, tags: [],
      event_filter: nil, transform: ^mx, styles: [],
      compiled: "td", state: nil
    } = Primitive.build("td", Group, position: {123,456})
  end


  test "build sets the optional style list" do
    %Primitive{
      module: Group, uid: nil, parent_uid: -1, id: nil, tags: [],
      event_filter: nil, transform: nil, styles: @styles,
      compiled: "td", state: nil
    } = Primitive.build("td", Group, styles: @styles)
  end

  test "build accepts a single style" do
    %Primitive{
      module: Group, uid: nil, parent_uid: -1, id: nil, tags: [],
      event_filter: nil, transform: nil, styles: [@style_1],
      compiled: "td", state: nil
    } = Primitive.build("td", Group, style: @style_1)
  end
  
  test "build sets the optional app state" do
    %Primitive{
      module: Group, uid: nil, parent_uid: -1, id: nil, tags: [],
      event_filter: nil, transform: nil, styles: [],
      compiled: "td", state: {:abc, 12}
    } = Primitive.build("td", Group, state: {:abc, 12})
  end

  test "build sets the optional id" do
    %Primitive{
      module: Group, uid: nil, parent_uid: -1, id: :set_test, tags: [],
      event_filter: nil, transform: nil, styles: [],
      compiled: "td", state: nil
    } = Primitive.build("td", Group, id: :set_test)
  end

  #============================================================================
  # structure

  #--------------------------------------------------------
  # type / module

  test "type_code gets the type code for the module" do
    assert Primitive.type_code(@primitive) == @type_module.type_code()
  end

  test "get_module returns the type module" do
    assert Primitive.get_module(@primitive) == @type_module
  end

  #--------------------------------------------------------
  # uid

  test "get_uid and do_put_uid manipulate the internal uid" do
    assert Primitive.do_put_uid(@primitive, 987) |> Primitive.get_uid() == 987
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
    assert Primitive.do_put_id(@primitive, :other) |> Primitive.get_id() == :other
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

  test "get_event_filter returns the event handler." do
    assert Primitive.get_event_filter(@primitive) == @event_filter
  end

  test "put_event_filter sets the event handler as {module,action}" do
    p = Primitive.put_event_filter(@primitive, { :mod, :act } )
    assert Primitive.get_event_filter(p) == { :mod, :act }
  end

  test "put_event_filter sets the event handler to a function" do
    p = Primitive.put_event_filter(@primitive, fn(_a,_b,_c,_d) -> nil end)
    assert is_function(Primitive.get_event_filter(p), 4)
  end

  test "put_event_filter sets the event handler to nil" do
    p = Primitive.put_event_filter(@primitive, { :mod, :act } )
    assert Primitive.get_event_filter(p) == { :mod, :act }
    p = Primitive.put_event_filter(@primitive, nil )
    assert Primitive.get_event_filter(p) == nil
  end

  #--------------------------------------------------------
  test "delete_event_filter sets the event filter to nil" do
    p = Primitive.put_event_filter(@primitive, { :mod, :act } )
    assert Primitive.get_event_filter(p) == { :mod, :act }
    p = Primitive.delete_event_filter( @primitive )
    assert Primitive.get_event_filter(p) == nil
  end

  #============================================================================
  # style field


  #--------------------------------------------------------
  # transform

  test "get_transform returns the transform" do
    assert Primitive.get_transform(@primitive) == @transform
  end

  test "put_transform sets the transform" do
    tx = Transform.put_pin(@transform, {987,654})
    p = Primitive.put_transform(@primitive, tx)
    assert Primitive.get_transform(p) == tx
  end

  test "put_transform sets the transform to nil" do
    p = Primitive.put_transform(@primitive, nil)
    assert Primitive.get_transform(p) == nil
  end

  test "put_transform sets individual transform types and cacls final" do
    tx = Transform.put_pin(@transform, {135,579})
    p = Primitive.put_transform(@primitive, :pin, {135,579})
    assert Primitive.get_transform(p) == tx
  end

  #--------------------------------------------------------
  # local matrix
  test "get_matrix returns the final matrix" do
    local_matrix = @primitive
      |> Primitive.get_transform()
      |> Transform.get_local()
    assert Primitive.get_local_matrix(@primitive) == local_matrix
  end

  #--------------------------------------------------------
  # local matrix
  test "calculate_inverse_matrix calculates and returns the inverse final matrix" do
    inverse_matrix = @primitive
      |> Primitive.get_transform()
      |> Transform.get_local()
      |> MatrixBin.invert()
    assert Primitive.calculate_inverse_matrix(@primitive) == inverse_matrix
  end

  #--------------------------------------------------------
  # styles

  test "get_styles returns the transform list" do
    assert Primitive.get_styles(@primitive) == @styles
  end

  test "put_styles replaces the entire style list" do
    new_styles = [Style.LineWidth.build(4), Style.Color.build(:magenta)]
    p = Primitive.put_styles(@primitive, new_styles )
    assert Primitive.get_styles(p) == new_styles
  end

  test "get_style returns a style by key" do
    assert Primitive.get_style(@primitive, Style.LineWidth) == @style_1
    assert Primitive.get_style(@primitive, Style.Color2)    == @style_2
  end

  test "get_style returns nil if missing by default" do
    assert Primitive.get_style(@primitive, :missing) == nil
  end

  test "get_style returns default if missing" do
    assert Primitive.get_style(@primitive, :missing, "default") == "default"
  end

  test "put_style adds to the head of the style list" do
    style = Style.Color.build(:khaki)
    p = Primitive.put_style(@primitive, style )
    assert Primitive.get_styles(p) == [style | @styles]
  end

  test "put_style replaces a style in the style list" do
    p = @primitive
      |> Primitive.put_style( Style.Color.build(:khaki) )
      |> Primitive.put_style( Style.Color.build(:cornsilk) )
    assert Primitive.get_styles(p) == [Style.Color.build(:cornsilk) | @styles]
  end

  test "drop_style removes a style in the style list" do
    assert Primitive.drop_style(@primitive, Style.LineWidth ) |> Primitive.get_styles() == [@style_2]
    assert Primitive.drop_style(@primitive, Style.Color2 ) |> Primitive.get_styles()    == [@style_1]
  end


  #============================================================================
  # data field

  #--------------------------------------------------------
  # compiled primitive-specific data

  test "get_data returns the primitive-specific compiled data" do
    assert Primitive.get_data(@primitive) == @compiled_data
  end

  test "put_data replaces the primitive-specific compiled data" do
    new_data = <<1,2,3,4,5,6,7,8,9,10>>
    p = Primitive.put_data(@primitive, new_data )
    assert Primitive.get_data(p) == new_data
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
  # generate io lists
  # to_io_list( uid, primitive ) 

  test "simple io_list generation works" do
    p = Group.build()
    io_list = Primitive.to_io_list(1234, p)
    assert io_list == [[<<210, 4, 0, 0>>, <<0, 0>>, <<255, 255, 255, 255>>], <<0>>]
  end

  test "to_io_list adds the final" do
    p = Group.build(pin: @tx_pin, rot: @tx_rot)
    io_list = Primitive.to_io_list(1234, p)

    tx_data = p
      |> Primitive.get_transform()
      |> Transform.get_data()

    assert io_list == [
      [
        [<<210, 4, 0, 0>>, <<0, 0>>, <<255, 255, 255, 255>>],
        tx_data
      ], <<0>>
    ]
  end

  test "to_io_list adds the style list" do
    style_color = Style.Color.build(:crimson)
    p = Group.build(styles: [style_color])

    io_list = Primitive.to_io_list(1234, p)
    assert io_list == [
      [
        [<<210, 4, 0, 0>>, <<0, 0>>, <<255, 255, 255, 255>>],
        [Style.get_data(style_color)]
      ], <<0>>
    ]
  end




end

