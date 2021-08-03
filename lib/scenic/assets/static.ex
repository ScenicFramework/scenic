#
#  Created by Boyd Multerer on 2021-04-17.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Static do
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

  require Logger
  alias Scenic.Assets.Static

  # import IEx

  # ===========================================================================
  # the using macro for scenes adopting this behavior
  defmacro __using__(using_opts \\ []) do
    quote do
      # @library Scenic.Assets.Static.build(__MODULE__, unquote(using_opts))
      @library Scenic.Assets.Static.build!(__MODULE__, unquote(using_opts))
      def library(), do: @library

      # quote
    end

    # defmacro
  end

  # import IEx

  @type id :: String.t() | atom | {atom, String.t()}

  @hash_type :sha3_256

  @dst_dir "_assets"
  @default_src_dir "assets"

  @default_aliases [
    roboto: {:scenic, "fonts/roboto.ttf"},
    roboto_mono: {:scenic, "fonts/roboto_mono.ttf"}
  ]

  @parsers [
    Scenic.Assets.Static.Image,
    Scenic.Assets.Static.Font
  ]

  @type t :: %Scenic.Assets.Static{
          aliases: map,
          metas: map,
          hash_type: :sha3_256,
          module: module,
          otp_app: atom
        }

  defstruct aliases: %{}, metas: %{}, hash_type: @hash_type, module: nil, otp_app: nil

  # ===========================================================================
  defmodule Error do
    @moduledoc false
    defexception message: nil, error: nil, id: nil
  end

  # ===========================================================================

  # --------------------------------------------------------
  # internal config sugar
  defp config(), do: Application.get_env(:scenic, :assets)

  @doc """
  Return the configured asset library module.
  """
  def module(), do: config()[:module]

  @doc "Return the compiled asset library."
  def library(), do: module().library()

  @doc false
  def dst_dir(), do: @dst_dir

  # --------------------------------------------------------
  @doc """
  Transform an asset id into the file hash.

  If you pass in a valid hash, it is returned unchanged

  Example:
  ```elixir
  alias Scenic.Assets.Static
  library = Scenic.Assets.Static.library()

  {:ok, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"} = Static.hash( library, :parrot )
  {:ok, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"} = Static.hash( library, "images/parrot.png" )
  {:ok, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"} = Static.hash( library, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns" )
  ```
  """
  @spec to_hash(id :: any) :: {:ok, hash :: any} | :error
  def to_hash(id), do: library() |> to_hash(id)

  @spec to_hash(library :: t(), id :: any) :: {:ok, hash :: any} | :error
  def to_hash(%Static{aliases: aliases, metas: metas}, id) do
    case Map.fetch(metas, id) do
      {:ok, _} -> {:ok, id}
      :error -> Map.fetch(aliases, id)
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
  @spec meta(id :: any) :: {:ok, meta :: any} | :error
  def meta(id), do: library() |> meta(id)

  @spec meta(library :: t(), id :: any) :: {:ok, meta :: any} | :error
  def meta(%Static{metas: metas} = lib, id) do
    case to_hash(lib, id) do
      {:ok, hash} -> Map.fetch(metas, hash)
      err -> err
    end
  end

  # --------------------------------------------------------
  @doc """
  Load the binary contents of an asset given it's id or hash.

  Return is in the form of `{:ok, bin}`

  If the asset is not in the library, `{:error, :not_found}` is returned.

  The contents of the file will be hashed and compared against the hash found in
  the library. If this test fails, `{:error, :hash_failed}` is returned.

  If the output file cannot be read, it returns a posix error.
  """
  @spec load(id :: any) ::
          {:ok, data :: binary}
          | {:error, :not_found}
          | {:error, :hash_failed}
          | {:error, File.posix()}

  def load(id), do: library() |> load(id)

  @spec load(library :: t(), id :: any) ::
          {:ok, data :: binary}
          | {:error, :not_found}
          | {:error, :hash_failed}
          | {:error, File.posix()}

  def load(%Static{otp_app: otp_app, hash_type: hash_type} = lib, id) do
    dir =
      otp_app
      |> :code.lib_dir()
      |> Path.join(dst_dir())

    with {:ok, str_hash} <- to_hash(lib, id),
         {:ok, bin_hash} <- Base.url_decode64(str_hash, padding: false),
         {:ok, bin} <- File.read(Path.join(dir, str_hash)),
         ^bin_hash <- :crypto.hash(hash_type, bin) do
      {:ok, bin}
    else
      :error -> {:error, :not_found}
      bin when is_binary(bin) -> {:error, :hash_failed}
      err -> err
    end
  end

  # ========================================================

  # --------------------------------------------------------
  @doc false
  def build!(library_module, opts \\ []) when is_atom(library_module) do
    # simultaneously calc the dst dir and validate the :otp_app option
    dst =
      try do
        opts[:otp_app]
        # |> :code.priv_dir()
        |> :code.lib_dir()
        |> Path.join(Static.dst_dir())
      rescue
        _ ->
          raise """
          'use Scenic.Assets.Static' requires a valid :otp_app option.
          """
      end

    # make sure the destination directory exists (delete and recreate to keep it clean)
    File.rm_rf(dst)
    File.mkdir_p!(dst)

    # start building the library
    library = %Static{module: library_module, otp_app: opts[:otp_app]}

    # build the file data and metas from the sources
    library =
      case opts[:sources] do
        nil -> [{opts[:otp_app], @default_src_dir}, {:scenic, "deps/scenic/assets"}]
        srcs -> srcs
      end
      |> Enum.reduce(library, &build_from_source(&2, &1, dst))

    # add the default aliases
    library = Enum.reduce(@default_aliases, library, &add_alias(&2, &1))

    # add any additional aliases, then return
    case opts[:alias] || opts[:aliases] do
      nil -> []
      aliases -> aliases
    end
    |> Enum.reduce(library, &add_alias(&2, &1))
  end

  # --------------------------------------------------------
  defp build_from_source(library, source, dst)

  defp build_from_source(%Static{otp_app: app} = lib, src, dst) when is_bitstring(src) do
    build_from_source(lib, {app, src}, dst)
  end

  defp build_from_source(%Static{} = lib, {app, dir}, dst)
       when is_atom(app) and is_bitstring(dir) do
    # build the library
    dir
    |> Path.join("**")
    |> Path.wildcard()
    |> Enum.reduce(lib, fn path, lib ->
      case File.dir?(path) do
        true -> lib
        false -> ingest_file(lib, app, dir, path, dst)
      end
    end)
  end

  defp build_from_source(%Static{module: mod}, src, _dst) do
    raise """
    Invalid :sources list when building assets library #{inspect(mod)}
    Received: #{inspect(src)}

    Expected a list of sources in the format of
    [{otp_app, assets_path}]
    """
  end

  # --------------------------------------------------------
  defp ingest_file(%Static{otp_app: otp_app, hash_type: hash_type} = lib, src_app, dir, path, dst) do
    with {:ok, bin} <- File.read(path),
         {:ok, meta} <- parse_bin(bin) do
      id = Path.relative_to(path, dir)
      bin_hash = :crypto.hash(hash_type, bin)
      str_hash = Base.url_encode64(bin_hash, padding: false)

      Path.join(dst, str_hash) |> File.write!(bin)

      # fill in the library entries
      lib =
        lib
        |> assign(:metas, str_hash, meta)
        |> assign(:aliases, {src_app, id}, str_hash)

      case otp_app == src_app do
        true -> assign(lib, :aliases, id, str_hash)
        false -> lib
      end
    else
      _ -> lib
    end
  end

  # --------------------------------------------------------
  def assign(%Static{metas: metas} = lib, :metas, key, value) do
    %{lib | metas: Map.put(metas, key, value)}
  end

  def assign(%Static{aliases: aliases} = lib, :aliases, key, value) do
    %{lib | aliases: Map.put(aliases, key, value)}
  end

  # --------------------------------------------------------
  defp parse_bin(bin) do
    @parsers
    |> Enum.find_value(fn parser ->
      case parser.parse_meta(bin) do
        {:ok, meta} -> {:ok, meta}
        _ -> false
      end
    end)
    |> case do
      {:ok, meta} -> {:ok, meta}
      _ -> :error
    end
  end

  # --------------------------------------------------------
  defp add_alias(library, new_alias)

  defp add_alias(%Static{aliases: aliases} = lib, {new_alias, to}) do
    case Map.fetch(aliases, to) do
      {:ok, hash} ->
        assign(lib, :aliases, new_alias, hash)

      _ ->
        Logger.warn("Attempted to alias #{inspect(new_alias)} to unknown asset: #{inspect(to)}")
        lib
    end
  end

  defp add_alias(%Static{module: mod}, src) do
    raise """
    Invalid :alias list when building assets library #{inspect(mod)}
    Received: #{inspect(src)}

    Expected a list of sources in the format of
    [alias_one: relative_path, alias_two: {otp_app, relative_path}]
    """
  end
end
