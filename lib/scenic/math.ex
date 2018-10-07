#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math do
  @moduledoc """
  Helper functions that support Scenic mathematical operations.

  The math functions are fairly straightforward. When performance is needed some
  have been broken out into a NIF.

  The NIF functions are currently written for compatibility over top speed and
  as such, there is an opportunity to further improve them by calling out to
  CPU-specific vector instructions in the future.
  """

  @type vector_2 :: {x :: number, y :: number}

  @type point :: {x :: number, y :: number}

  @type line :: {p0 :: point, p1 :: point}
  @type triangle :: {p0 :: point, p1 :: point, p2 :: point}
  @type quad :: {p0 :: point, p1 :: point, p2 :: point, p3 :: point}

  @type matrix :: binary()

  @type matrix_list :: list(number)
end
