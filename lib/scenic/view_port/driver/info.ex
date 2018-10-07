#
#  Created by Boyd Multerer April 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Driver.Info do
  @moduledoc """
  Helper module for configuring ViewPorts during startup
  """

  defstruct module: nil, type: nil, id: nil, width: -1, height: -1, pid: nil, private: nil
end
