# Cache Overview

Often, scenes will need to use assets, such as an image, or a custom font when being rendered. These assets are often large, static, and used in multiple scenes. In order to handle these assets effectively, Scenic has a built-in cache for them.

The goals of the cache are as follows:

* Only load assets once into memory even though they may be used by multiple scenes and drivers.
* Facilitate fast caching of static assets across computers.
* Allow drivers to monitor assets in the cache to optimize their resource usage.

## Asset Types

There are different types of assets in Scenic. Each have their own rules for loading, verification, and life-cycle. This is managed by launching a light weight cache process for each asset type. Examples of this are:

```elixir
Scenic.Cache.Static.Texture         # for image fills (static images)
Scenic.Cache.Static.FontMetrics     # font metrics for working with strings
Scenic.Cache.Static.Font            # custom fonts you may want to use
Scenic.Cache.Dynamic.Texture        # for image fills (changing images)
```

If you wish to add your own cache types, you can create a custom cache. See below.

**Note:** versions 0.9 and below of Scenic used a single cache for all types of assets. Version 0.10 and above use a cache-per-type in order to better handle the different life-cycles and rules of these items.

## Static vs. Dynamic assets

As you look at the asset types, take special note that they are static or dynamic in nature.

The static assets require and enforce a hash as the key to the asset. This is both protects
the contents against unwanted change, and allows for a very efficient way to reference these items both within a single machine and across the Internet.

The dynamic assets can have any string you desire as the key and are not cached across machines as they changing in nature. If you are capturing images from a camera and displaying it in a scene, you will want to put it in the dynamic texture cache.

## Custom Asset Types

You can create your own custom asset caches. Please look at the code for Scenic.Cache.Static.Texture or Scenic.Cache.Dynamic.Texture as an example. You will need to start your custom cache in a Supervisor that you set up.

When you create your cache, you have a few options to fill out to set.

```elixir
defmodule Scenic.Cache.Static.Texture do
  use Scenic.Cache.Base, name: "texture", static: true
  ...
end
```

The `:static` option is very important. If set to true, the asset will be cache-able across machines, but not changeable after it is loaded. The key should always be a hash of the content, although you need to enforce that in your load function.

The `:name` option should be a dev-friendly name for the asset that will appear in the generated documentation for your new cache.

## Adding Custom Fonts

If you would like to add a custom font to use in your Scenic application, you will need to generate a FontMetrics file for it and load that into the cache.

Please see the [custom font guide](custom_fonts.html) for more information.