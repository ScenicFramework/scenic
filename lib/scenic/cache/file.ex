#
#  Created by Boyd Multerer on 2019-03-06.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.File do
  @moduledoc """
  This module is deprecated and has moved `Scenic.Cache.Support.File`

  Please adjust accordingly as this module will be removed in a future version
  """

  @deprecated "Scenic.Cache.File.read/3 is now Scenic.Cache.Support.File.read/3"
  defdelegate read(path, hash, opts), to: Scenic.Cache.Support.File

  @deprecated "Use load in the appropriate cache module"
  def load( path, hash, opts \\ [] )
  def load( _, _, _ ) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.File.load/3 has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please use the load functions in the appropriate type-specific cache module.

    Asset Class                 | Module
    ----------------------------|--------------------------------
    Fonts                       | Scenic.Cache.Static.Font
    Font Metrics                | Scenic.Cache.Static.FontMetrics
    Textures (images in a fill) | Scenic.Cache.Static.Texture
    #{IO.ANSI.default_color()}
    """
  end

end
