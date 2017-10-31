#
#  Created by Boyd Multerer on 6/20/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Template.ButtonTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Template.Button


  #============================================================================
  # build / add
  test "build works" do
    button = Button.build( "Test",  id: :test_button )
    assert Graph.count(button) == 3

    # check that the input filter is set
    filter = button
      |> Graph.get(0)
      |> Primitive.get_event_filter()

    assert filter == {Button, :filter_input}
  end


end