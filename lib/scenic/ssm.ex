defmodule Scenic.SSM do
  @moduledoc """
  Semantic Scene Model — unified element registry for Scenic.

  The SSM is the single source of truth for what's in a scene graph. It combines
  input routing data (for hit-testing and event delivery) with semantic data
  (for DevTools, automation, and accessibility) into one structure, compiled
  synchronously from the graph.

  ## Architecture

  Previously, Scenic had two parallel systems:
  - `input_lists` — compiled tuples for hit-testing (synchronous)
  - `semantic_table` — ETS entries for queries (async, could drift)

  The SSM replaces both with a single compilation pass that produces:
  - Input routing tuples (backwards-compatible with existing hit-test code)
  - Semantic entries (for ETS storage, queries, and element state tracking)

  Both are always in sync because they're produced from the same graph walk.

  ## Future: Event Routing

  The SSM enables capabilities the split system couldn't support:
  - `cursor_enter`/`cursor_leave` — hover tracking via element identity
  - Scroll targeting — route to innermost scrollable under cursor
  - Driver-level hover styles — SSM tracks hover state, driver swaps fills
  """
end
