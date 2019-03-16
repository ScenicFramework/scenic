# Using Custom Fonts

Scenic ships standard with support for the [Roboto](https://fonts.google.com/specimen/Roboto) and [Roboto_Mono](https://fonts.google.com/specimen/Roboto+Mono) fonts. The [Roboto_Slab](https://fonts.google.com/specimen/Roboto+Slab) font is no longer standard in Scenic.

You can add the RobotoSlab font, and most any other TrueType font you want to use into Scenic.

To do this you will need do the following steps.

  1. Download the font you want to use and add it to the static files of your `priv/` folder in your application. Please be aware of font licenses and make good choices.
  2. Use the truetype_metrics hex package to generate a `*.metrics` file, which you also add to your `priv/` folder. This tool will also change the name of your font so that a hash of the data is included in the file name.
  3. Load the `*.metrics` file into the `Scenic.Cache.Static.FontMetrics` cache.
  4. refer to the font by the key to the metrics file in the graph where you want to use it.

These steps are descried in detail below

## Add the custom font file

Download your custom font and place it into your static assets folder. A typical static assets layout would look like this...

```bash
priv/
  static/
    fonts/
      Roboto_Slab/
        LICENSE.txt
        RobotoSlab-Regular.ttf
```

## Generate the `\*.metrics` file

Use the truetype_metrics tool to generate a font metrics file. This tool is not included in Scenic because this code is complicated (don't get me started on the TrueType format) and only needs to be run once when you set it up.

This tool will do two things. It will create a .metrics file and decorate the name of the font itself with a hash of its contents.

You may need to install the tool as an archive first

```bash
mix archive.install hex truetype_metrics
```

Then you can run the tool, pointing at your font directory

```bash
mix truetype_metrics -d priv/static/fonts/Roboto_Slab
```

When you are done, static folder will look something like this

```bash
priv/
  static/
    fonts/
      Roboto_Slab/
        LICENSE.txt
        RobotoSlab-Regular.ttf.0IXAWqFTtjn6MKSgQOzxUgxNKGrmyhqz1e2d90PVHck
        RobotoSlab-Regular.ttf.metrics
```

Read the truetype_metrics documentation to learn how to recurse font folders, control the font name decoration and force the file to be re-generated.

## Load the `\*.metrics` file into the cache

In your scene, you need to make load the `\*.metrics` file into the `Scenic.Cache.Static.FontMetrics` cache.


```elixir
```

Note that if you use this font everywhere, you may want to load it once during app startup with the `:global` scope. Then you can just refer to it without having to load it in every scene.

```elixir
```

## Refer to the font by the metrics key

Finally, you use the key to refer to the font metrics in the graph. The font itself will be loaded and used automatically as needed. The metrics file already contains the hash of the font itself.

```elixir
```
