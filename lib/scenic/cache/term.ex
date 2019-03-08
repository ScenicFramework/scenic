#
#  Created by Boyd Multerer on 2019-03-06
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Term do
  @moduledoc """

  This module is completely deprecated and will be removed in a future release

  If you would like a cache for generic terms, or any other type of data, please
  create and supervise a new cache by using the Scenic.Cache.Base module.

  Example

      defmodule MyApp.Cache.Static.MyTerm do
        use Scenic.Cache.Base, name: "my_data_type", static: true

        def load(hash, path, opts) do
          case Scenic.Cache.Support.File.read(path, hash, opts) do
            {:ok, data} ->
              try do
                {:ok, :erlang.binary_to_term(data) }
              rescue
                _ -> {:error, :binary_to_term}
              end

            err ->
              err
          end
        end

        def load!(hash, path, opts) do
          path
          |> Scenic.Cache.Support.File.read!(hash, opts)
          |> :erlang.binary_to_term()
        end
      end
  """

  def read( path, hash, opts \\ [] )
  def read( _, _, _ ) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.Term.read/3 has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please read the documentation for Scenic.Cache.Base to see how to build
    a cache for generic terms.
    """
  end

  def load( path, hash, opts \\ [] )
  def load( _, _, _ ) do
    raise """
    #{IO.ANSI.red()}
    Scenic.Cache.Term.load/3 has been deprecated and is longer supported.
    #{IO.ANSI.yellow()}
    Please read the documentation for Scenic.Cache.Base to see how to build
    a cache for generic terms.
    """
  end

end
