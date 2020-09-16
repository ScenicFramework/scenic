#
#  Created by Boyd Multerer on 2019-03-04.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Dynamic.Texture do
  use Scenic.Cache.Base, name: "texture", static: false

  # alias Scenic.Cache.Support

  # import IEx

  @moduledoc """
  In memory cache for static dynamic Image assets.

  In graphics-speak, an image that is being drawn to the screen is a "Texture".

  Unlike `Scenic.Cache.Static.Texture`, this module assumes that the pixels to be rendered
  in the image are being generated on the at runtime and change, perhaps rapidly.

  The primary example is capturing an image off of a camera. This data is generated
  on the fly and needs to be presented to the video card with as little encoding being done
  as possible.

  So instead of using a hash of the data as a key (which doesn't make sense given that the data
  is changing...), you pick a unique string to represent the stream of data. It is up to you
  to make sure the names you choose are unique in your app.

  The only data the `Scenic.Cache.Dynamic.Texture` accepts is a raw pixel map. Please use the `Scenic.Utilities.Texture`
  module to help build and manage these data sets.

  ## Goals

  Given this situation, the dynamic Cache module has multiple goals.
  * __Reuse__ - assets used by multiple scenes should only be stored in memory once
  * __Copy time__ - assets are stored in ETS, so they don't need to be copied as they are used
  * __Pub/Sub__ - Consumers of static assets (drivers...) should be notified when an asset is
  loaded or changed. They should not poll the system.

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
  def put(key, data, opts) do
    case validate(data) do
      :ok -> super(key, data, opts)
      err -> err
    end
  end

  # --------------------------------------------------------
  defp validate({:g, w, h, pix, _}), do: do_validate(w * h, byte_size(pix))
  defp validate({:ga, w, h, pix, _}), do: do_validate(w * h * 2, byte_size(pix))
  defp validate({:rgb, w, h, pix, _}), do: do_validate(w * h * 3, byte_size(pix))
  defp validate({:rgba, w, h, pix, _}), do: do_validate(w * h * 4, byte_size(pix))
  defp validate(_), do: {:error, :pixels_format}

  defp do_validate(expected, actual) when expected == actual, do: :ok
  defp do_validate(_, _), do: {:error, :pixels_size}
end
