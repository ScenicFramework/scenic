#
#  Created by Boyd Multerer on July 15, 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.ButtonTest do
  use ExUnit.Case, async: true
  doctest Scenic

  # alias Scenic.Component
  alias Scenic.Component.Button

  @data         {"Button", :id}
  @data_opts    {
                  "Button", :id, [width: 100, height: 100, radius: 2,
                  align: :right, theme: :warning]
                }

  #============================================================================
  # info

  test "info works" do
    assert is_bitstring Button.info()
  end

  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Button.verify( @data ) == {:ok, {"Button", :id, []}}
    assert Button.verify( @data_opts ) == {:ok, @data_opts}
  end

  test "verify fails invalid data" do
    assert Button.verify( {{10, :id}, :atom} )  == :invalid_data
    assert Button.verify( :banana )             == :invalid_data
  end

  #============================================================================
  # init

  test "init works with simple data" do
    {:ok, state} = Button.init(@data, nil)
    %Scenic.Graph{} = state.graph
    assert is_map(state.theme)
    assert state.pressed == false
    assert state.align == :center
    assert state.id == :id
  end

  test "init works with complex data" do
    {:ok, state} = Button.init(@data_opts, nil)
    %Scenic.Graph{} = state.graph
    assert is_map(state.theme)
    assert state.pressed == false
    assert state.align == :right
    assert state.id == :id
  end


end

