#
#  Created by Boyd Multerer on 2021-04-17.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Static do
  require Logger

  @moduledoc """

  ## Overview

  {path, hash, meta}
  """

  # import IEx

  @type id :: String.t() | atom

  @default_src_dir "assets"
  @dst_dir "assets"

  @hash_type :sha3_256
  # @hash_type  :sha3_512

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
  @spec hash() :: atom
  def hash(), do: @hash_type

  # --------------------------------------------------------
  # internal config sugar
  defp config(), do: Application.get_env(:scenic, :assets)
  def module(), do: config()[:module]
  def otp_app(), do: module().otp_app()
  def library(), do: module().library()
  def aliases(), do: config()[:alias] || []

  # --------------------------------------------------------
  @spec resolve_alias(id :: String.t() | atom) :: {:ok, String.t()} | {:error, :not_mapped}
  def resolve_alias(id)
  def resolve_alias(id) when is_bitstring(id), do: {:ok, id}

  def resolve_alias(id) when is_atom(id) do
    with :error <- Keyword.fetch(aliases(), id),
         :error <- Keyword.fetch(@default_aliases, id) do
      {:error, :not_mapped}
    else
      {:ok, id} -> {:ok, id}
    end
  end

  # --------------------------------------------------------
  @spec to_hash(id :: String.t() | atom) ::
          {:ok, binary, String.t()}
          | {:error, :not_found}
  def to_hash(id) do
    with {:ok, id_str} <- resolve_alias(id),
         {:ok, {bin_hash, str_hash, _meta}} <- Map.fetch(library(), id_str) do
      {:ok, bin_hash, str_hash}
    else
      :error -> {:error, :not_found}
      error -> error
    end
  end

  # --------------------------------------------------------
  @spec find_hash(hash :: binary, by :: :str_hash | :bin_hash) ::
          {:ok, hash :: String.t()} | {:error, :not_found}
  def find_hash(hash, :bin_hash) do
    library()
    |> Enum.find_value(fn
      {id, {^hash, _, _}} -> {:ok, id}
      _ -> false
    end)
    |> case do
      {:ok, id} -> {:ok, id}
      _ -> {:error, :not_found}
    end
  end

  def find_hash(hash, :str_hash) do
    library()
    |> Enum.find_value(fn
      {id, {_, ^hash, _}} -> {:ok, id}
      _ -> false
    end)
    |> case do
      {:ok, id} -> {:ok, id}
      _ -> {:error, :not_found}
    end
  end

  # --------------------------------------------------------
  @spec fetch(id :: String.t() | atom) :: {:ok, meta :: any} | :error
  def fetch(id) do
    with {:ok, id} <- resolve_alias(id),
         {:ok, {_bin_hash, _str_hash, meta}} <- Map.fetch(library(), id) do
      {:ok, meta}
    else
      _ -> :error
    end
  end

  # --------------------------------------------------------
  @spec load(id_or_hash :: String.t() | atom, by :: :id | :str_hash | :bin_hash) ::
          {:ok, data :: binary}
          | {:error, :not_found}
          | {:error, :hash_failed}
  def load(id, by \\ :id)

  def load(id, :id) do
    dir =
      otp_app()
      |> :code.priv_dir()
      |> Path.join(@dst_dir)

    with {:ok, bin_hash, str_hash} <- to_hash(id),
         {:ok, bin} <- File.read(Path.join(dir, str_hash)),
         ^bin_hash <- :crypto.hash(@hash_type, bin) do
      {:ok, bin}
    else
      :error -> {:error, :not_found}
      bin when is_binary(bin) -> {:error, :hash_failed}
      err -> err
    end
  end

  def load(hash, :bin_hash) do
    case find_hash(hash, :bin_hash) do
      {:ok, id} -> load(id, :id)
      err -> err
    end
  end

  def load(hash, :str_hash) do
    case find_hash(hash, :str_hash) do
      {:ok, id} -> load(id, :id)
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
    src = opts[:dir] || @default_src_dir

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

    # turns out that some asset names (fonts) on the web must start a letter and not a number
    # append an "a" to the front of every file name to ensure this requirement is met
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
