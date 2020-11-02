#
#  Created by Boyd Multerer on 2020-11-02.
#  Copyright © 2020 Kry10 Limited. All rights reserved.
#

# putting read and load in separate modules (both in this file)
# because load needs the cache to be set up and read doesn't.

defmodule Scenic.ViewPort.SupervisorTopTest do
  use ExUnit.Case, async: true
  doctest Scenic.ViewPort.SupervisorTop

  alias Scenic.ViewPort.SupervisorTop, as: Super

  # ============================================================================

  test "child_spec is as expected" do
    list = [1, 2, 3]

    assert Super.child_spec(list) == %{
             id: Super,
             start: {Super, :start_link, list},
             type: :supervisor,
             restart: :permanent,
             shutdown: 500
           }
  end
end
