# Core Scenic Library

Scenic is a client application library written directly on the
Elixir/Erlang/OTP stack. With it you can build applications that operate
identically across all supported operating systems, including MacOS, Ubuntu,
Nerves/Linux, and more.

Scenic is primarily aimed at fixed screen connected devices (IoT), but can also
be used to build portable applications.

See the [getting started guide](https://hexdocs.pm/scenic/getting_started.html) and the [online documentation](https://hexdocs.pm/scenic/) for more information. Other resources available are:

- [Introducing Scenic](https://www.youtube.com/watch?v=1QNxLNMq3Uw), a video from ElixirConf 2018, which introduces Scenic and the problems it strives to solve.

> **Warning** Version 0.11 is a **MAJOR** upgrade!
>
> There are numerous breaking changes. Please read the [version 0.11 upgrade
> guide](./guides/upgrading_to_v0.11.md) for details about how to upgrade your
> application to 0.11.

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
  accessed remotely. Remote traffic attempts to be as small as possible so it
  can be used over the Internet, cellular modems, Bluetooth, etc. This is
  actively under development and coming soon.

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



## Contributing

We appreciate any contribution to Scenic.

However, please understand that Scenic is still fairly new and as such, we'll be
keeping an extra-close eye on changes.

Check the [Code of Conduct](.github/CODE_OF_CONDUCT.md) and [Contributing
Guides](.github/CONTRIBUTING.md) for more information. We usually keep a list of
features and bugs in the issue tracker.

The easiest way to contribute is to help fill out the documentation. Please see
the [Contributing Guides](.github/CONTRIBUTING.md) first.
