#
#  Created by Boyd Multerer on 2019-03-04.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Static.Texture do
  use Scenic.Cache.Base, name: "texture", static: true
  alias Scenic.Cache.Support

  #--------------------------------------------------------
  def load( hash, path, opts \\ [] )
  when is_bitstring(hash) and is_bitstring(path) do
    # if the static font is already loaded, just return it.
    case member?( hash ) do
      true ->
        {:ok, hash}

      false->
        with {:ok, texture} <- Support.File.read(path, hash, opts),
        {:ok, ^hash} <- put_new( hash, texture, opts[:scope] ) do
          {:ok, hash}
        else
          err -> err
        end
    end
  end

  #--------------------------------------------------------
  def load!( hash, path, opts \\ [] )
  when is_bitstring(hash) and is_bitstring(path) do
    # if the static font is already loaded, just return it.
    case member?( hash ) do
      true ->
        hash

      false ->
        texture = Support.File.read!(path, hash, opts)
        {:ok, ^hash} = put_new( hash, texture, opts[:scope] )
        hash
    end
  end

end