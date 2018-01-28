#
#  Created by Boyd Multerer on 11/08/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#


defmodule Scenic.ViewPort.InputTest do
  use ExUnit.Case, async: true
  use Bitwise
  doctest Scenic
  alias Scenic.ViewPort.Input

#  import IEx

  @input_registry     :input_registry
  @driver_registry    :driver_registry


  # test helper functions
  defp verify_registries() do
    assert Registry.keys(@input_registry, self()) == []
    assert Registry.keys(@driver_registry, self()) == []
  end

  defp confirm_registration( type ) do
    Registry.keys( @input_registry, self() )
    |> Enum.member?( type )
  end

  #============================================================================
  # register input

  test "register input sets up to receive an input type" do
    verify_registries()
    Input.register( :key )
    assert confirm_registration( :key )
  end

  test "register input treats :char the same as :codepoint" do
    verify_registries()
    Input.register( :char )
    assert confirm_registration( :codepoint )
  end

  test "register input sets up to receive multiple input types" do
    verify_registries()
    Input.register( [:key, :cursor_button, :codepoint] )
    assert confirm_registration( :key )
    assert confirm_registration( :cursor_button )
    assert confirm_registration( :codepoint )
  end

  test "register input sets up to receive all input types" do
    verify_registries()
    Input.register( [:key, :cursor_button, :codepoint] )
    assert confirm_registration( :key )
    assert confirm_registration( :codepoint )
    refute confirm_registration( :cursor_pos )
    assert confirm_registration( :cursor_button )
    refute confirm_registration( :cursor_scroll )
    refute confirm_registration( :cursor_enter )
  end

  test "register input raises on invalid input type" do
    verify_registries()
    assert_raise Input.Error, fn ->
      Input.register( :banana )
    end
  end

  test "register the multiple times does not create multiple entries" do
    verify_registries()
    Input.register( :key )
    Input.register( :key )
    assert Registry.keys(@input_registry, self()) == [:key]
  end

  test "register sends updated flags to the driver on set one" do
    verify_registries()
    # register to receive driver messages
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # register for the input
    Input.register( :key )

    # confirm a driver update message was sent
    assert_receive( {:"$gen_cast", {:request_input, 0x0001}}  )
  end

  test "register sends updated flags to the driver on set multiple" do
    verify_registries()
    # register to receive driver messages
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # register for the input
    Input.register( [:key, :cursor_pos] )

    # confirm a driver update message was sent
    assert_receive( {:"$gen_cast", {:request_input, 5}}  )
  end

  test "register sends updated flags to the driver on set all" do
    verify_registries()
    # register to receive driver messages
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # register for the input
    Input.register( :all )

    # confirm a driver update message was sent
    assert_receive( {:"$gen_cast", {:request_input, 63}}  )
  end



  #============================================================================
  # unregister input

  test "unregister stops receiving an input type" do
    verify_registries()
    Input.register( :key )
    Input.unregister( :key )
    refute confirm_registration( :key )
  end

  test "unregister input treats :char the same as :codepoint" do
    verify_registries()
    Input.register( :codepoint )
    Input.unregister( :char )
    refute confirm_registration( :codepoint )
  end

  test "unregister stops receiving multiple input types" do
    verify_registries()
    Input.register( :all )
    Input.unregister( [:key, :cursor_button, :codepoint] )
    refute confirm_registration( :key )
    refute confirm_registration( :cursor_button )
    refute confirm_registration( :codepoint )
  end

  test "unregister stops receiving all input types" do
    verify_registries()
    Input.register( :all )
    Input.unregister( :all )
    refute confirm_registration( :key )
    refute confirm_registration( :codepoint )
    refute confirm_registration( :cursor_pos )
    refute confirm_registration( :cursor_button )
    refute confirm_registration( :cursor_scroll )
    refute confirm_registration( :cursor_enter )
  end

  test "unregister raises on invalid input type" do
    verify_registries()
    assert_raise Input.Error, fn ->
      Input.unregister( :banana )
    end
  end

  test "unregister sends updated flags to the driver on set one" do
    verify_registries()
    # register to receive driver messages
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # register for the input
    Input.register( :key )
    Process.sleep(10)
    Input.unregister( :key )

    # confirm a driver update message was sent
    assert_receive( {:"$gen_cast", {:request_input, 0x0000}}  )
  end

  test "unregister sends updated flags to the driver on set multiple" do
    verify_registries()
    # register to receive driver messages
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # register for the input
    Input.register( [:key, :cursor_pos] )
    Process.sleep(10)
    Input.unregister( [:key, :cursor_pos] )

    # confirm a driver update message was sent
    assert_receive( {:"$gen_cast", {:request_input, 0x0000}}  )
  end

  test "unregister sends updated flags to the driver on set all" do
    verify_registries()
    # register to receive driver messages
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # register for the input
    Input.register( :all )
    Process.sleep(10)
    Input.unregister( :all )

    # confirm a driver update message was sent
    assert_receive( {:"$gen_cast", {:request_input, 0x0000}}  )
  end


  #============================================================================
  # send
  
  test "send input sends a message to the current scene" do
    Input.register( :key )
    Input.send( {:key, {:test_input}} )
    assert_receive( {:"$gen_cast", {:input, {:key, {:test_input}}}}  )
  end


  #============================================================================
  # data converters

  #--------------------------------------------------------
  test "key_to_atom works" do
    assert Input.key_to_atom( 32 ) == :space
  end

  test "key_to_atom raises error on bad match" do
    assert_raise Input.Error, fn ->
      Input.key_to_atom( "banana" )
    end
  end


  #--------------------------------------------------------
  test "mods_to_atoms converts the bitfield to a list of atoms" do
    assert Input.mods_to_atoms( 0x0001 ) == [:shift]
    assert Input.mods_to_atoms( 0x0002 ) == [:control]
    assert Input.mods_to_atoms( 0x0004 ) == [:alt]
    assert Input.mods_to_atoms( 0x0008 ) == [:super]

    assert Input.mods_to_atoms( 0x0003 ) == [:control, :shift]
    assert Input.mods_to_atoms( 0x0006 ) == [:alt, :control]
    assert Input.mods_to_atoms( 0x000F ) == [:super, :alt, :control, :shift]
  end

  test "mods_to_atoms raises on invalid data" do
    assert_raise Input.Error, fn ->
      Input.mods_to_atoms( "banana" )
    end
  end

  #--------------------------------------------------------
  test "action_to_atom works" do
    assert Input.action_to_atom( 0 ) == :release
    assert Input.action_to_atom( 1 ) == :press
    assert Input.action_to_atom( 2 ) == :repeat
  end

  test "action_to_atom returns :unknown for anything that fails to match" do
    assert Input.action_to_atom( "banana" ) == :unknown
  end

  #--------------------------------------------------------
  test "button_to_atom works" do
    assert Input.button_to_atom( 0 ) == :left
    assert Input.button_to_atom( 1 ) == :right
  end

  test "button_to_atom returns :unknown for anything that fails to match" do
    assert Input.button_to_atom( "banana" ) == :unknown
  end

  #--------------------------------------------------------
  test "input_type_to_flags assembles a bitfield from atoms" do
    assert Input.input_type_to_flags( :key )          == 0x0001
    assert Input.input_type_to_flags( :codepoint )    == 0x0002
    assert Input.input_type_to_flags( :cursor_pos )   == 0x0004
    assert Input.input_type_to_flags( :cursor_button ) == 0x0008
    assert Input.input_type_to_flags( :cursor_scroll ) == 0x0010
    assert Input.input_type_to_flags( :cursor_enter )  == 0x0020
    assert Input.input_type_to_flags( :all )          == 0xFFFF
  end

  test "input_type_to_flags assembles a bitfield from lists of atoms" do
    assert Input.input_type_to_flags( [:key, :codepoint] )                  == 0x0003
    assert Input.input_type_to_flags( [:cursor_pos, :cursor_scroll, :key] )  == 0x0015
  end

  test "input_type_to_flags raises on invalid data" do
    assert_raise Input.Error, fn ->
      Input.input_type_to_flags( "banana" )
    end
  end

  #============================================================================
  # normalize input

  test "normalize key converts raw key input into atoms - but leaves mods alone" do
    assert Input.normalize( {:key, {265, 265, 1, 2}} ) == {:key, :up, :press, 2}
  end

  test "normalize codepoint converts codepoint key input into a bitstring - but leaves mods alone" do
    assert Input.normalize( {:codepoint, {10029, 3}} ) == {:char, "✭", 3}
  end

  test "normalize mouse_button converts mouse_button input into atoms - but leaves mods alone" do
    assert Input.normalize( {:cursor_button, {1, 0, 5, {1,2}}} ) == {:cursor_button, :right, :release, 5, {1,2}}
  end

  test "normalize mouse_enter converts mouse_enter input into true/false" do
    assert Input.normalize( {:cursor_enter, {0, {1,2}}} ) == {:cursor_enter, false, {1,2}}
    assert Input.normalize( {:cursor_enter, {1, {1,2}}} ) == {:cursor_enter, true, {1,2}}
  end

  test "normalize leaves other events alone" do
    assert Input.normalize( {:cursor_pos, {10,10}} ) == {:cursor_pos, {10,10}}
    assert Input.normalize( {:cursor_scroll, {0,-1}, {10,10}} ) == {:cursor_scroll, {0,-1}, {10,10}}
  end

end














