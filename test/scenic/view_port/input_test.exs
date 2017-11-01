#
#  Created by Boyd Multerer on 6/13/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# {:context, ref, {_scene_pid, vp_pid, port_id}} 

defmodule Scenic.ViewPort.InputTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.ViewPort.Context
  alias Scenic.ViewPort.Input

#  import IEx

  @mouse_opcode     2
  @key_opcode       3

  @key_type_down    1
  @key_type_up      2

#  @key_delete       127
#  @key_escape       27
#  @key_enter        13
#  @key_tab          9

  @input_key        :input


  #============================================================================
  # test helpers
  defp test_context() do
    Context.build(self(), self(), 123)
  end

  defp set_up_registry() do
    Registry.start_link(:duplicate, :scenic_input_registry)
  end

  #============================================================================
  # base mouse input handling

  test "last mouse event recorded in the state" do
    raw_event = <<
      @mouse_opcode :: size(8),
      5 :: size(8),
      123 ::  unsigned-integer-size(32)-native,
      10 ::    integer-size(16)-native,
      20 ::    integer-size(16)-native
    >>

    mouse_state = Input.Mouse.build( 5, 123, 10, 20 )

    set_up_registry()
    state = Input.handle_raw_input(test_context(), %{}, raw_event)

    assert Map.get(state, @input_key) == %{Input.Mouse => mouse_state}
  end

  #============================================================================
  # key input handling

  test "key down events are sent to the scene with uid of -1" do
    key = 64

    raw_event = <<
      @key_opcode :: size(8),
      @key_type_down :: size(8),
      key ::  integer-size(16)-native
    >>

    assert Input.handle_raw_input(test_context(), %{}, raw_event) == %{}

    assert_received( {:"$gen_cast", {:input, {:key_down, ^key}, -1} }  )
  end

  test "key up events are sent to the scene with uid of -1" do
    key = 64

    raw_event = <<
      @key_opcode :: size(8),
      @key_type_up :: size(8),
      key ::  integer-size(16)-native
    >>

    assert Input.handle_raw_input(test_context(), %{}, raw_event) == %{}

    assert_received( {:"$gen_cast", {:input, {:key_up, ^key}, -1} }  )
  end

end
