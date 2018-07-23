#
#  Created by Boyd Multerer on November 11, 2017
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Font do
  alias Scenic.Cache

#  import IEx

  @default_range            {32,255}

  @roboto_regular           "/fonts/Roboto/Roboto-Regular.ttf"
  @roboto_regular_hash      "3RsdsT_x9yE4wTTGLzj--DdJ82o"
  @roboto_regular_ranges    @default_range

  @roboto_mono              "/fonts/Roboto_Mono/RobotoMono-Regular.ttf"
  @roboto_mono_hash         "aaZcK3l9L6EktMcJCX52G3hXoDU"
  @roboto_mono_ranges       @default_range

  @roboto_slab              "/fonts/Roboto_Slab/RobotoSlab-Regular.ttf"
  @roboto_slab_hash         "kSiV5rueBa86Hlih2kF-mSpxoyQ"
  @roboto_slab_ranges       @default_range

  @system_fonts [
    {:roboto,               { @roboto_regular, @roboto_regular_hash, @roboto_regular_ranges} },
    {:roboto_regular,       { @roboto_regular, @roboto_regular_hash, @roboto_regular_ranges} },
    {:roboto_mono,          { @roboto_mono, @roboto_mono_hash, @roboto_mono_ranges} },
    {:roboto_slab,          { @roboto_slab, @roboto_slab_hash, @roboto_slab_ranges} },
  ]

  @app  Mix.Project.config[:app]


  #===========================================================================
  defmodule Error do
    defexception [ message: "Unknown font", font: nil ]
  end


  #--------------------------------------------------------
  def system_font_key( font ) do
    case Enum.find(@system_fonts, fn({f,_}) -> f == font end) do
      nil       -> {:err, :unknown_font}
      {_, {_path, hash, _range}} -> {:ok, hash}
    end
  end


  #============================================================================
  # load a font file into the cache

  #--------------------------------------------------------
  def load( font, opts \\ [] )
  def load( font, opts ) when is_atom(font) do
    case system_font(font) do
      {:ok, {path, hash, range}} ->
        opts = Keyword.put_new(opts, :range, range)
        load( {path, hash}, opts )
      err -> err
    end
  end
  def load( path_data, opts ) when is_list(opts) do
    opts = Keyword.put_new(opts, :init, &initialize/2 )
    Cache.File.load(path_data, opts)
  end

  #============================================================================
  # load! a font file into the cache

  #--------------------------------------------------------
  # def load!( font, opts \\ [] )
  # def load!( font, opts ) when is_atom(font) do
  #   case system_font(font) do
  #     {:ok, {path, hash, range}} ->
  #       opts = Keyword.put_new(opts, :range, range)
  #       load!( {path, hash}, opts )
  #     _ -> raise Error, font: font, message: "Unknown font: #{inspect(font)}"
  #   end
  # end
  # def load!( path_data, opts ) when is_list(opts) do
  #   opts = Keyword.put_new(opts, :init, &initialize/2 )
  #   Cache.File.load!(path_data, opts)
  # end


  #============================================================================
  # internal load helpers

  #--------------------------------------------------------
  defp system_font( font ) do
    case Enum.find(@system_fonts, fn({f,_}) -> f == font end) do
      nil       -> {:err, :unknown_font}
      {_, {path, hash, range}} ->
        priv = :code.priv_dir(@app) |> to_string()
        {:ok, {priv <> path, hash, range}}
    end
  end

  #--------------------------------------------------------
  defp initialize( data, opts ) do
    range = case opts_ranges( opts ) do
      [] -> @default_range
      range -> range
    end
    {:ok, {:font, data, range, "temp"}}
  end

  # defp initialize!( data, opts ) do
  #   case initialize( data, opts ) do
  #     {:ok, font} -> {:ok, font}
  #     _ -> raise Error, message: "Invalid font file"
  #   end
  # end
  
  #--------------------------------------------------------
  def opts_ranges( opts ) do
    Enum.reduce(opts, [], fn(opt, acc) ->
      case opt do
        {:range, range} -> [range | acc]
        _ -> acc
      end
    end)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
    |> merge_overlapping_ranges()
  end
  
  defp merge_overlapping_ranges( ranges, acc \\ [] )
  defp merge_overlapping_ranges( [], acc ),           do: Enum.reverse(acc)
  defp merge_overlapping_ranges( [head | []], acc ),  do: Enum.reverse([head | acc])
  defp merge_overlapping_ranges( [head | tail], acc ) do
    {h_start, h_end} = head
    [{n_start, n_end} | n_tail] = tail
    cond do
      h_end > n_start -> merge_overlapping_ranges( n_tail, [{h_start, n_end} | acc] )
      true -> merge_overlapping_ranges( tail, [head | acc] )
    end
  end



  def ranges_from_text( text ) do
