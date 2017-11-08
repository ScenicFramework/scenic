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

  defp set_up_registry() do
  end


end
