#
#  Created by Boyd Multerer on 2020-11-02.
#  Copyright © 2020 Kry10 Limited. All rights reserved.
#

# putting read and load in separate modules (both in this file)
# because load needs the cache to be set up and read doesn't.

defmodule Scenic.Cache.Support.SupervisorTest do
  use ExUnit.Case, async: true
  doctest Scenic.Cache.Support.Supervisor

  alias Scenic.Cache.Support.Supervisor, as: Super

  # ============================================================================

  test "child_spec is as expected" do
    assert Super.child_spec() == %{
             id: Super,
             start: {Super, :start_link, nil},
             type: :supervisor,
             restart: :permanent,
             shutdown: 500
           }
  end
end
