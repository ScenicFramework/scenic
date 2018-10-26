# Changelog

## 0.9.0
* Much improved testing
* Much improved documentation
* Simplify rules around user-closing a viewport
* Fix bug where captured positional inputs were not casting the transformed location
* Deprecated Graph.get_root(). Use Graph.get!(graph, :\_root\_) instead.
* Renamed Primitive.put_opts to Primitive.merge_opts
* Deprecated Primitive.put_style(w/list). Use Primitive.merge_opts(...) instead.
* Deprecated Primitive.put_transform(w/list). Use Primitive.merge_opts(...) instead.
* Add Graph.find/2
* Add Graph.modify/3 with a finder function
* Rename Cache.request_notification/1 -> Cache.subscribe/1
* Rename Cache.stop_notification/1 -> Cache.unsubscribe/1
* General cleanup of Scenic.Cache.Hash. Some functions removed. Some function signatures changed.
* Add Scenic.version function. Returns current version of Scenic.

## 0.8.0

* Many documentation improvements
* Rename `Scenic.Cache.Hash.compute/2` to `Scenic.Cache.Hash.binary/2`
* Rename `Scenic.Cache.Hash.compute_file/2` to `Scenic.Cache.Hash.file/2`
* Add `Scenic.Cache.Hash.binary!/2`
* Rename `Scenic.Cache.Hash.compute_file!/2` to `Scenic.Cache.Hash.file!/2`
* Add ability to put master styles and transforms in a ViewPort config.
* Fold Scenic.Math into the main Scenic project
* Cursor input is now only sent if the mouse is actually over a primitive. This
  solves an inconsistency where sometimes the incoming point would be in local
  coordinate space and sometimes it would be global. If you want to capture that
  sort of input, either cover the space with a clear rect, or capture the input.
* Add the `:direction` option to the `Dropdown` component so can can go either
  up or down.
* Add specs to functions in components and primitives
* Add the Toggle component. Thank you to Eric Watson. @wasnotrice

### Breaking Change

* Rename `Scenic.Component.Input.Carat` to `Scenic.Component.Input.Caret`.

## 0.7.0

* First public release