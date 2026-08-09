# Task: Fix Hit-Testing Inside Scissored Groups

## Problem

Scenic's input hit-testing does NOT account for scissor clipping. When a group has
`scissor: {w, h}` set, the rendering driver correctly clips visuals to that rectangle,
but the input system still reports hits on primitives that are **visually clipped** —
i.e. outside the scissor bounds and invisible to the user.

This means you can "click" on things you can't see, and primitives that have scrolled
out of view inside a scissored scrollable area still receive input events.

## Root Cause

The input compilation and hit-testing pipeline has two relevant locations:

### 1. Input List Compilation (`view_port.ex` ~line 2076)

When compiling input for a **Group**, the code calculates transforms and recurses
into children, but **completely ignores the scissor style**:

```elixir
defp comp_input_prim(
       input, _uid,
       %Primitive{module: Primitive.Group, data: ids, transforms: txs},
       primitives, tx
     ) do
  local_tx = local_tx(txs, tx)
  Enum.reduce(ids, input, fn id, inpt ->
    comp_input_prim(inpt, id, primitives[id], primitives, local_tx)
  end)
end
```

The group's `styles` (which contains `:scissor`) are not even pattern-matched here.
Children are added to the input list with no knowledge that they're inside a scissor region.

### 2. Hit-Testing (`view_port.ex` ~line 2209)

`do_find_hit/6` tests each primitive's `contains_point?` in local coordinates, but
has no concept of scissor bounds. Even if a point is outside the scissor region,
it will still match if it's within the primitive's own bounds.

## Proposed Fix

### Option A: Propagate scissor bounds during input compilation (Recommended)

Modify `comp_input_prim` for groups to pass scissor bounds alongside the transform.
Store scissor info in the input list entries. Then in `do_find_hit`, check that the
projected point is also within the scissor bounds before testing `contains_point?`.

**Changes needed:**

1. **`comp_input_prim` for Group** (~line 2076): Extract `:scissor` from `styles`.
   Pass it down. Could add a `scissor` parameter to `comp_input_prim` or embed it
   in a tuple alongside `tx`.

2. **Input list entry format**: Currently `{module, data, local_tx, pid, types, id}`.
   Add a 7th element for scissor bounds (or nil): `{module, data, local_tx, pid, types, id, scissor}`.
   The scissor should be stored as `{sx, sy, sw, sh}` in the parent's coordinate space
   (the origin of the group + the scissor dimensions).

3. **`do_find_hit`** (~line 2209): Before calling `contains_point?`, check if there's
   a scissor bound. If so, verify the global point (projected into the scissor's
   coordinate space) falls within `{0, 0, sw, sh}`.

4. **Nested scissors**: If scissors can nest, the inner scissor should be intersected
   with the outer one. For a first pass, just using the innermost scissor is probably fine.

### Option B: Check scissor at hit-test time only

Store scissor rects on the ViewPort state keyed by scene/group, and check them during
`do_find_hit`. Simpler but less precise for nested cases.

## Files to Modify

- `/home/luke/workbench/flx/scenic/lib/scenic/view_port.ex`
  - `comp_input_prim/5` — the Group clause (~line 2076) needs to extract scissor
  - `comp_input_prim/5` — the primitive clause (~line 2104) needs to pass scissor through
  - `do_find_hit/6` — the primitive clause (~line 2209) needs scissor bounds check
  - `handle_cast({:input_list, ...})` (~line 1106) — may need to handle new tuple format

## Testing

- Create a group with `scissor: {200, 100}` containing a rect with `input: :cursor_button`
- Position the rect so part of it extends beyond the scissor bounds
- Verify: clicking the visible part triggers input, clicking the clipped part does NOT
- Test with scroll offset (translate the group contents so some items are above/below scissor)
- Test nested scissors if supported

## Context

This fix would allow the merlinex GUI to use Scenic's native `input: :cursor_button`
on primitives inside scrollable panels (which use scissored groups), instead of the
current workaround of manual coordinate math and process dictionary click targets.
The current workaround is ~200 lines of fragile code across multiple files.
