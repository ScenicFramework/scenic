#
#  Created by Boyd Multerer on July 15, 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.ButtonTest do
  use ExUnit.Case, async: true
  doctest Scenic

  # alias Scenic.Component
  alias Scenic.Component.Button

  #============================================================================
  # info

  test "info works" do
    assert is_bitstring Button.info()
  end

  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Button.verify( "Button" ) == {:ok, "Button"}
  end

  test "verify fails invalid data" do
    assert Button.verify( :banana )             == :invalid_data
  end

  #============================================================================
  # init

  test "init works with simple data" do
    {:ok, state} = Button.init("Button", [styles: %{}, id: :button_id])
    %Scenic.Graph{} = state.graph
    assert is_map(state.theme)
    assert state.pressed == false
    assert state.align == :center
    assert state.id == :button_id
  end




end

