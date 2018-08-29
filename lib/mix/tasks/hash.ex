defmodule Mix.Tasks.Scenic.Hash do
  use Mix.Task
  alias Scenic.Cache.Hash

  @shortdoc "Compute the hash of a file"

  @moduledoc """
  Starts the application

  The `--no-halt` flag is automatically added.
  """

  @switches [
    hash: :string
  ]

  @default_hash   "sha"

  @hash_types Hash.valid_hash_types()
  @hash_map  Enum.reduce(@hash_types, %{}, &Map.put(&2, to_string(&1), &1) )

  # import IEx

  @doc false
  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv, strict: @switches)

    with {:ok, path }<- validate_path( List.first(argv) ),
    {:ok, hash} <- validate_hash( opts[:hash] || @default_hash ) do
      IO.puts ""
      IO.puts "File hash using #{inspect(hash)}"
      case File.dir?(path) do
        true -> hash_dir( path, hash )
        false -> hash_file( path, hash )
      end
      IO.puts ""
    end
  end

  defp hash_dir( path, hash ) do
    File.ls!( path )
    |> Enum.each( fn(sub_path) ->
      p = Path.join(path, sub_path)
      unless File.dir?(p), do: hash_file( p, hash )
    end)
  end

  defp hash_file( path, hash ) do
    IO.write path <> " -> "
    {:ok, hash} = Hash.compute_file(path, hash)
    IO.inspect( hash )
  end


  defp validate_path( path ) do
    case File.exists?(path) do
      true -> {:ok, path}
      false ->
        IO.puts(
          IO.ANSI.red() <>
          "Invalid Path: \"#{path}\"" <>
          IO.ANSI.default_color()
        )
        :error
    end
  end

  defp validate_hash( hash ) do
    case @hash_map[hash] do
      nil ->
        IO.puts(
          IO.ANSI.red() <>
          "Invalid hash option: \"#{hash}\"\r\n" <>
          IO.ANSI.yellow() <>
          "Must be one of: " <>
          Enum.join( @hash_types, ", " ) <>
          "\r\nIf you don't supply a --hash option it will use sha by default" <>
          IO.ANSI.default_color()
        )
        :error
      h -> {:ok, h}
    end
  end

end
