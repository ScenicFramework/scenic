#
#  Created by Boyd Multerer on 2019-03-06.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Hash do
  @moduledoc """
  This module is deprecated and has moved `Scenic.Cache.Support.Hash`

  Please adjust accordingly as this module will be removed in a future version
  """

  @deprecated "Scenic.Cache.Hash.binary/2 is now Scenic.Cache.Support.Hash.binary/2"
  defdelegate binary(data, type), to: Scenic.Cache.Support.Hash

  @deprecated "Scenic.Cache.Hash.binary!/2 is now in Scenic.Cache.Support.Hash.binary!/2"
  defdelegate binary!(data, type), to: Scenic.Cache.Support.Hash

  @deprecated "Scenic.Cache.Hash.file/3 is now in Scenic.Cache.Support.Hash.file/3"
  defdelegate file(path, hash_type), to: Scenic.Cache.Support.Hash

  @deprecated "Scenic.Cache.Hash.file!/3 is now in Scenic.Cache.Support.Hash.file!/3"
  defdelegate file!(path, hash_type), to: Scenic.Cache.Support.Hash

  @deprecated "Scenic.Cache.Hash.verify/3 is now in Scenic.Cache.Support.Hash.verify/3"
  defdelegate verify(data, hash, hash_type), to: Scenic.Cache.Support.Hash

  @deprecated "Scenic.Cache.Hash.verify!/3 is now in Scenic.Cache.Support.Hash.verify!/3"
  defdelegate verify!(data, hash, hash_type), to: Scenic.Cache.Support.Hash

  @deprecated "Scenic.Cache.Hash.verify_file/3 is now in Scenic.Cache.Support.Hash.verify_file/3"
  defdelegate verify_file(path, hash, hash_type), to: Scenic.Cache.Support.Hash

  @deprecated "Scenic.Cache.Hash.verify_file!/3 is now in Scenic.Cache.Support.Hash.verify_file!/3"
  defdelegate verify_file!(path, hash, hash_type), to: Scenic.Cache.Support.Hash
end
