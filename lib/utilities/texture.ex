#
#  Created by Boyd Multerer on 2019-03-17.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Utilities.Texture do
  alias Scenic.Primitive.Style.Paint.Color

  @app Mix.Project.config()[:app]

  # load the NIF
  @compile {:autoload, false}
  @on_load :load_nifs

  @doc false
  def load_nifs do
    :ok =
      @app
      |> :code.priv_dir()
      |> :filename.join('texture')
      |> :erlang.load_nif(0)
  end

  # --------------------------------------------------------

  # def build( :g, width, height, g ) when
  # is_integer(g) and g >= 0 and g <= 255 and
  # is_integer(width) and is_integer(height) and width > 0 and height > 0 do
  #   {:g, width, height, nif_pixels(width * height, g), []}
  # end

  def build(type, width, height, opts \\ [])

  def build(:g, width, height, opts)
      when is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    {g, opts} =
      case opts[:clear] do
        nil ->
          {0, opts}

        hint_clear ->
          c = prep_clear(:g, hint_clear)
          {c, Keyword.put(opts, :clear, c)}
      end

    case validate_channel(g, :invalid_clear) do
      :ok -> {:ok, {:g, width, height, nif_pixels(width * height, g), opts}}
      err -> err
    end
  end

  # def build( :ga, width, height, {g,a} ) when
  # is_integer(g) and g >= 0 and g <= 255 and
  # is_integer(a) and a >= 0 and a <= 255 and
  # is_integer(width) and is_integer(height) and width > 0 and height > 0 do
  #   {:ga, width, height, nif_pixels(width * height * 2, g, a), []}
  # end

  def build(:ga, width, height, opts)
      when is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    {{g, a}, opts} =
      case opts[:clear] do
        nil ->
          {{0, 0xFF}, opts}

        hint_clear ->
          c = prep_clear(:ga, hint_clear)
          {c, Keyword.put(opts, :clear, c)}
      end

    with :ok <- validate_channel(g, :invalid_clear),
         :ok <- validate_channel(a, :invalid_clear) do
      {:ok, {:ga, width, height, nif_pixels(width * height * 2, g, a), opts}}
    else
      err -> err
    end
  end

  # def build( :rgb, width, height, color ) when
  # is_integer(width) and is_integer(height) and width > 0 and height > 0 do
  #   {r,g,b,_} = Color.to_rgba(color)
  #   {:rgb, width, height, nif_pixels(width * height * 3, r, g, b), []}
  # end

  def build(:rgb, width, height, opts)
      when is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    {{r, g, b}, opts} =
      case opts[:clear] do
        nil ->
          {{0, 0, 0}, opts}

        hint_clear ->
          c = prep_clear(:rgb, hint_clear)
          {c, Keyword.put(opts, :clear, c)}
      end

    with :ok <- validate_channel(r, :invalid_clear),
         :ok <- validate_channel(g, :invalid_clear),
         :ok <- validate_channel(b, :invalid_clear) do
      {:ok, {:rgb, width, height, nif_pixels(width * height * 3, r, g, b), opts}}
    else
      err -> err
    end
  end

  def build(:rgba, width, height, opts)
      when is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    {{r, g, b, a}, opts} =
      case opts[:clear] do
        nil ->
          {{0, 0, 0, 0xFF}, opts}

        hint_clear ->
          c = prep_clear(:rgba, hint_clear)
          {c, Keyword.put(opts, :clear, c)}
      end

    with :ok <- validate_channel(r, :invalid_clear),
         :ok <- validate_channel(g, :invalid_clear),
         :ok <- validate_channel(b, :invalid_clear),
         :ok <- validate_channel(a, :invalid_clear) do
      {:ok, {:rgba, width, height, nif_pixels(width * height * 4, r, g, b, a), opts}}
    else
      err -> err
    end
  end

  defp validate_channel(v, err_type) do
    with true <- is_integer(v),
         true <- v >= 0,
         true <- v <= 0xFF do
      :ok
    else
      _ -> {:error, err_type}
    end
  end

  defp nif_pixels(_, _), do: :erlang.nif_error("Did not find nif_pixels_g")
  defp nif_pixels(_, _, _), do: :erlang.nif_error("Did not find nif_pixels_ga")
  defp nif_pixels(_, _, _, _), do: :erlang.nif_error("Did not find nif_pixels_rgb")
  defp nif_pixels(_, _, _, _, _), do: :erlang.nif_error("Did not find nif_pixels_rgba")

  # --------------------------------------------------------
  def build!(type, width, height, opts \\ []) do
    {:ok, texture} = build(type, width, height, opts)
    texture
  end

  # --------------------------------------------------------
  def get(texture, x, y)

  def get({:g, w, h, p, _}, x, y) when x >= 0 and x <= w and y >= 0 and y <= h,
    do: nif_get_g(p, y * w + x)

  def get({:ga, w, h, p, _}, x, y) when x >= 0 and x <= w and y >= 0 and y <= h,
    do: nif_get_ga(p, y * w + x)

  def get({:rgb, w, h, p, _}, x, y) when x >= 0 and x <= w and y >= 0 and y <= h,
    do: nif_get_rgb(p, y * w + x)

  def get({:rgba, w, h, p, _}, x, y) when x >= 0 and x <= w and y >= 0 and y <= h,
    do: nif_get_rgba(p, y * w + x)

  defp nif_get_g(_, _), do: :erlang.nif_error("Did not find nif_get_g")
  defp nif_get_ga(_, _), do: :erlang.nif_error("Did not find nif_get_ga")
  defp nif_get_rgb(_, _), do: :erlang.nif_error("Did not find nif_get_rgb")
  defp nif_get_rgba(_, _), do: :erlang.nif_error("Did not find nif_get_rgba")

  # --------------------------------------------------------
  def put!(texture, x, y, color)

  def put!({:g, w, h, p, hints}, x, y, color) when x >= 0 and x <= w and y >= 0 and y <= h do
    g = prep_color(:g, color)
    nif_put(p, y * w + x, g)
    {:g, w, h, p, hints}
  end

  def put!({:ga, w, h, p, hints}, x, y, color) when x >= 0 and x <= w and y >= 0 and y <= h do
    {g, a} = prep_color(:ga, color)
    nif_put(p, y * w + x, g, a)
    {:ga, w, h, p, hints}
  end

  def put!({:rgb, w, h, p, hints}, x, y, color) when x >= 0 and x <= w and y >= 0 and y <= h do
    {r, g, b} = prep_color(:rgb, color)
    nif_put(p, y * w + x, r, g, b)
    {:rgb, w, h, p, hints}
  end

  def put!({:rgba, w, h, p, hints}, x, y, color) when x >= 0 and x <= w and y >= 0 and y <= h do
    {r, g, b, a} = Color.to_rgba(color)
    nif_put(p, y * w + x, r, g, b, a)
    {:rgba, w, h, p, hints}
  end

  defp nif_put(_, _, _), do: :erlang.nif_error("Did not find nif_put_g")
  defp nif_put(_, _, _, _), do: :erlang.nif_error("Did not find nif_put_ga")
  defp nif_put(_, _, _, _, _), do: :erlang.nif_error("Did not find nif_put_rgb")
  defp nif_put(_, _, _, _, _, _), do: :erlang.nif_error("Did not find nif_put_rgba")

  # --------------------------------------------------------
  def clear!(texture, color \\ nil)

  def clear!({:g, w, h, p, hints}, color) do
    g = prep_clear(:g, hints[:clear], color)
    {:g, w, h, nif_clear(p, g), hints}
  end

  def clear!({:ga, w, h, p, hints}, color) do
    {g, a} = prep_clear(:ga, hints[:clear], color)
    {:ga, w, h, nif_clear(p, g, a), hints}
  end

  def clear!({:rgb, w, h, p, hints}, color) do
    {r, g, b} = prep_clear(:rgb, hints[:clear], color)
    {:rgb, w, h, nif_clear(p, r, g, b), hints}
  end

  def clear!({:rgba, w, h, p, hints}, color) do
    {r, g, b, a} = prep_clear(:rgba, hints[:clear], color)
    {:rgba, w, h, nif_clear(p, r, g, b, a), hints}
  end

  defp nif_clear(_, _), do: :erlang.nif_error("Did not find nif_clear_g")
  defp nif_clear(_, _, _), do: :erlang.nif_error("Did not find nif_clear_ga")
  defp nif_clear(_, _, _, _), do: :erlang.nif_error("Did not find nif_clear_rgb")
  defp nif_clear(_, _, _, _, _), do: :erlang.nif_error("Did not find nif_clear_rgba")

  # --------------------------------------------------------
  def to_rgba(texture)

  def to_rgba({:g, w, h, p, hints}) do
    {:rgba, w, h, nif_g_to_rgba(p, w * h), hints}
  end

  def to_rgba({:ga, w, h, p, hints}) do
    {:rgba, w, h, nif_ga_to_rgba(p, w * h), hints}
  end

  def to_rgba({:rgb, w, h, p, hints}) do
    {:rgba, w, h, nif_rgb_to_rgba(p, w * h), hints}
  end

  def to_rgba({:rgba, _, _, _, _} = tex), do: tex

  defp nif_g_to_rgba(_, _), do: :erlang.nif_error("Did not find nif_g_to_rgba")
  defp nif_ga_to_rgba(_, _), do: :erlang.nif_error("Did not find nif_ga_to_rgba")
  defp nif_rgb_to_rgba(_, _), do: :erlang.nif_error("Did not find nif_rgb_to_rgba")

  # --------------------------------------------------------
  defp prep_clear(type, hint_clear, color \\ nil)

  defp prep_clear(type, hint_clear, color) do
    prep_color(type, color || hint_clear || :black)
  end

  # --------------------------------------------------------
  defp prep_color(type, color)

  defp prep_color(:g, g) when is_integer(g), do: g

  defp prep_color(:g, color) do
    {r, g, b, _} = Color.to_rgba(color)
    trunc((r + g + b) / 3)
  end

  defp prep_color(:ga, {g, a}) when is_integer(g) and is_integer(a), do: {g, a}

  defp prep_color(:ga, color) do
    {r, g, b, a} = Color.to_rgba(color)
    {trunc((r + g + b) / 3), a}
  end

  defp prep_color(:rgb, {r, g, b})
       when is_integer(r) and is_integer(g) and is_integer(b) do
    {r, g, b}
  end

  defp prep_color(:rgb, color) do
    {r, g, b, _} = Color.to_rgba(color)
    {r, g, b}
  end

  defp prep_color(:rgba, color), do: Color.to_rgba(color)
end
