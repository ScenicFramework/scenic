#
#  Created by Boyd Multerer on 2018-08-08.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# Seperate Status out into its own file

defmodule Scenic.ViewPort.Status do
  @moduledoc false

  alias Scenic.ViewPort.Status
  alias Scenic.Math

  defstruct drivers: nil,
            root_config: nil,
            root_graph: nil,
            root_scene_pid: nil,
            size: nil,
            styles: %{},
            transforms: %{}

  @type t :: %Status{
          drivers: map,
          root_config: {scene_module :: atom, args :: any} | (scene_name :: atom),
          root_graph: {:graph, reference, any},
          root_scene_pid: pid,
          size: Math.point(),
          styles: map,
          transforms: map
        }
end
