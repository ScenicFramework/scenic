#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# each platform-specific version of exui_platform must implement
# a complient version of Scenic.ViewPort. There won't be any conflics
# as by definition, there should be only one platform adapter in the
# deps of any one build-type of a project.


defmodule Scenic.ViewPort.Driver do
  require Logger

  @callback set_graph(list, pid) :: atom
  @callback update_graph(list, pid) :: atom

  #===========================================================================
  # the using macro for scenes adopting this behavioiur
  defmacro __using__(_use_opts) do
    quote do
      use GenServer
      @behaviour Scenic.ViewPort.Driver
    end # quote
  end # defmacro


  #===========================================================================
  # dispatch api
  
  #----------------------------------------------
  def set_graph( list ),    do: dispatch( :set_graph, list )
  def update_graph( list ), do: dispatch( :update_graph, list )

  #----------------------------------------------
  defp dispatch( action, data ) do
    # dispatch the call to any listening drivers
    Registry.dispatch(:viewport_registry, action, fn(entries) ->
      for {pid, {module, func}} <- entries do
        try do
          apply(module, func, [data, pid])
        catch
          kind, reason ->
            formatted = Exception.format(kind, reason, System.stacktrace)
            Logger.error "Registry.dispatch/3 failed with #{formatted}"
        end
      end
    end)
    :ok
  end


end


























