#
#  Created by Boyd Multerer on 2021-05-05.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Static.Font do
  @moduledoc false

  def parse_meta(bin) do
    case TruetypeMetrics.parse(bin, "") do
      {:ok, meta} -> {:ok, {__MODULE__, meta}}
      _ -> :error
    end
  end
  
end
