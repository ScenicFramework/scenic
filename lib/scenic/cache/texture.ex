#
#  Created by Boyd Multerer on November 15, 2017
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# for now, am doing the naive, although faster, implementation of load. First it loads the entire
# source file into memory and verifies it. Then it passes that blob into the native code.
# A more memory efficient, although slower, way is to verify the file via streaming first, then
# stream the file again through the native image reader. I would probably do that if the stb
# code supported a different style of streaming instead of through callbacks.

defmodule Scenic.Cache.Texture do
  alias Scenic.Cache

#  import IEx

  @system_textures          []

  #===========================================================================
  defmodule Error do
    defexception [ message: "Unknown texture", texture: nil ]
  end

  #============================================================================
  # load a texture file into the cache
#
  #--------------------------------------------------------
  def load( texture, opts \\ [] )
  def load( texture, opts ) when is_atom(texture) do
    case system_texture_path(texture) do
      {:ok, path_data} -> load( path_data, opts )
      err -> err
    end
  end
  def load( path_data, opts ) when is_list(opts) do
    opts = Keyword.put_new(opts, :init, &initialize/2 )
    Cache.File.load(path_data, opts)
  end


  #============================================================================
  # load! a texture file into the cache

  #--------------------------------------------------------
  def load!( texture, opts \\ [] )
  def load!( texture, opts ) when is_atom(texture) do
    case system_texture_path(texture) do
      {:ok, path_data} -> load!( path_data, opts )
      _ -> raise Error, texture: texture, message: "Unknown texture: #{inspect(texture)}"
    end
  end
  def load!( path_data, opts ) when is_list(opts) do
    opts = Keyword.put_new(opts, :init, &initialize/2 )
    Cache.File.load!(path_data, opts)
  end


  #============================================================================
  # internal load helpers

  #--------------------------------------------------------
  defp initialize( data, _opts ) do
    {:ok, {:texture, data}}
  end

  #--------------------------------------------------------
  defp system_texture_path( texture ) do
    case Enum.find(@system_textures, fn({t,_}) -> t == texture end) do
      nil       -> {:err, :unknown_texture}
      {_, path} -> {:ok, path}
    end
  end
    
  
  #============================================================================
  # native section

end
