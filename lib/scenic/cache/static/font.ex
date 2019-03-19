#
#  Created by Boyd Multerer on 2019-03-04.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Static.Font do
  use Scenic.Cache.Base, name: "font", static: true
  alias Scenic.Cache.Support

  # import IEx

  defmodule Error do
    @moduledoc false

    defexception message: "Font not found", err: nil, hash: nil, font_folder: nil
  end

  @default_hash :sha256

  # --------------------------------------------------------
  def load(font_folder, font_ref, opts \\ [])

  def load(
        font_folder,
        %FontMetrics{source: %{signature: hash}},
        opts
      ) do
    load(font_folder, hash, opts)
  end

  # --------------------------------------------------------
  def load(font_folder, {:true_type, hash}, opts) do
    load(font_folder, hash, opts)
  end

  # --------------------------------------------------------
  def load(font_folder, hash, opts)
      when is_bitstring(hash) and is_bitstring(font_folder) do
    # if the static font is already loaded, just return it.

    case member?(hash) do
      true ->
        {:ok, hash}

      false ->
        opts = Keyword.put_new(opts, :hash, @default_hash)

        with {:ok, path} <- resolve_path(font_folder, hash),
             {:ok, font} <- Support.File.read(path, hash, opts),
             {:ok, ^hash} <- put_new(hash, font, opts[:scope]) do
          {:ok, hash}
        else
          err ->
            err
        end
    end
  end

  # --------------------------------------------------------
  def load!(font_folder, font_ref, opts \\ [])

  def load!(
        font_folder,
        %FontMetrics{source: %{signature: hash}},
        opts
      ) do
    load!(font_folder, hash, opts)
  end

  # --------------------------------------------------------
  def load!(font_folder, {:true_type, hash}, opts) do
    load!(font_folder, hash, opts)
  end

  def load!(font_folder, hash, opts)
      when is_bitstring(hash) and is_bitstring(font_folder) do
    # if the static font is already loaded, just return it.
    case member?(hash) do
      true ->
        hash

      false ->
        # use default hash for fonts
        opts = Keyword.put_new(opts, :hash, @default_hash)

        font =
          resolve_path!(font_folder, hash)
          |> Support.File.read!(hash, opts)

        {:ok, ^hash} = put_new(hash, font, opts[:scope])
        hash
    end
  end

  # --------------------------------------------------------
  defp resolve_path(font_folder, hash) do
    font_folder
    |> Path.expand()
    |> Kernel.<>("/**/*#{hash}")
    |> Path.wildcard()
    |> case do
      [] -> {:error, :not_found}
      [path] -> {:ok, path}
      _ -> {:error, :multiple}
    end
  end

  # --------------------------------------------------------
  defp resolve_path!(font_folder, hash) do
    case resolve_path(font_folder, hash) do
      {:ok, path} -> path
      err -> raise Error, err: err, hash: hash, font_folder: font_folder
    end
  end
end
