#
#  Created by Boyd Multerer on 2021-02-06
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Driver do
  @moduledoc """

  Drivers make up the bottom layer of the Scenic architectural stack. They draw
  everything on the screen and originate the raw user input. In general, different
  hardware platforms will need different drivers.

  The interface between drivers and the ViewPort that hosts them is a command-buffer
  like immediate-mode API. Scenes and Graphs are compiled down to into binary
  scripts that are handed to the drivers. The drivers are then responsible for
  rendering them in whatever way makes sense for the hardware they support.

  These scripts come in the form of messages that are cast to the drivers.
  {:title, string } Update the title of the ViewPort
  {:background, color } Update the background color
  {:size, width, height } Update the size of the ViewPort
  {:root, id} Sets the id of the root script
  {:put_script, id, data} put a script
  {:del_script, id} delete a script, which is no longer in use

  Drivers can also send messages containing user input back up to the ViewPort
  """

  # ============================================================================
  # callback definitions

  @callback validate_opts(opts :: Keyword.t()) ::
              {:ok, any}
              | {:error, String.t()}
              | {:error, NimbleOptions.ValidationError.t()}

  @callback init(
              vp_info :: Scenic.ViewPort.t(),
              opts :: Keyword.t()
            ) :: {:ok, any}

  # @callback build_assets(
  #             src_dir :: String.t()
  #           ) :: :ok | :error

  # ===========================================================================
  defmodule Error do
    defexception message: nil
  end

  # ===========================================================================
  # the using macro for scenes adopting this behavior
  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour Scenic.Driver

      def validate_opts(opts), do: {:ok, opts}

      def init({vp_info, opts}) do
        GenServer.cast(vp_info.pid, {:register_driver, self()})
        {:ok, nil, {:continue, {:__init__, vp_info, opts}}}
      end

      def build_assets(_src_dir), do: :ok

      def start_link({vp_info, opts}) do
        opts = Keyword.delete(opts, :module)

        case opts[:name] do
          nil -> GenServer.start_link(__MODULE__, {vp_info, opts})
          name -> GenServer.start_link(__MODULE__, {vp_info, opts}, name: name)
        end
      end

      def handle_continue({:__init__, vp_info, opts}, nil) do
        assets = opts[:assets]

        opts =
          opts
          |> Keyword.delete(:module)
          |> Keyword.delete(:name)

        {:ok, state} = init(vp_info, opts)
        {:noreply, state}
      end

      # --------------------------------------------------------
      defoverridable validate_opts: 1,
                     handle_continue: 2,
                     build_assets: 1
    end

    # quote
  end

  # options validation
  @opts_schema [
    module: [required: true, type: :atom],
    name: [type: :atom]
  ]

  @doc false
  def validate([]), do: {:ok, []}

  def validate(drivers) do
    case Enum.reduce(drivers, [], &do_validate(&1, &2)) do
      opts when is_list(opts) -> {:ok, Enum.reverse(opts)}
      err -> err
    end
  end

  defp do_validate(opts, drivers) do
    core_opts =
      []
      |> put_set(:module, opts[:module])
      |> put_set(:name, opts[:name])

    driver_opts =
      opts
      |> Keyword.delete(:module)
      |> Keyword.delete(:name)

    with {:ok, core} <- NimbleOptions.validate(core_opts, @opts_schema),
         {:ok, opts} <- core[:module].validate_opts(driver_opts) do
      [core ++ opts | drivers]
    else
      {:error, %NimbleOptions.ValidationError{} = error} ->
        raise Exception.message(error)
        # err -> err
    end
  end

  defp put_set(opts, _, nil), do: opts
  defp put_set(opts, key, value), do: Keyword.put(opts, key, value)
end
