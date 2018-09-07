defmodule Mix.Tasks.Scenic.Run do
  use Mix.Task

  @shortdoc "Starts the UI application"

  @moduledoc """
  Starts the application

  The `--no-halt` flag is automatically added.
  """

  @doc false
  def run(args) do
    Mix.Tasks.Run.run(run_args() ++ args)
  end

  defp run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end
end
