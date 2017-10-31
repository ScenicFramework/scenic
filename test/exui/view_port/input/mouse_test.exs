#
#  Created by Boyd Multerer on 6/13/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# {:context, ref, {_scene_pid, vp_pid, port_id}} 

defmodule Scenic.ViewPort.Input.MouseTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.ViewPort.Context
  alias Scenic.ViewPort.Input
  alias Scenic.ViewPort.Input.Mouse

#  import IEx

  @mouse_opcode         2

  @left_button_mask     0x01
  @middle_button_mask   0x02
  @right_button_mask    0x04

  @input_key            :input

  #============================================================================
  # test helpers
  defp test_context() do
    Context.build(self(), self(), 123)
  end

  defp set_up_registry() do
    r = Registry.start_link(:duplicate, :scenic_input_registry)
    # give the registry a chance to set up...
    Process.sleep(10)
    r
  end

  defp mouse_event(btns, uid, x, y) do
    <<
      @mouse_opcode :: size(8),
      btns :: size(8),
      uid ::  unsigned-integer-size(32)-native,
      x ::    integer-size(16)-native,
      y ::    integer-size(16)-native
    >>  
  end

  #============================================================================
  # mouse state

  test "build creates a mouse state record" do
    {{true,false,false},{10,20},123} = Mouse.build(@left_button_mask, 123, 10, 20)
    {{false,true,false},{10,20},123} = Mouse.build(@middle_button_mask, 123, 10, 20)
    {{false,false,true},{10,20},123} = Mouse.build(@right_button_mask, 123, 10, 20)
  end

  test "get_buttons gets the position" do
    mouse = Mouse.build(5, 123, 10, 20)
    assert Mouse.get_buttons(mouse) == {true,false,true}
  end

  test "get_position gets the position" do
    mouse = Mouse.build(5, 123, 10, 20)
    assert Mouse.get_position(mouse) == {10,20}
  end

  test "get_uid gets the uid" do
    mouse = Mouse.build(5, 123, 10, 20)
    assert Mouse.get_uid(mouse) == 123
  end

  test "left_button_down? works" do
    mouse = Mouse.build(@left_button_mask, 123, 10, 20)
    assert Mouse.left_button_down?(mouse) == true
    assert Mouse.middle_button_down?(mouse) == false
    assert Mouse.right_button_down?(mouse) == false
  end

  test "middle_button_down? works" do
    mouse = Mouse.build(@middle_button_mask, 123, 10, 20)
    assert Mouse.left_button_down?(mouse) == false
    assert Mouse.middle_button_down?(mouse) == true
    assert Mouse.right_button_down?(mouse) == false
  end

  test "right_button_down? works" do
    mouse = Mouse.build(@right_button_mask, 123, 10, 20)
    assert Mouse.left_button_down?(mouse) == false
    assert Mouse.middle_button_down?(mouse) == false
    assert Mouse.right_button_down?(mouse) == true
  end

  #============================================================================
  # basic mouse event handling

  test "raw mouse event is sent to scene" do
    raw_event = mouse_event(5, 123, 10, 20)
    mouse_state = Mouse.build( 5, 123, 10, 20 )

    set_up_registry()
    Input.handle_raw_input(test_context(), %{}, raw_event)

    assert_received( {:"$gen_cast", {:input, {:mouse_raw, ^mouse_state}, 123} }  )
  end


  #============================================================================
  # mouse left down event handling

  test "mouse_down is sent when switching from up to down" do
    old_mouse = Mouse.build( 0, 123, 10, 20 )
    old_state = %{@input_key => %{Mouse => old_mouse}}

    new_mouse = Mouse.build( @left_button_mask, 123, 10, 20 )
    new_event = mouse_event( @left_button_mask, 123, 10, 20)

    set_up_registry()
    Input.handle_raw_input(test_context(), old_state, new_event)

    assert_received( {:"$gen_cast", {:input, {:mouse_down, ^new_mouse}, 123} }  )
    refute_received( {:"$gen_cast", {:input, {:mouse_up, _}, _} }  )
  end

  test "mouse_up is sent when switching from down to up" do
    old_mouse = Mouse.build( @left_button_mask, 123, 10, 20 )
    old_state = %{@input_key => %{Mouse => old_mouse}}

    new_mouse = Mouse.build( 0, 123, 10, 20 )
    new_event = mouse_event( 0, 123, 10, 20)

    set_up_registry()
    Input.handle_raw_input(test_context(), old_state, new_event)

    assert_received( {:"$gen_cast", {:input, {:mouse_up, ^new_mouse}, 123} }  )
    refute_received( {:"$gen_cast", {:input, {:mouse_down, _}, _} }  )
  end

  test "neither mouse_down nor mouse_up is sent staying up" do
    old_mouse = Mouse.build( 0, 123, 10, 20 )
    old_state = %{@input_key => %{Mouse => old_mouse}}

    new_event = mouse_event( 0, 123, 10, 20)

    set_up_registry()
    Input.handle_raw_input(test_context(), old_state, new_event)

    refute_received( {:"$gen_cast", {:input, {:mouse_up, _}, _} }  )
    refute_received( {:"$gen_cast", {:input, {:mouse_down, _}, _} }  )
  end

  test "neither mouse_down nor mouse_up is sent staying down" do
    old_mouse = Mouse.build( @left_button_mask, 123, 10, 20 )
    old_state = %{@input_key => %{Mouse => old_mouse}}

    new_event = mouse_event( @left_button_mask, 123, 10, 20)

    set_up_registry()
    Input.handle_raw_input(test_context(), old_state, new_event)

    refute_received( {:"$gen_cast", {:input, {:mouse_up, _}, _} }  )
    refute_received( {:"$gen_cast", {:input, {:mouse_down, _}, _} }  )
  end

  #============================================================================
  # mouse right down event handling

  test "mouse_context_down is sent when switching from up to down" do
    old_mouse = Mouse.build( 0, 123, 10, 20 )
    old_state = %{@input_key => %{Mouse => old_mouse}}

    new_mouse = Mouse.build( @right_button_mask, 123, 10, 20 )
    new_event = mouse_event( @right_button_mask, 123, 10, 20)

    set_up_registry()
    Input.handle_raw_input(test_context(), old_state, new_event)

    assert_received( {:"$gen_cast", {:input, {:mouse_context_down, ^new_mouse}, 123} }  )
    refute_received( {:"$gen_cast", {:input, {:mouse_context_up, _}, _} }  )
  end

  test "mouse_context_up is sent when switching from down to up" do
    old_mouse = Mouse.build( @right_button_mask, 123, 10, 20 )
    old_state = %{@input_key => %{Mouse => old_mouse}}

    new_mouse = Mouse.build( 0, 123, 10, 20 )
    new_event = mouse_event( 0, 123, 10, 20)

    set_up_registry()
    Input.handle_raw_input(test_context(), old_state, new_event)

    assert_received( {:"$gen_cast", {:input, {:mouse_context_up, ^new_mouse}, 123} }  )
    refute_received( {:"$gen_cast", {:input, {:mouse_context_down, _}, _} }  )
  end

  test "neither mouse_context_down nor mouse_context_up is sent staying up" do
    old_mouse = Mouse.build( 0, 123, 10, 20 )
    old_state = %{@input_key => %{Mouse => old_mouse}}

    new_event = mouse_event( 0, 123, 10, 20)

    set_up_registry()
    Input.handle_raw_input(test_context(), old_state, new_event)

    refute_received( {:"$gen_cast", {:input, {:mouse_context_up, _}, _} }  )
    refute_received( {:"$gen_cast", {:input, {:mouse_context_down, _}, _} }  )
  end

  test "neither mouse_context_down nor mouse_context_up is sent staying down" do
    old_mouse = Mouse.build( @right_button_mask, 123, 10, 20 )
    old_state = %{@input_key => %{Mouse => old_mouse}}

    new_event = mouse_event( @right_button_mask, 123, 10, 20)

    set_up_registry()
    Input.handle_raw_input(test_context(), old_state, new_event)

    refute_received( {:"$gen_cast", {:input, {:mouse_context_up, _}, _} }  )
    refute_received( {:"$gen_cast", {:input, {:mouse_context_down, _}, _} }  )
  end

  #============================================================================
  # mouse enter / leave uid

  test "mouse_enter and mouse_leave is sent when changing uid" do
    old_mouse = Mouse.build( 0, -1, 10, 20 )
    old_state = %{@input_key => %{Mouse => old_mouse}}

    new_event = mouse_event( 0, 123, 11, 20)

    set_up_registry()
    Input.handle_raw_input(test_context(), old_state, new_event)

    assert_received( {:"$gen_cast", {:input, {:mouse_enter, 123}, 123} }  )
    assert_received( {:"$gen_cast", {:input, {:mouse_leave, -1}, -1} }  )
  end

  test "neither mouse_enter nor mouse_leave is sent when not changing uid" do
    old_mouse = Mouse.build( 0, 123, 10, 20 )
    old_state = %{@input_key => %{Mouse => old_mouse}}

    new_event = mouse_event( 0, 123, 11, 20)

    set_up_registry()
    Input.handle_raw_input(test_context(), old_state, new_event)

    refute_received( {:"$gen_cast", {:input, {:mouse_enter, _}, _} }  )
    refute_received( {:"$gen_cast", {:input, {:mouse_leave, _}, _} }  )
  end



  #============================================================================
  # mouse event forwarded to registry

  test "prove that raw mouse is not sent to nil scene" do
    context = Context.build(nil, self(), 123)

    raw_event = mouse_event(5, 123, 10, 20)

    set_up_registry()
    Input.handle_raw_input(context, %{}, raw_event)

    refute_received( {:"$gen_cast", {:input, {:mouse_raw, _}, _} }  )
  end

  test "receive raw mouse via registered listener (keep scene nil)" do
    context = Context.build(nil, self(), 123)

    # register to as a listener...
    set_up_registry()
    Registry.register(:scenic_input_registry, :mouse_raw, nil )

    raw_event = mouse_event(5, 123, 10, 20)
    mouse_state = Mouse.build( 5, 123, 10, 20 )

    Input.handle_raw_input(context, %{}, raw_event)

    assert_received( {:"$gen_cast", {:mouse_raw, ^mouse_state}}  )
  end


end






































