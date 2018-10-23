#
#  Created by Boyd Multerer on 2017-11-13.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Hash do
  @moduledoc """
  Helper functions to work with hash signatures.

  Both the [`Cache.File`](Scenic.Cache.File.html) and [`Cache.Term`](Scenic.Cache.Term.html)
  modules use cryptographic hash signatures to verify that files are valid before using
  the data they contain.

  This modules provides a collection of helper functions that make it easy to use, generate
  and validate these hashes.

  Any time one of these functions asks for a type of hash, the supported types are:
  `:sha`, `:sha224`, `:sha256`, `:sha384`, `:sha512`, and `:ripemd160`
  """

  @hash_types [:sha, :sha224, :sha256, :sha384, :sha512, :ripemd160]

  @type hash_type ::
          :sha
          | :sha224
          | :sha256
          | :sha384
          | :sha512
          | :ripemd160

  # @type type_error :: {:error, :invalid_hash_type}
  # @type hash_error :: {:error, :hash_failure}

  # ===========================================================================
  defmodule Error do
    @moduledoc false

    defexception message: "Hash check failed"
  end

  # --------------------------------------------------------
  @doc false
  @deprecated "Cache.valid_hash_types/0 will be removed in 0.10.0"
  @spec valid_hash_types() :: [:ripemd160 | :sha | :sha224 | :sha256 | :sha384 | :sha512, ...]
  def valid_hash_types(), do: @hash_types

  # --------------------------------------------------------
  @spec valid_hash_type?(type :: hash_type) :: boolean()
  defp valid_hash_type?(type), do: Enum.member?(@hash_types, type)

  # --------------------------------------------------------
  @spec valid_hash_type!(type :: hash_type) :: hash_type | no_return
  defp valid_hash_type!(type) do
    case Enum.member?(@hash_types, type) do
      true ->
        type

      false ->
        msg = "Invalid hash type: #{type}\r\n" <> "Must be one of: #{inspect(@hash_types)}"
        raise Error, message: msg
    end
  end

  # --------------------------------------------------------
  @doc """
  Calculate the hash of binary data

  Returns the hash wrapped in a `{:ok, hash}` tuple.
  """
  @spec binary(data :: binary, type :: hash_type) ::
          {:ok, bitstring()} | {:error, :invalid_hash_type}
  def binary(data, type) do
    case valid_hash_type?(type) do
      true -> {:ok, type |> :crypto.hash(data) |> Base.url_encode64(padding: false)}
      false -> {:error, :invalid_hash_type}
    end
  end

  @doc """
  Calculate the hash of binary data

  Returns the hash directly.
  """
  @spec binary!(data :: binary, type :: hash_type) :: bitstring()
  def binary!(data, type) do
    valid_hash_type!(type)
    |> :crypto.hash(data)
    |> Base.url_encode64(padding: false)
  end

  # --------------------------------------------------------
  @spec file(path :: bitstring, type :: hash_type) ::
          {:ok, bitstring()} | {:error, :invalid_hash_type}
  def file(path, hash_type) do
    do_compute_file(
      path,
      hash_type,
      valid_hash_type?(hash_type)
    )
  end

  @spec file!(path :: bitstring, type :: hash_type) :: bitstring()
  def file!(path, hash_type) do
    # start the hash context
    hash_context =
      valid_hash_type!(hash_type)
      |> :crypto.hash_init()

    # stream the file into the hash
    File.stream!(path, [], 2048)
    |> Enum.reduce(hash_context, &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.url_encode64(padding: false)
  end

  defp do_compute_file(_, _, false), do: {:error, :invalid_hash_type}

  defp do_compute_file(path, hash_type, true) do
    # start the hash context
    hash_context = :crypto.hash_init(hash_type)

    # since there is no File.stream option, only File.stream!, catch the error
    try do
      # stream the file into the hash
      hash =
        File.stream!(path, [], 2048)
        |> Enum.reduce(hash_context, &:crypto.hash_update(&2, &1))
        |> :crypto.hash_final()
        |> Base.url_encode64(padding: false)

      {:ok, hash}
    rescue
      err ->
        :crypto.hash_final(hash_context)

        case err do
          %{reason: reason} -> {:error, reason}
          _ -> {:error, :hash}
        end
    end
  end

  # --------------------------------------------------------
  @doc """
  Verify that the given data conforms to the given hash.

  If the verification passes, returns `{:ok, data}`
  If it fails, returns `{:error, :hash_failure}`
  """
  @spec verify(data :: binary, hash :: bitstring, type :: hash_type) ::
          {:ok, binary} | {:error, :hash_failure}
  def verify(data, hash, hash_type) do
    case binary(data, hash_type) do
      {:ok, ^hash} -> {:ok, data}
      _ -> {:error, :hash_failure}
    end
  end

  # --------------------------------------------------------
  @doc """
  Verify that the given data conforms to the given hash.

  If the verification passes, returns the data unchanged.
  If it fails, raises an error
  """
  @spec verify!(data :: binary, hash :: bitstring, type :: hash_type) :: binary | no_return
  def verify!(data, hash, hash_type) do
    case binary!(data, hash_type) == hash do
      true -> data
      false -> raise Error
    end
  end

  # --------------------------------------------------------
  @doc """
  Verify that the data in a file conforms to the given hash.

  If the verification passes, returns `{:ok, hash}`
  If it fails, returns `{:error, :hash_failure}`
  """
  @spec verify_file(path :: bitstring, hash :: bitstring, type :: hash_type) ::
          {:ok, binary} | {:error, :hash_failure}
  def verify_file(path, hash, hash_type) do
    case file(path, hash_type) do
      {:ok, computed_hash} ->
        case computed_hash == hash do
          true -> {:ok, hash}
          false -> {:error, :hash_failure}
        end

      err ->
        err
    end
  end

  # --------------------------------------------------------
  @doc """
  Verify that the data in a file conforms to the given hash.

  If the verification passes, returns the hash unchanged.
  If it fails, raises an error
  """
  @spec verify_file!(path :: bitstring, hash :: bitstring, type :: hash_type) ::
          binary | no_return
  def verify_file!(path, hash, hash_type) do
    case file!(path, hash_type) == hash do
      true -> hash
      false -> raise Error
    end
  end

  # # --------------------------------------------------------
  # defp from_path(path) do
  #   path
  #   |> String.split(".")
  #   |> List.last()
  # end

  # # --------------------------------------------------------
  # defp path_params(path)

  # defp path_params(path) when is_bitstring(path) do
  #   hash = from_path(path)
  #   path_params({path, hash, @default_hash})
  # end

  # defp path_params({path, hash_type}) when is_atom(hash_type) do
  #   hash = from_path(path)
  #   path_params({path, hash, hash_type})
  # end

  # defp path_params({path_or_data, hash}), do: path_params({path_or_data, hash, @default_hash})

  # defp path_params({path_or_data, hash, hash_type})
  #     when is_binary(path_or_data) and is_bitstring(hash) and is_atom(hash_type) do
  #   {path_or_data, hash, valid_hash_type!(hash_type)}
  # end

  # defp path_params(path_or_data, hash_or_type), do: path_params({path_or_data, hash_or_type})
  # defp path_params(path_or_data, hash, hash_type), do: path_params({path_or_data, hash, hash_type})
end
