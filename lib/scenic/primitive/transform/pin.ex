#
#  Created by Boyd Multerer on 10/03/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Pin do
  use Scenic.Primitive.Transform

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  defdelegate info(data), to: Scenic.Primitive.Transform.Translate

  # --------------------------------------------------------
  defdelegate verify(percent), to: Scenic.Primitive.Transform.Translate

  # --------------------------------------------------------
  # normalize named stipples
  defdelegate normalize(v2), to: Scenic.Primitive.Transform.Translate
end
