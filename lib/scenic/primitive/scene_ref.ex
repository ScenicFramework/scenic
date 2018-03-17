#
#  Created by Boyd Multerer on 3/16/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.SceneRef do
  use Scenic.Primitive


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Scene reference must be either a pid, an atom (naming a scene)\r\n" <>
    "or a Module and initialization data. See examples:\r\n" <>
    "SceneRef.add( graph, :some_supervised_scene )  # scene you supervise\r\n" <>
    "SceneRef.add( graph, <pid> ) # scene you supervise\r\n" <>
    "SceneRef.add( graph, Button, {{20,20},\"Example\"} ) # will be started for you"
  end

  #--------------------------------------------------------
  def verify( name ) when is_atom(name), do: {:ok, name}
  def verify( pid ) when is_pid(pid), do: {:ok, pid}
  def verify( _ ), do: :invalid_data
  def verify( module, data ) when is_atom(module) do
    try do
      module.verify(data)
    rescue
      _ ->
        :invalid_data
    end
  end


  #============================================================================
  # filter and gather styles

  def valid_styles(),                               do: [:all]
  def filter_styles( styles ) when is_map(styles),  do: styles


  #--------------------------------------------------------
  def default_pin( data )
  def default_pin( _ ) do
    {0,0}
  end

end