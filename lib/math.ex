#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math do
  @moduledoc """
  Documentation for Scenic.Math

  Lots to do here
  """

  @type vector_2 :: {x :: number, y :: number}
  @type vector_3 :: {x :: number, y :: number, z :: number}
  @type vector_4 :: {x :: number, y :: number, z :: number, w :: number}

  @type point :: {x :: number, y :: number}

  @type line :: {p0 :: point, p1 :: point}
  @type triangle :: {p0 :: point, p1 :: point, p2 :: point}
  @type quad :: {p0 :: point, p1 :: point, p2 :: point, p3 :: point}

  @type matrix :: <<_::64>>
end
