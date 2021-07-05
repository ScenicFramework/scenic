#
#  Created by Boyd Multerer on 2021-04-17.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Static do
  require Logger

  @moduledoc """
  Manages static assets, which are resources such as fonts or images (jpg or png) that
  ship with your application and do not change over time.

  These assets live as seperate files and are hashed so that they are rejected if they
  change in any way after you compile your application. They are cacheable by the
  relay server if you remote your Scenic UI.

  In previous versions of Scenic, static assets were rather complicated to set up
  and maintain. Starting with v0.11, Scenic has an assets build pipeline that manages
  the static assets library for you.

  ### Required Configuration
  Setting up the static asset pipeline requites several inputs that need to be maintained.

  * __Assets Directory__: Typically `/assets` in your main app source directory. This is the
    folder that holds your raw asset files.
  * __Assets Module__: A module in your application that builds and holds the asset library.
  * __Assets Config__: Configuration scripts in your application that indicates where the 
    assets directory is and your assets module.

  #### Assets Directory
  The assets directory typically is typically called `/assets` and lives at the root of
  your application source directory. This can be changed in the config options.

  Example:

  ```
  my_app_src
    assets
      fonts
        roboto.ttf
        custom_font.ttf
      images
        parrot.jpg
        my_logo.png
    config
    lib
    etc...
  ```

  Once the rest of the configuration is complete, adding a new font is as simple as dropping
  the *.ttf file into the /assets/fonts directory and compiling your assets module. Similar
  is true for images.

  #### Assets Library
  When your application is running, there needs to be a module that contains the built asset
  library referring to your static assets. This library holds things like the hash of the
  contents of each asset, and it's parsed metadata.

  You must create this module and compile it with your application. The following example
  is what this module should look like. Replace `MyApplication` and `:my_application` with
  the actual name of your application and it should work.

  ```elixir
  defmodule MyApplication.Assets do
    use Scenic.Assets.Static, otp_app: :my_application
  end
  ```

  IMPORTANT NOTE: When you add a new asset to the assets directory, you may need to force this
  module to recompile for them to be usable. Adding or removing a return at the end should do 
  the trick. In the future, there will be a file system watcher (much like Phoenix has) that
  will do this automatically. Until then, it is pretty easy to do manually.

  #### Assets Configuration
  The final piece is some configuration that connects the assets directory and the assets module
  togther. Put this in your applications config.exs file.

  ```elixir
  config :scenic, :assets,
    module: MyApplication.Assets,
    directory: "/assets",
    alias: [
      parrot: "images/parrot.jpg"
    ]
  ```

  The only required configuration option in the above example is `module: MyApplication.Assets`.

  Use the `:directory` option to change the location of the `/assets` directory. If this option
  is omitted, then `/assets` will be used by default.

  The `:alias` list creates shortcut atoms that refer to the files in the library. This is useful
  if you think an asset id may change during development but want a constant way to refer to it
  in your code. In the above example, the atom :parrot is mapped to the file `images/parrot.jpb`
  and are interchangeable with each other in a graph.

  In this example, the two rect fills are identical as the `:parrot` alias was created
  in the configuration script.

  ```elixir
  Graph.build()
    |> rect({100, 50}, fill: {:image, "images/parrot.jpg"})
    |> rect({100, 50}, fill: {:image, :parrot})
  ```

  The fonts `fonts/roboto.ttf` and `fonts/roboto_mono.ttf` are considered the default
  fonts for Scenic and are automatically aliased to `:roboto` and `:roboto_mono`.
  It is expected that you will include those two fonts in your `/assets/fonts` directory.

  ### Troubleshooting

  If you have added an asset to your assets directory and you think it should be in
  your library, but it isn't, or you can't compile a scene because the asset can't
  be found, then start troubleshooting with the following steps.

  1) Force your assets module to rebuild. Touch it in some way such as adding or removing a
  carriage return at the end, then compile again.
  2) Check that you are using the correct id for the asset in your graph.
  3) If you are using an alias, check it's spelling and its assignment in the config script.
  4) Confirm that the asset itself has valid contents, whether it is a font (.ttf)
    or an image (.jpg or .jpeg or .png)

  That usually does it.

  ### Under the Covers
  When your assets module is compiled, several steps are executed by `Scenic.Assets.Static`
    1) The files in your assets directory are parsed for validity and metadata.
      Valid files move on to the next step
    2) The valid assets files are hashed to create a cryptographic signature that is used
      later when the files are loaded to confirm that they are unchanged.
    3) The asset files are copied into the `/priv/static` directory, which is where they
      are actually loaded from at run time. The name of the file in this directory is
      a `Base.url_encode64/2` version of the hash of the file's contents.
    4) A map is created, which is the actual asset library used at runtime. This map
      has the original file name as keys and holds the hashes, and parsed metadata
      as the contents. This map is stored as a literal object in your assets module
      and is the reason it needs to be compiled when you add a new asset.

  If you are curious and want to see the library yourself, you can query the
  `MyApplication.Assets.library/0` function, which is added at compile time. Alternately,
  the function `Scenic.Assets.Static.library/0` should return the same library.

  ### Future Work
  There are two pieces of work to the static assets pipeline that are planned for the future.

  First is a file system watcher that automatically flags your assets module to be recompiled
  when the contents of the assets directory changes. This would work in a similar way to the
  file system watcher used by Phoenix.

  The second, larger, piece of work is to include optional transform scripts/code when
  your assets module is compiled. This would let you do things like putting a very
  high resolution image in the sources folder and down-scaling at compile time as
  appropriate for the target device you are compiling for. In the meantime, just put
  in the assets you want to use directly.
  """

  # import IEx

  @type id :: String.t() | atom

  @default_src_dir "assets"
  @dst_dir "assets"

  @hash_type :sha3_256

  @default_aliases [
    roboto: "fonts/roboto.ttf",
    roboto_mono: "fonts/roboto_mono.ttf"
  ]

  # ===========================================================================
  defmodule Error do
    @moduledoc false
    defexception message: nil, error: nil, id: nil
  end

  # ===========================================================================
  defmodule Ingestor do
  end

  # ===========================================================================
  # the using macro for scenes adopting this behavior
  defmacro __using__(using_opts \\ []) do
    quote do
      @library Scenic.Assets.Static.build(unquote(using_opts))
      def library(), do: @library
      def otp_app(), do: unquote(using_opts[:otp_app])

      # quote
    end

    # defmacro
  end

  # --------------------------------------------------------
  @doc "Return the hash type used in the library."
  @spec hash() :: atom
  def hash(), do: @hash_type

  # --------------------------------------------------------
  # internal config sugar
  defp config(), do: Application.get_env(:scenic, :assets)

  @doc """
  Return the configured asset library module.
  """
  def module(), do: config()[:module]
  defp otp_app(), do: module().otp_app()

  @doc "Return the compiled asset library."
  def library(), do: module().library()

  @doc "Return the list of configured aliases."
  def aliases() do
    Enum.reduce(
      @default_aliases,
      config()[:alias] || [],
      fn {k, v}, acc -> Keyword.put_new(acc, k, v) end
    )
  end

  # --------------------------------------------------------
  @doc """
  Resolve an id, an alias, or a hash into the asset's id.

  Examples:
  ```elixir
  iex(1)> Scenic.Assets.Static.resolve_id( "fonts/roboto.ttf" )
  {:ok, "fonts/roboto.ttf"}

  iex(2)> Scenic.Assets.Static.resolve_id( :roboto )
  {:ok, "fonts/roboto.ttf"}

  iex(3)> Scenic.Assets.Static.resolve_id( "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE" )
  {:ok, "fonts/roboto.ttf"}
  ```
  """
  @spec resolve_id(id :: String.t() | atom | binary) ::
          {:ok, String.t()}
          | {:error, :not_mapped}
          | {:error, :not_found}

  def resolve_id(id)

  def resolve_id(id) when is_atom(id) do
    case Keyword.fetch(aliases(), id) do
      {:ok, id} -> {:ok, id}
      :error -> {:error, :not_mapped}
    end
  end

  def resolve_id(id) when is_binary(id) do
    case fetch(id) do
      {:ok, _} ->
        {:ok, id}

      :error ->
        case byte_size(id) do
          32 -> do_resolve_bin_hash(id)
          _ -> do_resolve_str_hash(id)
        end
    end
    |> case do
      {:ok, id} -> {:ok, id}
      :error -> {:error, :not_found}
    end
  end

  defp do_resolve_bin_hash(hash) do
    library()
    |> Enum.find_value(fn
      {id, {^hash, _, _}} -> {:ok, id}
      _ -> false
    end)
    |> case do
      {:ok, id} -> {:ok, id}
      _ -> :error
    end
  end

  defp do_resolve_str_hash(hash) do
    library()
    |> Enum.find_value(fn
      {id, {_, ^hash, _}} -> {:ok, id}
      _ -> false
    end)
    |> case do
      {:ok, id} -> {:ok, id}
      _ -> :error
    end
  end

  # --------------------------------------------------------
  @doc """
  Return the cryptographic hash of an asset.

  Return is in the form of `{:ok, binary_hash, string_hash}`

  If the named asset is not in the library, `{:error, :not_found}` is returned.

  Example:
  ```elixir
  iex(1)> Scenic.Assets.Static.to_hash( :roboto )
  {:ok,
   <<243, 145, 76, 95, 149, 49, 167, 23, 114, 99, 197, 95, 239, 40, 165, 67, 253,
     202, 42, 117, 16, 198, 39, 218, 236, 72, 219, 150, 94, 195, 187, 33>>,
   "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"}
  ```
  """
  @spec to_hash(id :: String.t() | atom) ::
          {:ok, binary, String.t()}
          | {:error, :not_found}
  def to_hash(id) do
    with {:ok, id_str} <- resolve_id(id),
         {:ok, {bin_hash, str_hash, _meta}} <- Map.fetch(library(), id_str) do
      {:ok, bin_hash, str_hash}
    else
      :error -> {:error, :not_found}
      error -> error
    end
  end

  # --------------------------------------------------------
  @doc """
  Fetch the metadata for an asset by id.

  Return is in the form of `{:ok, metadata}`

  If the hash is not in the library, `:error` is returned.

  Example:
  ```elixir
  {:ok, meta} = Scenic.Assets.Static.fetch( :parrot )
  ```
  """
  @spec fetch(id :: String.t() | atom) :: {:ok, meta :: any} | :error
  def fetch(id) when is_atom(id) do
    case resolve_id(id) do
      {:ok, id} -> fetch(id)
      _ -> :error
    end
  end

  def fetch(id) do
    case Map.fetch(library(), id) do
      {:ok, {_bin_hash, _str_hash, meta}} -> {:ok, meta}
      :error -> :error
    end
  end

  # --------------------------------------------------------
  @doc """
  Load the binary contents of an asset given it's id or hash.

  Return is in the form of `{:ok, bin}`

  If the asset is not in the library, `{:error, :not_found}` is returned.

  The contents of the file will be hashed and compared against the hash found in
  the library. If this test fails, `{:error, :hash_failed}` is returned.
  """
  @spec load(id :: String.t() | atom | binary) ::
          {:ok, data :: binary}
          | {:error, :not_found}
          | {:error, :hash_failed}

  def load(id) do
    dir =
      otp_app()
      |> :code.priv_dir()
      |> Path.join(@dst_dir)

    with {:ok, id} <- resolve_id(id),
         {:ok, bin_hash, str_hash} <- to_hash(id),
         {:ok, bin} <- File.read(Path.join(dir, str_hash)),
         ^bin_hash <- :crypto.hash(@hash_type, bin) do
      {:ok, bin}
    else
      :error -> {:error, :not_found}
      bin when is_binary(bin) -> {:error, :hash_failed}
      err -> err
    end
  end

  # ===========================================================================
  # called at compile time...
  # intended for internal use

  # --------------------------------------------------------
  @doc false
  def build(opts) when is_list(opts) do
    if !opts[:otp_app] || !is_atom(opts[:otp_app]) do
      raise "use Scenic.Assets requires a valid :otp_app option"
    end

    # build the full path to the source directory
    src = opts[:directory] || @default_src_dir

    # build the full path to the destination artifacts directory
    dst =
      opts[:otp_app]
      |> :code.priv_dir()
      |> Path.join(@dst_dir)

    # make sure the destination directory exists (delete and recreate to keep it clean)
    File.rm_rf(dst)
    File.mkdir!(dst)

    # build the library
    src
    |> Path.join("**")
    |> Path.wildcard()
    |> Enum.reduce(%{}, fn path, lib ->
      case File.dir?(path) do
        true -> lib
        false -> add_file(lib, path, src, dst, opts)
      end
    end)
  end

  defp add_file(library, path, src, dst, opts) do
    # load the source binary data and generate the hash.
    bin = File.read!(path)
    bin_hash = :crypto.hash(@hash_type, bin)
    str_hash = Base.url_encode64(bin_hash, padding: false)

    id = Path.relative_to(path, src)

    # parse the binary to generate the metadata
    # if this fails, then the file is an unknown type and we should output
    # a warning and skip the file.
    case parse_meta(bin, path, opts) do
      {:ok, meta, copy?} ->
        # write out the binary if requested
        with true <- copy?,
             file_out <- Path.join(dst, str_hash),
             false <- File.exists?(file_out) do
          File.write!(file_out, bin)
        end

        # the id is the path minus the "assets" folder at the start
        Map.put(library, id, {bin_hash, str_hash, meta})

      _ ->
        library
    end
  end

  defp parse_meta(bin, path, opts) do
    with :not_parsed <- parse_font(bin, path, opts),
         :not_parsed <- parse_image(path) do
      :not_parsed
    else
      {:ok, meta, copy?} -> {:ok, meta, copy?}
    end
  end

  # The parse_*** functions attempt to parse the binary
  # if they succeed, they return a metadata object.
  # if they fail, return nil
  # also return guidance on if the file should be copied
  defp parse_font(bin, path, opts) do
    case TruetypeMetrics.parse(bin, path) do
      {:ok, meta} ->
        copy? =
          case opts[:copy_font] do
            false -> false
            _ -> true
          end

        {:ok, {:font, meta}, copy?}

      _ ->
        :not_parsed
    end
  end

  defp parse_image(path) do
    with {:ok, bin} <- File.read(path),
         {mime, width, height, _type} <- ExImageInfo.info(bin) do
      {:ok, {:image, {width, height, mime}}, true}
    else
      _ -> :not_parsed
    end
  end
end
