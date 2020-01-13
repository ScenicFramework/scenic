# Core Scenic Library

[![Build Status](https://travis-ci.org/boydm/scenic.svg?branch=master)](https://travis-ci.org/boydm/scenic)
[![Codecov](https://codecov.io/gh/boydm/scenic/branch/master/graph/badge.svg)](https://codecov.io/gh/boydm/scenic)

Scenic is a client application library written directly on the
Elixir/Erlang/OTP stack. With it you can build applications that operate
identically across all supported operating systems, including MacOS, Ubuntu,
Nerves/Linux, and more.

Scenic is primarily aimed at fixed screen connected devices (IoT), but can also
be used to build portable applications.

See the [getting started guide](https://hexdocs.pm/scenic/getting_started.html) and the [online documentation](https://hexdocs.pm/scenic/) for more information. Other resources available are:

- [Introducing Scenic](https://www.youtube.com/watch?v=1QNxLNMq3Uw), a video from ElixirConf 2018, which introduces Scenic and the problems it strives to solve.

## Goals

- **Available:** Scenic takes full advantage of OTP supervision trees to create
  applications that are fault-tolerant, self-healing, and highly available under
  adverse conditions.

- **Small and Fast:** The only core dependencies are Erlang/OTP and OpenGL.

- **Self Contained:** "Never trust a device if you don't know where it keeps its
  brain." The logic to run a device should be on the device and it should remain
  operational even if the service it talks to becomes unavailable.

- **Maintainable:** Each device knows how to run itself. This lets teams focus
  on new products and only updating the old ones as the business needs.

- **Remotable:** Scenic devices know how to run themselves, but can still be
  accessed remotely. Remote traffic attempts to be as small so it can be used
  over the Internet, cellular modems, Bluetooth, etc.

- **Reusable:** Collections of UI can be packaged up for reuse with, and across
  applications. I expect to see Hex packages of controls, graphs, and more
  available for Scenic applications.

- **Flexible:** Scenic uses matrices similar to game development to position
  everything. This makes reuse, scale, positioning and more very flexible and
  simple.

- **Secure:** Scenic is designed with an eye towards security. For now, the main
  effort is to keep it simple. No browser, Javascript, and other complexity
  presenting vulnerabilities. There will be much more to say about security
  later.

## Non-Goals

- **Browser:** Scenic is **not** a web browser. It is aimed at a fixed screen
  devices and certain types of windowed apps. It knows nothing about HTML.

- **3D:** Scenic is a 2D UI framework. It uses techniques from game development
  (such as transform matrices), but it does not support 3D drawing at this time.

- **Immediate Mode:** In graphics speak, Scenic is a retained mode system. If
  you need immediate mode, then Scenic isn't for you. If you don't know what
  retained and immediate modes are, then you are probably just fine. For
  reference: HTML is a retained mode model.

## Upgrading to v0.10

Version 0.10 of Scenic contains both deprecations and breaking changes, which will need to be updated in your app in order to run. This is all good through as it enables goodness in the forms of proper font metrics and dynamic raw pixel textures.

Please see the [v0.10 Upgrade Guide](https://hexdocs.pm/scenic/upgrading_to_v0-10.html).

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

##### Static vs. Dynamic Caches

Note that caches are marked as either static or dynamic. Things that do not change and can be referred to by a hash of their content go into Static caches. This allows for future optimizations, such as caching these assets on a CDN.

The Dynamic.Texture cache is for images that change over time. For example, this could be an image coming off of a camera, or something that you generate directly in your own code. Note that Dynamic caches are more expensive overall as they will not get the same level of optimization in the future.

##### Custom Fonts

If you have used custom fonts in your application, you need to use a new process to get them to load and render.

1. use the `truetype_metrics` tool in hex to generate a `\*.metrics` file for your custom font. This will live in the same folder as your font.
2. Make sure the name of the font file itself ends with the hash of its content. If you use the `-d` option in `truetype_metrics`, then that will be done for you.
3. Load the font metrics file into the `Scenic.Cache.Static.FontMetrics` cache. The hash of this file is the hash that you will use to refer to the font in the graphs.
4. Load the font itself into the `Scenic.Cache.Static.Font`

## Contributing

We appreciate any contribution to Scenic.

However, please understand that Scenic is still fairly new and as such, we'll be
keeping an extra-close eye on changes.

Check the [Code of Conduct](.github/CODE_OF_CONDUCT.md) and [Contributing
Guides](.github/CONTRIBUTING.md) for more information. We usually keep a list of
features and bugs in the issue tracker.

The easiest way to contribute is to help fill out the documentation. Please see
the [Contributing Guides](.github/CONTRIBUTING.md) first.
