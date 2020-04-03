#
#  Created by Boyd Multerer on 2019-03-04.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Static.Texture do
  use Scenic.Cache.Base, name: "texture", static: true
  alias Scenic.Cache.Support

  @moduledoc """
  In memory cache for static static Image assets.

  In graphics-speak, an image that is being drawn to the screen is a "Texture". It doesn't
  matter how the image was stored on the disk (jpg, png, etc.), they all end up as
  textures presented to the graphics card.

  Assets such as textures tend to be relatively large compared to
  other data. These assets are often used across multiple scenes and may need to be shared
  with multiple drivers.

  ## Goals

  Given this situation, the Cache module has multiple goals.
  * __Reuse__ - assets used by multiple scenes should only be stored in memory once
  * __Load Time__- loading cost should only be paid once
  * __Copy time__ - assets are stored in ETS, so they don't need to be copied as they are used
  * __Pub/Sub__ - Consumers of static assets (drivers...) should be notified when an asset is
  loaded or changed. They should not poll the system.
  * __Security__ - Base assets can become an attack vector. Helper modules are provided
  to assist in verifying these files.

  ## Scope

  When a texture term is loaded into the cache, it is assigned a scope. 
  The scope is used to
  determine how long to hold the asset in memory before it is unloaded. Scope is either
  the atom `:global`, or a `pid`.

  The typical flow is that a scene will load a font into the cache. A scope is automatically
  defined that tracks the asset against the pid of the scene that loaded it. When the scene
  is closed, the scope becomes empty and the asset is unloaded.

  If, while that scene is loaded, another scene (or any process...) attempts to load
  the same asset into the cache, a second scope is added and the duplicate load is
  skipped. When the first scene closes, the asset stays in memory as long as the second
  scope remains valid.

  When a scene closes, it's scope stays valid for a short time in order to give the next
  scene a chance to load its assets (or claim a scope) and possibly re-use the already
  loaded assets.

  This is also useful in the event of a scene crashing and being restarted. The delay
  in unloading the scope means that the replacement scene will use already loaded
  assets instead of loading the same files again for no real benefit.

  When you load assets you can alternately provide your own scope instead of taking the
  default, which is your processes pid. If you provide `:global`, then the asset will
  stay in memory until you explicitly release it.

  ## Hashes

  At its simplest, accessing the cache is a key-value store. This cache is meant to be
  static in nature, so the key is be a hash of the data.

  Why? Read below...

  ## Security

  A lesson learned the hard way is that static assets (fonts, images, etc.) that your app
  loads out of storage can easily become attack vectors.

  These formats are complicated! There is no guarantee (on any system) that a malformed
  asset will not cause an error in the C code that interprets it. Again - these are complicated
  and the renderer needs to be fast...

  The solution is to compute a SHA hash of these files during build-time of your
  and to store the result in your applications code itself. Then during run time, you 
  compare then pre-computed hash against the run-time of the asset being loaded.

  Please take advantage of the helper modules `Cache.Support.File` and `Cache.Support.Hash` to
  build the hashes. 

  These scheme is much stronger when the application code itself is also signed and
  verified, but that is an exercise for the packaging tools.

  Full Example:

  ```elixir
  defmodule MyApp.MyScene do
    use Scenic.Scene
    import Scenic.Primitives

    # build the path to the static asset file (compile time)
    @image_path :code.priv_dir(:my_app) |> Path.join("/static/images/my_image.jpg")
    @image_hash Scenic.Cache.Hash.file!( @image_path, :sha )

    @graph Graph.build()
    |> rect( {10, 20}, fill: {:image, @image_hash})

    def init( _, _ ) do
      # load the asset into the cache (run time)
      Scenic.Cache.Static.Texture.load(@image_path, @image_hash)

      {:ok, :some_state, push: @graph}
    end
  end
  ```

  ## Pub/Sub

  Drivers (or any process...) listen to the font
  Cache via a simple pub/sub api.

  Because the graph, may be computed during compile time and pushed at some
  other time than the assets are loaded, the drivers need to know when the assets
  become available.

  Whenever any asset is loaded into the cache, messages are sent to any
  subscribing processes along with the affected keys. This allows them to react in a
  loosely-coupled way to how the assets are managed in your scene.

  """

  # --------------------------------------------------------
  def load(path, hash, opts \\ [])
      when is_bitstring(hash) and is_bitstring(path) do
    # if the static font is already loaded, just return it.
    case member?(hash) do
      true ->
        {:ok, hash}

      false ->
        with {:ok, texture} <- Support.File.read(path, hash, opts),
             {:ok, ^hash} <- put_new(hash, texture, opts[:scope]) do
          {:ok, hash}
        else
          err -> err
        end
    end
  end

  # --------------------------------------------------------
  def load!(path, hash, opts \\ [])
      when is_bitstring(hash) and is_bitstring(path) do
    # if the static font is already loaded, just return it.
    case member?(hash) do
      true ->
        hash

      false ->
        texture = Support.File.read!(path, hash, opts)
        {:ok, ^hash} = put_new(hash, texture, opts[:scope])
        hash
    end
  end
end
