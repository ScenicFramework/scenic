# Upgrading to v0.10

Version 0.10 of Scenic contains breaking changes, which will need to be updated in your app in order to run. This is all good through as it enables goodness in the forms of proper font metrics and dynamic raw pixel textures.

## Changes to the Cache

The most important (and immediate) change you need to deal with is to the cache. In order to handle static items with different life-cycle requirements, the cache has been broken out into multiple smaller caches, each for a specific type of content.

The module `Scenic.Cache` is gone and should be replace with the appropriate cache in your code.

| Asset Type | Module |
| --- | --- |
| Static Textures | `Scenic.Cache.Static.Texture` |
| Fonts | `Scenic.Cache.Static.Font` |
| Font Metrics | `Scenic.Cache.Static.FontMetrics` |
| Dynamic Textures | `Scenic.Cache.Dynamic.Texture` |

## Static vs. Dynamic Caches

Note that caches are marked as either static or dynamic. Things that do not change and can be referred to by a hash of their content go into Static caches. This allows for future optimizations, such as caching these assets on a CDN.

The Dynamic.Texture cache is for images that change over time. For example, this could be an image coming off of a camera, or something that you generate directly in your own code. Note that Dynamic caches are more expensive overall as they will not get the same level of optimization in the future.

## Custom Fonts

If you have used custom fonts in your application, you need to use a new process to get them to load and render.

1. use the `truetype_metrics` tool in hex to generate a `\*.metrics` file for your custom font. This will live in the same folder as your font.
2. Make sure the name of the font file itself ends with the hash of its content. If you use the `-d` option in `truetype_metrics`, then that will be done for you.
3. Load the font metrics file into the `Scenic.Cache.Static.FontMetrics` cache. The hash of this file is the hash that you will use to refer to the font in the graphs.
4. Load the font itself into the `Scenic.Cache.Static.Font`