#    text = "A​‌B​‌C​‌Ć​‌Č​‌D​‌Đ​‌E​‌F​‌G​‌H​‌I​‌J​‌K​‌L​‌M​‌N​‌O​‌P​‌Q​‌R​‌S​‌Š" <>
#      "T​‌U​‌V​‌W​‌X​‌Y​‌Z​‌Ž​‌a​‌b​‌c​‌č​‌ć​‌d​‌đ​‌e​‌f​‌g​‌h​‌i​‌j​‌k​‌l​‌m​‌n​‌o" <>
#      "p​‌q​‌r​‌s​‌š​‌t​‌u​‌v​‌w​‌x​‌y​‌z​‌ž​‌А​‌Б​‌В​‌Г​‌Ґ​‌Д​‌Ђ​‌Е​‌Ё​‌Є​‌Ж​‌З" <>
#      "Ѕ​‌И​‌І​‌Ї​‌Й​‌Ј​‌К​‌Л​‌Љ​‌М​‌Н​‌Њ​‌О​‌П​‌Р​‌С​‌Т​‌Ћ​‌У​‌Ў​‌Ф​‌Х" <>
#      "Ц​‌Ч​‌Џ​‌Ш​‌Щ​‌Ъ​‌Ы​‌Ь​‌Э​‌Ю​‌Я​‌а​‌б​‌в​‌г​‌ґ​‌д​‌ђ​‌е​‌ё​‌є​‌ж​‌з" <>
#      "ѕ​‌и​‌і​‌ї​‌й​‌ј​‌к​‌л​‌љ​‌м​‌н​‌њ​‌о​‌п​‌р​‌с​‌т​‌ћ​‌у​‌ў​‌ф​‌х​‌ц​‌ч​‌џ​‌ш" <>
#      "щ​‌ъ​‌ы​‌ь​‌э​‌ю​‌я​‌Α​‌Β​‌Γ​‌Δ​‌Ε​‌Ζ​‌Η​‌Θ​‌Ι​‌Κ​‌Λ​‌Μ​‌Ν​‌Ξ​‌Ο​‌Π" <>
#      "Ρ​‌Σ​‌Τ​‌Υ​‌Φ​‌Χ​‌Ψ​‌Ω​‌α​‌β​‌γ​‌δ​‌ε​‌ζ​‌η​‌θ​‌ι​‌κ​‌λ​‌μ​‌ν​‌ξ​‌ο​‌π​‌ρ" <>
#      "σ​‌τ​‌υ​‌φ​‌χ​‌ψ​‌ω​‌ά​‌Ά​‌έ​‌Έ​‌έ​‌Ή​‌ί​‌ϊ​‌ΐ​‌Ί​‌ό​‌Ό​‌ύ​‌ΰ​‌ϋ​‌Ύ​‌Ϋ​‌Ώ​‌Ă" <>
#      "Â​‌Ê​‌Ô​‌Ơ​‌Ư​‌ă​‌â​‌ê​‌ô​‌ơ​‌ư​‌1​‌2​‌3​‌4​‌5​‌6​‌7​‌8​‌9​‌0​‌‘​‌?​‌’​‌“​‌!​‌”" <>
#      "(​‌%​‌)​‌[​‌#​‌]​‌{​‌@​‌}​‌/​‌&​‌\​‌<​‌-​‌+​‌÷​‌×​‌=​‌>​‌®​‌©​‌$​‌€​‌£​‌¥​‌¢​‌:​‌;​‌," <>
 #     ".​‌*\"\' "

    points = String.to_charlist(text)
    |> Enum.sort()
    |> Enum.uniq()

    [first | rest] = points
    {ranges, first, first} = Enum.reduce(rest, {[], first, first}, fn(point, {acc, crs, crp})->
      cond do
        point == crp + 1 -> {acc, crs, point}
        true -> {[{crs, crp} | acc], point, point}
      end
    end)
    Enum.reverse(ranges)    
  end


  #============================================================================
  # native section

end































