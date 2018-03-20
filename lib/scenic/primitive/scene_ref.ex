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
  def verify( {name, id} ) when is_atom(name), do: {:ok, {name, id}}
  def verify( {pid, id} ) when is_pid(pid), do: {:ok, {pid, id}}
  def verify( {{module, data}, id} ) when is_atom(module), do: {:ok, {{module, data}, id}}
  def verify( _ ), do: :invalid_data

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