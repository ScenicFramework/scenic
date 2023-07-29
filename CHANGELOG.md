# Changelog

## Unreleased

* Variety of minor updates, bug fixes, and doc updates
* `Scenic.Scene.assign/2` now accepts a map by @amclain in https://github.com/ScenicFramework/scenic/pull/291
* Allow `Scenic.Scene.assign_new/2` and `Scenic.Driver.assign_new/2` to take a map of values by @adkron in https://github.com/ScenicFramework/scenic/pull/293
* Update nimble_options by @axelson in https://github.com/ScenicFramework/scenic/pull/300
* Improve static assets otp_app error message by @axelson in https://github.com/ScenicFramework/scenic/pull/305
* Upgrade elixir_make and ssl_verify_fun by @ohrite in https://github.com/ScenicFramework/scenic/pull/321

### New Contributors
* @amclain made their first contribution in https://github.com/ScenicFramework/scenic/pull/291
* @adkron made their first contribution in https://github.com/ScenicFramework/scenic/pull/293
* @seb3s made their first contribution in https://github.com/ScenicFramework/scenic/pull/294
* @rkenzhebekov made their first contribution in https://github.com/ScenicFramework/scenic/pull/303
* @ohrite made their first contribution in https://github.com/ScenicFramework/scenic/pull/321

**Full Changelog**: https://github.com/ScenicFramework/scenic/compare/v0.11.1...v0.11.2

## 0.11.1
* A variety of minor documentation and spec bug fixes. The most important one
  fixes the docs for Primitives.arc and Primitives.sector, which did not reflect
  the actual format those primitives required.

## 0.11.0
* The GitHub repo was moved to the new ScenicFramework GitHub organization
* Add the Scenic.Assets.Stream.Bitmap.put_offset/3 api
* Various cleanup and documentation fixes
* This is a __MAJOR__ update. As Connor Rigby put it in a call... "What hasn't changed?"
* Read the [version 0.11 upgrade guide](./guides/upgrading_to_v0.11.md) for details
  about how to upgrade your application to 0.11.

## 0.10.4
* Can pass in a :name option to scenes/components @am-kantox
* Clean up warnings under Elixir 1.11
* Tell git not to mangle line endings on test data - part of getting Windows support working. @trejkaz
* Now requires Elixir 1.9 or higher.


## 0.10.3
* Fix bug allowing handle_continue to be overridden by scene. Thank you @lmarlow
* Fix bug where font in a style map wasn't being honored during graph build
* Add group_spec_r to primitives.ex. Thank you @nyaray
* Numerous documentation fixes by @grahamhay
* Clean up warnings, timing issues in test
* Fix compiler options for ARM. PR #198 Thank you Justin! @mobileoverlord
* Fix examples in docs. PR #196. Thank you @nschulzke
* Add :name option to components. PR #185. Thank you @tiger808


## 0.10.2
* A good set of documentation improvements. All minor, but good to get out there. Thank you @GregMefford
* Minor improvements to do error scene readability. Thank you @lmarlow

## 0.10.1
* Added the `Graph.add_to/3` function so you can add primitives to an existing group in a graph
* Remove runtime dependency on Mix
* Various doc fixes.

## 0.10.0
* Integration of [font metrics](https://github.com/boydm/font_metrics)
  * Buttons, checkboxes, radios, etc. can be auto-sized to fix their text
  * FontMetrics can be used to measure strings, trim to fit, and more
* Much improved error handling when a scene crashes during its init phase. Instead of quickly
  restarting the scene over and over, it now goes to an error scene that displays debug info.
  Also displays that info in the command line.
* Integrated spec-based graphs from @pragdave. This is a cleaner looking way to build graphs.
  See the changes in primitives.ex
* PR to fix delete the children of a group when the group itself is deleted. Thanks to
  Chris Boebel. @cboebel
* Improve building the C products. PR #126 - @fhunleth
* Added a :parser option to Cache.File.read/load to allow custom interpreters
* Added a ViewPort.reset() function (used by the error scene), which can be used to send
  a ViewPort back to the original scene it was started with.
* Dynamic Textures in the form of raw pixel maps are now supported. This should allow you
  to capture raw images off of a camera and display them without encoding/decoding
* leading spaces in a text primitive are now rendered
* Scene callbacks are all updated to support the OTP 21+ callback returns.
* Scenes now have the terminate callback.

### Deprecations

`push_graph/1` is deprecated in favor of returning `{:push, graph}`
([keyword](https://hexdocs.pm/elixir/Keyword.html)) options
from the `Scenic.Scene` callbacks. Since this is only a deprecation `push_graph/1` will
continue to work, but will log a warning when used.

`push_graph/1` will be removed in a future release.

* This allows us to utilize the full suite of OTP GenServer callback behaviors (such as
  timeout and `handle_continue`)
* Replacing the call of `push_graph(graph)` within a callback function depends slightly
  on the context in which it is used.
* in `init/2`:
  * `{:ok, state, [push: graph]}`
* in `filter_event/3`:
  * `{:halt, state, [push: graph]}`
  * `{:cont, event, state, [push: graph]}`
* in `handle_cast/2`:
  * `{:noreply, state, [push: graph]}`
* in `handle_info/2`:
  * `{:noreply, state, [push: graph]}`
* in `handle_call/3`:
  * `{:reply, reply, state, [push: graph]}`
  * `{:noreply, state, [push: graph]}`
* in `handle_continue/3`:
  * `{:noreply, state, [push: graph]}`

### Breaking Changes

`Scenic.Cache` has been removed. It has been replaced by asset specific caches.

| Asset Class   | Module  |
| ------------- | -----|
| Fonts      | `Scenic.Cache.Static.Font` |  
| Font Metrics | `Scenic.Cache.Static.FontMetrics` |
| Textures (images in a fill) | `Scenic.Cache.Static.Texture` |
| Raw Pixel Maps | `Scenic.Cache.Dynamic.Texture` |

Some of the Cache support modules have moved

| Old Module   | New Module  |
| ------------- | -----|
| `Scenic.Cache.Hash` | `Scenic.Cache.Support.Hash` |
| `Scenic.Cache.File` | `Scenic.Cache.Support.File` |
| `Scenic.Cache.Supervisor` | `Scenic.Cache.Support.Supervisor` |


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
