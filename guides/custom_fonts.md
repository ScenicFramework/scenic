# Using Custom Fonts

Scenic ships standard with support for the [Roboto](https://fonts.google.com/specimen/Roboto) and [Roboto_Mono](https://fonts.google.com/specimen/Roboto+Mono) fonts. The [Roboto_Slab](https://fonts.google.com/specimen/Roboto+Slab) font is no longer standard in Scenic.

You can, however, add the RobotoSlab font, and most any other TrueType font you want to use into Scenic.

To do this you will need do the following steps.

  1. Download the font you want to use and add it to the static files of your `priv/` folder in your application. Please be aware of font licenses and make good choices.
  2. Use the [truetype_metrics](https://hex.pm/packages/truetype_metrics) hex package to generate a `*.metrics` file, which you also add to your `priv/` folder. This tool will also change the name of your font so that a hash of the data is included in the file name.
  3. Load the `*.metrics` file into the `Scenic.Cache.Static.FontMetrics` cache.
  4. Refer to the font by the key to the metrics file in the graph where you want to use it.

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

Use the [truetype_metrics](https://hex.pm/packages/truetype_metrics) tool to generate a font metrics file. This tool is not included in Scenic because this code is complicated (don't get me started on the TrueType format) and only needs to be used once when you set up your project.

This tool will do two things. It will create a `\*.metrics` file and decorate the name of the font itself with a hash of its contents.

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

Read the [truetype_metrics](https://hex.pm/packages/truetype_metrics) documentation to learn how to recurse font folders, control the font name decoration and force the file to be re-generated.

## Load the `\*.metrics` file and the font into the cache

In your scene, you need to make load both the `\*.metrics` file into the `Scenic.Cache.Static.FontMetrics` cache and the font itself into the `Scenic.Cache.Static.Font` cache.


```elixir
@custom_font_hash "0IXAWqFTtjn6MKSgQOzxUgxNKGrmyhqz1e2d90PVHck"
@custom_metrics_path :code.priv_dir(:scenic_example)
           |> Path.join("/static/fonts/Roboto_Slab/RobotoSlab-Regular.ttf.metrics")
@custom_metrics_hash Scenic.Cache.Support.Hash.file!(@custom_metrics_path, :sha)

def init(_, _opts) do
  # load the custom font
  font_folder = :code.priv_dir(:my_app) |> Path.join("/static/fonts")
  custom_metrics_path = :code.priv_dir(:scenic_example)
           |> Path.join("/static/fonts/Roboto_Slab/RobotoSlab-Regular.ttf.metrics")
  
  Cache.Static.Font.load(font_folder, @custom_font_hash)
  Cache.Static.FontMetrics.load(custom_metrics_path, @custom_metrics_hash)

  # no need to put the graph into state as we won't be using it again
  {:ok, nil, push: @graph}
end
```

Note that if you use this font everywhere, you may want to load it once during app startup with the `:global` scope. Then you can just refer to it without having to load it in every scene.

```elixir
Cache.Static.Font.load(@font_folder, @custom_font_hash, scope: :global)
Cache.Static.FontMetrics.load(@custom_metrics_path, @custom_metrics_hash, scope: :global)
```

## Refer to the font by the metrics key

Finally, you use the key to refer to the font metrics in the graph. The font itself will be loaded and used automatically as needed. The metrics file already contains the hash of the font itself.

```elixir
text_spec("Font Test", translate: {0, 40}, font_size: 60, font: @custom_metrics_hash)
```
