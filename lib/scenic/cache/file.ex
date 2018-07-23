#
#  Created by Boyd Multerer on November 12, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# simple functions to load a file, following the hashing rules

defmodule Scenic.Cache.File do
  alias Scenic.Cache
  alias Scenic.Cache.Hash

#  import IEx

  #===========================================================================
  defmodule Error do
    defexception [ message: "Hash check failed", err: nil ]
  end

  #============================================================================
  # load a file - hash is required
  # first this tries to claim an existing item from the cache
  # if the item isn't there, then reads it and adds
  # it to the cache.

  #--------------------------------------------------------
  def load( path_data, opts \\ [] )

  def load( path_list, opts ) when is_list(path_list) do
    # if scope was set, preserve it, otherwise set to this process
    opts = Keyword.put_new(opts, :scope, self())
    do_parallel(path_list, fn(path_data) -> load(path_data, opts) end)
  end

  def load( path_data, opts ) do
    {path, hash, hash_type} = Hash.path_params( path_data )
    # try claiming the already cached file before reading it
    case Cache.claim(hash, opts[:scope]) do
      true -> {:ok, hash}
      false ->
        # need to really load the font
        case read( {path, hash, hash_type}, opts ) do
          {:ok, data} -> Cache.put(hash, data, opts[:scope])
          err -> err
        end
      end
  end

  #--------------------------------------------------------
  # def load!( path_data, opts \\ [] )

  # def load!( path_list, opts ) when is_list(path_list) do
  #   # if scope was set, preserve it, otherwise set to this process
  #   opts = Keyword.put_new(opts, :scope, self())
  #   do_parallel(path_list, fn(path_data) -> load!(path_data, opts) end)
  # end

  # def load!( path_data, opts ) do
  #   {path, hash, hash_type} = Hash.path_params( path_data )
  #   # try claiming the already cached file before reading it
  #   case Cache.claim(hash, opts[:scope]) do
  #     true -> hash
  #     false ->
  #       data = read!( {path, hash, hash_type}, opts )
  #       case Cache.put(hash, data, opts[:scope]) do
  #         {:ok, key} -> key
  #         err -> raise "Failed to put item in the cache: #{inspect(err)}"
  #       end
  #     end
  # end


  #============================================================================
  # read a file - hash is required

  #--------------------------------------------------------
  def read( path_data, opts \\ [] )

  def read( path_list, opts ) when is_list(path_list) do
    do_parallel(path_list, fn(path_data) ->
      read(path_data, opts)
    end)
  end

  def read( path_data, opts ) do
    {path, hash, hash_type} = Hash.path_params( path_data )
    case opts[:read] do
      nil ->
        with  {:ok, data} <- File.read(path),
              {:ok, data} <- Hash.verify( data, hash, hash_type ) do
          initialize( data, opts )
        else
          err -> err
        end
      read_func -> read_func.(path, hash, opts)
    end
  end

  #--------------------------------------------------------
  def read!( path_data, opts \\ [] )

  def read!( path_list, opts ) when is_list(path_list) do
    do_parallel(path_list, fn(path_data) -> read!(path_data, opts) end)
  end

  def read!( path_data, opts ) do
    {path, hash, hash_type} = Hash.path_params( path_data )
    case opts[:read] do
      nil ->
        path
        |> File.read!()
        |> Hash.verify!( hash, hash_type )
        |> initialize( opts )
        |> case do
          {:ok, data} -> data
          err -> raise Error, message: "Data init failed", err: err
        end
      read_func -> read_func.(path, hash, opts)
    end
  end


  #============================================================================
  # internal helpers

  # the idea here is to let the caller supply an optional init function
  # which initializes the already read and hash verified data
  defp initialize( data, opts ) do
    case opts[:init] do
      nil  -> {:ok, data}
      init -> init.(data, opts)
    end
  end

  #--------------------------------------------------------
  defp do_parallel(list, action) do
    # spin up tasks
    tasks = Enum.map(list, fn(item) -> 
      Task.async( fn -> action.( item ) end)
    end)

    # wait for the async tasks to complete
    Enum.reduce( tasks, [], fn (task, acc )-> [ Task.await(task) | acc ] end)
    |> Enum.reverse()
  end
  
end

