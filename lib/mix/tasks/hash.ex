# credo:disable-for-this-file Credo.Check.Warning.IoInspect
defmodule Mix.Tasks.Scenic.Hash do
  use Mix.Task

  @shortdoc "Compute the hash of a file - mix scenic.hash path_to_file"

  @moduledoc """
  Compute the hash of a file or multiple files in directory.

  example:

      mix scenic.hash mix.exs

      >> File hash using :sha
      >> mix.exs -> "SjGBfd6TiDy7kbknjxt1uFbui6Q"

  Options

  --hash hash_type

  You can specify which hash algorithm to use with the --hash switch. The valid
  hash types you can specify are [ sha, sha224, sha256, sha384, sha512, ripemd160 ]

      mix scenic.hash mix.exs --hash sha256

      >> File hash using :sha256
      >> mix.exs -> "Svs-U3-UaMvp5i_Okpj9v92oX5uQmGIp0WHn_aRWt2w"


  You can also point it at a directory to have it hash the files within

      mix scenic.hash guides
      
      >> File hash using :sha
      >> guides/overview_graph.md -> "xu6ihkVwAX7W8-Rzr2U769DR46w"
      >> guides/overview_general.md -> "UNcd84guRIEBK5a0tWdp5MYmJpI"
      >> guides/overview_driver.md -> "zsTJ_xDQGrXLBtQk80hSUt-wZYE"
      >> guides/scene_lifecycle.md -> "jNcP7dPNXon0zEMtyCqL2z-A7FY"
      >> guides/overview_scene.md -> "apxgZRkCBHZeNNzCMpxgQRytHLA"
      >> guides/getting_started.md -> "v1So-K14iPs_mGQZqr237TPah8I"
      >> guides/overview_viewport.md -> "3TpXIFxcwG54N2bb0O-86aznSS4"
      >> guides/mix_tasks.md -> "CWp9l8tDfHf5czjJqpbKtPqaqlc"
  """

  @switches [
    hash: :string
  ]

  @default_hash "sha"

  @hash_types Scenic.Cache.Hash.valid_hash_types()
  @hash_map Enum.reduce(@hash_types, %{}, &Map.put(&2, to_string(&1), &1))

  # import IEx

  @doc false
  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv, strict: @switches)

    with {:ok, path} <- validate_path(List.first(argv)),
         {:ok, hash} <- validate_hash(opts[:hash] || @default_hash) do
      IO.puts("")
      IO.puts("File hash using #{inspect(hash)}")

      case File.dir?(path) do
        true -> hash_dir(path, hash)
        false -> hash_file(path, hash)
      end

      IO.puts("")
    end
  end

  defp hash_dir(path, hash) do
    File.ls!(path)
    |> Enum.each(fn sub_path ->
      p = Path.join(path, sub_path)
      unless File.dir?(p), do: hash_file(p, hash)
    end)
  end

  defp hash_file(path, hash) do
    IO.write(path <> " -> ")
    {:ok, hash} = do_hash_file(path, hash)
    IO.inspect(hash)
  end

  defp validate_path(path) do
    case File.exists?(path) do
      true ->
        {:ok, path}

      false ->
        IO.puts(IO.ANSI.red() <> "Invalid Path: \"#{path}\"" <> IO.ANSI.default_color())
        :error
    end
  end

  defp validate_hash(hash) do
    case @hash_map[hash] do
      nil ->
        IO.puts(
          IO.ANSI.red() <>
            "Invalid hash option: \"#{hash}\"\r\n" <>
            IO.ANSI.yellow() <>
            "Must be one of: " <>
            Enum.join(@hash_types, ", ") <>
            "\r\nIf you don't supply a --hash option it will use sha by default" <>
            IO.ANSI.default_color()
        )

        :error

      h ->
        {:ok, h}
    end
  end

  defp do_hash_file(path, hash_type) do
    # start the hash context
    hash_context = :crypto.hash_init(hash_type)

    # since there is no File.stream option, only File.stream!, catch the error
    try do
      # stream the file into the hash
      hash =
        File.stream!(path, [], 2048)
        |> Enum.reduce(hash_context, &:crypto.hash_update(&2, &1))
        |> :crypto.hash_final()
        |> Base.url_encode64(padding: false)

      {:ok, hash}
    rescue
      err ->
        :crypto.hash_final(hash_context)

        case err do
          %{reason: reason} -> {:error, reason}
          _ -> {:error, :hash}
        end
    end
  end
end
