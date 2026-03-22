defmodule Scenic.Layout do
  @moduledoc """
  Pure layout functions for computing child bounds.

  These are stateless helpers — input is dimensions + layout spec, output is
  bounds maps. No side effects, no state. Scenes call them in render to compute
  child positions.

  ## Bounds Format

  All functions produce bounds maps: `%{x: number, y: number, w: number, h: number}`.
  These can be passed directly to Widgets as their bounds prop.

  ## Examples

      # Split horizontally: 35% left, 65% right
      %{left: left, right: right} = Layout.hsplit(800, 600, ratio: 0.35)
      # left  = %{x: 0, y: 0, w: 280, h: 600}
      # right = %{x: 280, y: 0, w: 520, h: 600}

      # Vertical stack: 60px header, flexible middle, 40px footer
      [header, body, footer] = Layout.vstack(800, 600, [60, :flex, 40])
      # header = %{x: 0, y: 0, w: 800, h: 60}
      # body   = %{x: 0, y: 60, w: 800, h: 500}
      # footer = %{x: 0, y: 560, w: 800, h: 40}
  """

  @doc """
  Split a region horizontally into left and right panels.

  ## Options

  - `:ratio` — fraction of width for the left panel (default 0.5)
  - `:gap` — pixel gap between panels (default 0)

  ## Example

      Layout.hsplit(1600, 1200, ratio: 0.35)
      # => %{left: %{x: 0, y: 0, w: 560, h: 1200},
      #      right: %{x: 560, y: 0, w: 1040, h: 1200}}
  """
  def hsplit(width, height, opts \\ []) do
    ratio = Keyword.get(opts, :ratio, 0.5)
    gap = Keyword.get(opts, :gap, 0)

    left_w = trunc(width * ratio)
    right_w = width - left_w - gap

    %{
      left: %{x: 0, y: 0, w: left_w, h: height},
      right: %{x: left_w + gap, y: 0, w: right_w, h: height}
    }
  end

  @doc """
  Split a region vertically into top and bottom panels.

  ## Options

  - `:ratio` — fraction of height for the top panel (default 0.5)
  - `:gap` — pixel gap between panels (default 0)

  ## Example

      Layout.vsplit(800, 600, ratio: 0.6)
      # => %{top: %{x: 0, y: 0, w: 800, h: 360},
      #      bottom: %{x: 0, y: 360, w: 800, h: 240}}
  """
  def vsplit(width, height, opts \\ []) do
    ratio = Keyword.get(opts, :ratio, 0.5)
    gap = Keyword.get(opts, :gap, 0)

    top_h = trunc(height * ratio)
    bottom_h = height - top_h - gap

    %{
      top: %{x: 0, y: 0, w: width, h: top_h},
      bottom: %{x: 0, y: top_h + gap, w: width, h: bottom_h}
    }
  end

  @doc """
  Stack regions vertically within a container.

  Each entry in `sizes` is either:
  - A positive integer — fixed pixel height
  - `:flex` — takes remaining space (only one `:flex` allowed)

  Returns a list of bounds maps in the same order as `sizes`.

  ## Example

      Layout.vstack(800, 600, [60, :flex, 40])
      # => [%{x: 0, y: 0, w: 800, h: 60},
      #     %{x: 0, y: 60, w: 800, h: 500},
      #     %{x: 0, y: 560, w: 800, h: 40}]
  """
  def vstack(width, height, sizes) do
    fixed_total = sizes |> Enum.reject(&(&1 == :flex)) |> Enum.sum()
    flex_h = max(0, height - fixed_total)

    {regions, _y} =
      Enum.map_reduce(sizes, 0, fn
        :flex, y -> {%{x: 0, y: y, w: width, h: flex_h}, y + flex_h}
        h, y     -> {%{x: 0, y: y, w: width, h: h}, y + h}
      end)

    regions
  end

  @doc """
  Stack regions horizontally within a container.

  Each entry in `sizes` is either:
  - A positive integer — fixed pixel width
  - `:flex` — takes remaining space (only one `:flex` allowed)

  Returns a list of bounds maps in the same order as `sizes`.

  ## Example

      Layout.hstack(800, 600, [200, :flex, 100])
      # => [%{x: 0, y: 0, w: 200, h: 600},
      #     %{x: 200, y: 0, w: 500, h: 600},
      #     %{x: 700, y: 0, w: 100, h: 600}]
  """
  def hstack(width, height, sizes) do
    fixed_total = sizes |> Enum.reject(&(&1 == :flex)) |> Enum.sum()
    flex_w = max(0, width - fixed_total)

    {regions, _x} =
      Enum.map_reduce(sizes, 0, fn
        :flex, x -> {%{x: x, y: 0, w: flex_w, h: height}, x + flex_w}
        w, x     -> {%{x: x, y: 0, w: w, h: height}, x + w}
      end)

    regions
  end

  @doc """
  Inset bounds by a uniform padding.

  ## Example

      Layout.pad(%{x: 0, y: 0, w: 800, h: 600}, 20)
      # => %{x: 20, y: 20, w: 760, h: 560}
  """
  def pad(%{x: x, y: y, w: w, h: h}, padding) when is_number(padding) do
    %{x: x + padding, y: y + padding, w: max(0, w - padding * 2), h: max(0, h - padding * 2)}
  end

  @doc """
  Inset bounds with different horizontal and vertical padding.

  ## Example

      Layout.pad(%{x: 0, y: 0, w: 800, h: 600}, {20, 10})
      # => %{x: 20, y: 10, w: 760, h: 580}
  """
  def pad(%{x: x, y: y, w: w, h: h}, {pad_x, pad_y}) do
    %{x: x + pad_x, y: y + pad_y, w: max(0, w - pad_x * 2), h: max(0, h - pad_y * 2)}
  end
end
