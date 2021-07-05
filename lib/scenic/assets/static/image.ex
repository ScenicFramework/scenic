#
#  Created by Boyd Multerer on 2021-05-05.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Static.Image do
  @moduledoc false

  def parse_meta(bin) do
    case ExImageInfo.info(bin) do
      {mime, width, height, _type} -> {:ok, {__MODULE__, {width, height, mime}}}
      _ -> :error
    end
  end
end
