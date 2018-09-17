#
#  Created by Boyd Multerer on November 12, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# simple functions to load a file, following the hashing rules

defmodule Scenic.Cache.Term do
  alias Scenic.Cache
  alias Scenic.Cache.Hash

  #  import IEx

  # --------------------------------------------------------
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
