#
#  Created by Boyd Multerer on 2021-04-18.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets do
  require Logger

  @moduledoc """

  ## Overview

  """

  # @type image_format ::
  #         :file
  #         | :g
  #         | :ga
  #         | :rgb
  #         | :rgba

  # @type image_meta ::
  #         {Scenic.Assets.Static.Font, {width :: integer, height :: integer, format :: image_format()}}

  # @type font_meta :: {Scenic.Assets.Static.Font, meta :: map}

  # @type static_meta :: font_meta | image_meta
end
