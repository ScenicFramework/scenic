#
#  Created by Boyd Multerer on 2017-11-12.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Term do
  @moduledoc """
  Helpers for loading file based Erlang terms directly into the cache.

  Sometimes you want to pre-compile a big erlang term, such as a dictionary/map and 
  distribute it to multiple applications. In this case you build your term, then use
  [`:erlang.term_to_binary/2`](http://erlang.org/doc/man/erlang.html#term_to_binary-2)
  to change it into binary data, which you write out to a file. Later you read the file
  and load the term.

  This will be used in Scenic to store pre-compiled font metric data, such as character
  widths, kerning, etc. It is much better to compute that once and store it than to
  run the C code every time your program is run.

  The `Scenic.Cache.Term` is very similar to [`Scenic.Cache.File`](Scenic.Cache.File.html)
  module, except that after the file has been loaded into memory, it also calls
  [`:erlang.binary_to_term/2`](http://erlang.org/doc/man/erlang.html#binary_to_term-2).

  ## Where to store your static file assets

  You can store your assets anywhere in your app's `priv/` directory. This directory is
  special in the sense that the Elixir build system knows to copy its contents into the
  correct final build location. How you organize your assets inside of `priv/` is up to you.

      my_app/
        priv/
          static/
            terms/
              asset.jpg


  At compile time you need to build the actual path of your asset by combining
  the build directory with the partial path inside of `priv/`

  Example

      path = :code.priv_dir(:my_app)
      |> Path.join("/static/terms/asset.jpg")

  You can do this at either compile time or runtime.

  ## Security

  A lesson learned the hard way is that static assets (fonts, images, etc) that your app
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

  Note that the hash is of the binary data in the file.

  ## Full example

      defmodule MyApp.MyScene do
        use Scenic.Scene

        # build the path to the static asset file (compile time)
        @asset_path :code.priv_dir(:my_app) |> Path.join("/static/terms/asset.jpg")

        # pre-compute the hash (compile time)
        @asset_hash Scenic.Cache.Hash.file!( @asset_path, :sha )

        def init( _, _ ) {
          # load the asset into the cache (run time)
          Scenic.Cache.File.load(@asset_path, @asset_hash)
          ...
        end

      end
  """
  alias Scenic.Cache
  alias Scenic.Cache.Hash

  # --------------------------------------------------------
  @doc """
  Load a file-based term directly into the cache.

  Parameters:
  * `path` - the path to the term file
  * `hash` - the pre-computed hash of the file
  * `opts` - a list of options. See below.

  Options:
  * `hash` - format of the hash. Valid formats include `:sha, :sha224, :sha256, :sha384, :sha512, :ripemd160`. If the hash option is not set, it will use `:sha` by default.
  * `scope` - Explicitly set the scope of the term in the cache.
  * `safe` - prevents the creation of new atoms. [See erlang docs](http://erlang.org/doc/man/erlang.html#binary_to_term-2).

  On success, returns
  `{:ok, cache_key}`

  The key in the cache will be the hash of the file.
  """

  def load(path, hash, opts \\ [])

  # insecure loading. Loads file blindly even it is altered
  # don't recommend doing this in production. Better to embed the expected
  # hashes. Is also slower because it has to load the file and compute the hash
  # to use as a key even it is is already loaded into the cache.
  def load(path, :insecure, opts) do
    with {:ok, data} <- Cache.File.read(path, :insecure, opts),
         {:ok, hash} <- Hash.binary(data, opts[:hash] || :sha) do
      case Cache.claim(hash, opts[:scope]) do
        true ->
          {:ok, hash}

        false ->
          case do_read_term(data, opts) do
            {:ok, term} -> Cache.put(hash, term, opts[:scope])
            err -> err
          end
      end
    else
      err -> err
    end
  end

  # preferred, more secure load. Expected hash signature is supplied
  # also faster if the item is already loaded as then it can just skip
  # loading the file
  def load(path, hash, opts) do
    case Cache.claim(hash, opts[:scope]) do
      true ->
        {:ok, hash}

      false ->
        # need to read and verify the file
        case read(path, hash, opts) do
          {:ok, data} -> Cache.put(hash, data, opts[:scope])
          err -> err
        end
    end
  end

  # --------------------------------------------------------
  @doc """
  Read a file-based term into memory.

  The reason you would use this instead of File.read is to verify the data against
  a pre-computed hash.

  Parameters:
  * `path` - the path to the term file
  * `hash` - the pre-computed hash of the file
  * `opts` - a list of options. See below.

  Options:
  * `hash` - format of the hash. Valid formats include `:sha, :sha224, :sha256, :sha384, :sha512, :ripemd160`. If the hash option is not set, it will use `:sha` by default.
  * `safe` - prevents the creation of new atoms. [See erlang docs](http://erlang.org/doc/man/erlang.html#binary_to_term-2).

  On success, returns
  `{:ok, term}`
  """

  def read(path, hash, opts \\ [])

  # insecure read
  # don't recommend doing this in production. Better to embed the expected
  # hashes. Is also slower because it has to load the file and compute the hash
  # to use as a key even it is is already loaded into the cache.
  def read(path, :insecure, opts) do
    with {:ok, data} <- File.read(path) do
      do_read_term(data, opts)
    else
      err -> err
    end
  end

  def read(path, hash, opts) do
    with {:ok, data} <- File.read(path),
         {:ok, data} <- Hash.verify(data, hash, opts[:hash] || :sha) do
      do_read_term(data, opts)
    else
      err -> err
    end
  end

  # --------------------------------------------------------
  # unzip the data if the unzip option is true. Otherwise just returns
  # the data unchanged.
  defp do_read_term(data, opts) do
    opts =
      case opts[:safe] do
        false -> []
        _ -> [:safe]
      end

    try do
      {:ok, :erlang.binary_to_term(data, opts)}
    rescue
      _ -> {:error, :invalid_term}
    end
  end
end
