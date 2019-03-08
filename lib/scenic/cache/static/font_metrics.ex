#
#  Created by Boyd Multerer on 2019-03-04.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Static.FontMetrics do
  use Scenic.Cache.Base, name: "font_metrics", static: true
  alias Scenic.Cache.Support

  # import IEx

  @base_path "static/font_metrics"

  :code.priv_dir(:scenic)
  |> Path.join(@base_path)
  |> File.ls()
  |> IO.inspect(label: "metrics_files")

  @roboto_path "Roboto-Regular.ttf.metrics"
  @roboto_hash :code.priv_dir(:scenic)
               |> Path.join(@base_path)
               |> Path.join(@roboto_path)
               |> Support.Hash.file!(:sha)

  @roboto_mono_path "RobotoMono-Regular.ttf.metrics"
  @roboto_mono_hash :code.priv_dir(:scenic)
                    |> Path.join(@base_path)
                    |> Path.join(@roboto_mono_path)
                    |> Support.Hash.file!(:sha)

  @type sys_fonts :: :roboto | :roboto_mono

  # ============================================================================
  # override the getters to support the system fonts

  # --------------------------------------------------------
  def get(hash_or_sys_font, default \\ :roboto)

  def get(:roboto, default) do
    path = font_path(@roboto_path)

    case load(@roboto_hash, path) do
      {:ok, @roboto_hash} -> get(@roboto_hash, default)
      _ -> default
    end
  end

  def get(:roboto_mono, default) do
    path = font_path(@roboto_mono_path)

    case load(@roboto_mono_hash, path) do
      {:ok, @roboto_mono_hash} -> get(@roboto_mono_hash, default)
      _ -> default
    end
  end

  def get(hash, default) do
    case fetch(hash) do
      {:ok, fm} ->
        fm

      _ ->
        case default do
          nil -> nil
          other -> get(other, nil)
        end
    end
  end

  # --------------------------------------------------------
  def get!(hash_or_sys_font)

  def get!(:roboto) do
    path = font_path(@roboto_path)

    load!(@roboto_hash, path)
    |> super()
  end

  def get!(:roboto_mono) do
    path = font_path(@roboto_mono_path)

    load!(@roboto_mono_hash, path)
    |> super()
  end

  def get!(hash) when is_bitstring(hash), do: super(hash)

  # --------------------------------------------------------
  def fetch(hash_or_sys_font)

  def fetch(:roboto) do
    path = font_path(@roboto_path)

    case load(@roboto_hash, path) do
      {:ok, @roboto_hash} -> super(@roboto_hash)
      err -> err
    end
  end

  def fetch(:roboto_mono) do
    path = font_path(@roboto_mono_path)

    case load(@roboto_mono_hash, path) do
      {:ok, @roboto_mono_hash} -> super(@roboto_mono_hash)
      err -> err
    end
  end

  def fetch(hash) when is_bitstring(hash), do: super(hash)

  # --------------------------------------------------------
  def load(hash, path, opts \\ [])

  def load(hash, path, opts) when is_bitstring(hash) and is_bitstring(path) do
    # if the static font_metrics are already loaded, just return them.
    case member?(hash) do
      true ->
        {:ok, hash}

      false ->
        with {:ok, data} <- Support.File.read(path, hash, opts),
             {:ok, metrics} <- FontMetrics.from_binary(data) do
          put_new(hash, metrics, opts[:scope])
        else
          err -> err
        end
    end
  end

  # --------------------------------------------------------
  def load!(hash, path, opts \\ [])

  def load!(hash, path, opts) do
    case member?(hash) do
      true ->
        hash

      false ->
        metrics =
          path
          |> Support.File.read!(hash, opts)
          |> FontMetrics.from_binary!()

        {:ok, ^hash} = put_new(hash, metrics, opts[:scope])
        hash
    end
  end

  defp font_path(file) do
    :code.priv_dir(:scenic)
    |> Path.join(@base_path)
    |> Path.join(file)
  end
end
