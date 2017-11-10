#
#  Created by Boyd Multerer on 11/09/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# a cache for blobs of image/font/cursor type data


defmodule Scenic.ViewPort.Cache do
  use GenServer

  require Logger
  alias Scenic.ViewPort

  import IEx

  @name             :viewport_cache

  @hash_type         :sha
#  @hash_type         :sha224
#  @hash_type         :sha256

  @cache_table      :viewport_cache_table

  #===========================================================================
  defmodule Error do
    defexception [ message: nil ]
  end

  #============================================================================
  # client apis

  #--------------------------------------------------------
  # bin data only - returns key
  def load( scope, data )
  def load( scope, data ) when is_binary(data) do
    hash( data )
  end

  #--------------------------------------------------------
  # files, urls - returns validates & returns key
  def load( scope, data, key ) do
    key
  end
  
  #--------------------------------------------------------
  def release( scope, key ) do
    :ok
  end

  #--------------------------------------------------------
  def status( scope, key ) do
    :ok
  end

  #--------------------------------------------------------
  def keys( scope )

  #--------------------------------------------------------
  def hash( data ) do
    :crypto.hash( @hash_type, data )
    |> Base.url_encode64( padding: false )
  end

  #============================================================================

  #--------------------------------------------------------
  def start_link( opts ) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def init( _ ) do
    state = %{
#      ets_table: :ets.new(@cache_table, [:set, :public, :named]),
      scopes: %{}
    }
    {:ok, state}
  end


  #============================================================================

end















