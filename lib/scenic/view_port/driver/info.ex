#
#  Created by Boyd Multerer April 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# helper module for configuring ViewPorts during startup

defmodule Scenic.ViewPort.Driver.Info do
  defstruct module: nil, type: nil, id: nil, width: -1, height: -1, pid: nil, private: nil
end
