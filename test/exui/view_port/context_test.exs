#
#  Created by Boyd Multerer on 6/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# {:context, ref, {_scene_pid, vp_pid, port_id}} 

defmodule Scenic.ViewPort.ContextTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.ViewPort.Context

#  import IEx

  #============================================================================
  # build( scene_pid, vp_pid, port_id )

  test "build context works" do
    {:context, ref, {scene_pid, vp_pid, port_id}} = Context.build(:scene_pid, :vp_pid, :port_id)
    assert is_reference( ref )
    assert scene_pid == :scene_pid
    assert vp_pid ==    :vp_pid
    assert port_id ==   :port_id
  end

  #============================================================================
  # getters

  test "get_reference gets the generated reference" do
    context = Context.build(:scene_pid, :vp_pid, :port_id)
    {:context, ref, _} = context
    assert Context.get_reference( context ) == ref
  end

  test "get_scene_pid gets the scene pid" do
    context = Context.build(:scene_pid, :vp_pid, :port_id)
    assert Context.get_scene_pid( context ) == :scene_pid
  end

  test "get_view_port_pid gets the view port pid" do
    context = Context.build(:scene_pid, :vp_pid, :port_id)
    assert Context.get_view_port_pid( context ) == :vp_pid
  end

  test "get_port_id gets the client app port id" do
    context = Context.build(:scene_pid, :vp_pid, :port_id)
    assert Context.get_port_id( context ) == :port_id
  end

end