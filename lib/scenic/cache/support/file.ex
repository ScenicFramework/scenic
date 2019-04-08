#
#  Created by Boyd Multerer on 2017-11-12.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Support.File do
  @moduledoc """
  Helpers for reading files in a hash-secured manner.

  Static assets such as fonts and images are usually stored as files on the local
  storage device. These files need to be loaded into the cache in order to be used
  by the various parts of Scenic.

  ## Where to store your static file assets

  You can store your assets anywhere in your app's `priv/` directory. This directory is
  special in the sense that the Elixir build system knows to copy its contents into the
  correct final build location. How you organize your assets inside of `priv/` is up to you.

      my_app/
        priv/
          static/
            images/
              asset.jpg


  At compile time you need to build the actual path of your asset by combining
  the build directory with the partial path inside of `priv/`

  Example

      path = :code.priv_dir(:my_app)
      |> Path.join("/static/images/asset.jpg")

  You can do this at either compile time or runtime.

  ## Security

  A lesson learned the hard way is that static assets (fonts, images, etc.) that your app
  loads out of storage can easily become attack vectors.

  These formats are complicated! There is no guarantee (on any system) that a malformed
  asset will not cause an error in the C code that interprets it. Again - these are complicated
  and the renderers need to be fast...

  The solution is to compute a SHA hash of these files during build-time of your
  and to store the result in your applications code itself. Then during run time, you
  compare then pre-computed hash against the run-time of the asset being loaded.

  These scheme is much stronger when the application code itself is also signed and
  verified, but that is an exercise for the packaging tools.

  When assets are loaded this way, the `@asset_hash` term is also used as the key in
  the cache. This has the additional benefit of allowing you to pre-compute
  the graph itself, using the correct keys for the correct assets.

  ## Full example

      defmodule MyApp.MyScene do
        use Scenic.Scene

        # build the path to the static asset file (compile time)
        @asset_path :code.priv_dir(:my_app) |> Path.join("/static/images/asset.jpg")

        # pre-compute the hash (compile time)
        @asset_hash Scenic.Cache.Hash.file!( @asset_path, :sha )

        # build a graph that uses the asset (compile time)
        @graph Scenic.Graph.build()
        |> rect( {100, 100}, fill: {:image, @asset_hash} )

        def init( _, _ ) {
          # load the asset into the texture cache (at run time)
          Scenic.Cache.Static.Texture.load(@asset_path, @asset_hash)

          {:ok, :some_state, push: @graph}
        end

      end
  """
  alias Scenic.Cache.Support.Hash

  # ===========================================================================

  # --------------------------------------------------------
  @doc """
  Read a file into memory.

  The reason you would use this instead of File.read is to verify the data against
  a pre-computed hash.

  Parameters:
  * `path` - the path to the asset file
  * `hash` - the pre-computed hash of the file.
  * `opts` - a list of options. See below.

  Options:
  * `hash` - format of the hash. Valid formats include `:sha, :sha224, :sha256, :sha384, :sha512, :ripemd160`.
    If the hash option is not set, it will use `:sha` by default.
  * `decompress` - if `true` - decompress the data (zlib) after reading and verifying the hash.

  On success, returns
  `{:ok, data}`
  """

  def read(path, hash, opts \\ [])

  # insecure read
  # don't recommend doing this in production. Better to embed the expected
  # hashes. Is also slower because it has to load the file and compute the hash
  # to use as a key even it is is already loaded into the cache.
  def read(path, :insecure, opts) do
    if Scenic.mix_env() != :test do
      IO.puts("WARNING: Cache asset read as :insecure \"#{path}\"")
    end

    with {:ok, data} <- File.read(path),
         {:ok, data} <- do_unzip(data, opts) do
      {:ok, data}
    else
      err -> err
    end
  end

  def read(path, hash, opts) do
    with {:ok, data} <- File.read(path),
         {:ok, data} <- Hash.verify(data, hash, opts[:hash] || :sha),
         {:ok, data} <- do_unzip(data, opts) do
      {:ok, data}
    else
      err -> err
    end
  end

  # --------------------------------------------------------
  @doc """
  Read a file into memory.

  The reason you would use this instead of File.read is to verify the data against
  a pre-computed hash.

  `read!` is similar to `read` except that it raises if an error occurs and returns the
  data directly

  Parameters:
  * `path` - the path to the asset file
  * `hash` - the pre-computed hash of the file
  * `opts` - a list of options. See below.

  Options:
  * `hash` - format of the hash. Valid formats include `:sha, :sha224, :sha256, :sha384, :sha512, :ripemd160`.
    If the hash option is not set, it will use `:sha` by default.
  * `decompress` - if `true` - decompress the data (zlib) after reading and verifying the hash.

  On success, returns
  `data`
  """

  def read!(path, hash, opts \\ [])

  def read!(path, :insecure, opts) do
    if Scenic.mix_env() != :test do
      IO.puts("WARNING: Cache asset read! as :insecure \"#{path}\"")
    end

    path
    |> File.read!()
    |> do_unzip!(opts)
  end

  def read!(path, hash, opts) do
    path
    |> File.read!()
    |> Hash.verify!(hash, opts[:hash] || :sha)
    |> do_unzip!(opts)
  end

  # --------------------------------------------------------
  # unzip the data if the unzip option is true. Otherwise just returns
  # the data unchanged.
  defp do_unzip(data, opts) do
    case opts[:decompress] do
      true ->
        try do
          {:ok, :zlib.gunzip(data)}
        rescue
          _ -> {:error, :decompress}
        end

      _ ->
        {:ok, data}
    end
  end

  defp do_unzip!(data, opts) do
    case opts[:decompress] do
      true -> :zlib.gunzip(data)
      _ -> data
    end
  end
end
