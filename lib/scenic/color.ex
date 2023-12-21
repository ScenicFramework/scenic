#
#  Created by Boyd Multerer on 2021-06-28
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Color do
  alias Scenic.Themes

  @g :color_g
  @ga :color_ga
  @rgb :color_rgb
  @rgba :color_rgba
  @hsv :color_hsv
  @hsl :color_hsl

  @moduledoc """
  APIs to create and work with colors.

  Colors are used in multiple places in Scenic. Fills and Strokes of a
  single color are quite common.

  ## Data Format

  There are multiple ways to define colors.

  The native format of color on modern computers is RGBA. This is four channels
  including Red, Green, Blue, and Alpha. Alpha indicates transparency, and is
  used to blend the color being applied at any given location with the color
  that is already there.

  Most of the time, you will use one of the pre-defined named colors from the
  Named Colors table. However, there are times when you want to work with
  other color formats ranging from simple grayscale to rgb to hsl.

  The following formats are all supported by the `Scenic.Color` module.
  The values of r, g, b, and a are integers between 0 and 255.
  For HSL and HSV, h is a float between 0 and 360, while the s, v and l values
  are floats between 0 and 100.

  | Format                     | Implicit       | Explicit                    |
  |----------------------------|----------------|-----------------------------|
  | Named Color                | *na*           | See the Named Color Table   |
  | Grayscale                  | `g`            | `{:#{@g}, g}`               |
  | Gray, Alpha                | `{g, a}`       | `{:#{@ga}, {g, a}}`         |
  | Red, Green, Blue           | `{r, g, b}`    | `{:#{@rgb}, {r, g, b}}`     |
  | Red, Green, Blue, Alpha    | `{r, g, b, a}` | `{:#{@rgba}, {r, g, b, a}}` |
  | Hue, Saturation, Value     | *na*           | `{:#{@hsv}, {h, s, v}}`     |
  | Hue, Saturation, Lightness | *na*           | `{:#{@hsl}, {h, s, l}}`     |


  ## Named Colors

  The simplest is to used a named color (see the table below). Named colors are simply
  referred to by an atom, which is their name. Named colors are opaque by default.
  I failed to figure out how to show a table with colored cells in exdoc. So this is
  a list of all the color names. I'll eventually add a link to a page that shows them
  visually.


  ## Additional Named Colors

  | Name          | Value                       |
  |---------------|-----------------------------|
  | `:clear` | `{0x80, 0x80, 0x80, 0x00}`       |
  | `:transparent` | `{0x80, 0x80, 0x80, 0x00}` |

  ## Converting Between Color Formats

  By using the functions `to_g/1`, `to_ga/1`, `to_rgb/1`, `to_rgb/1`,
  `to_hsl/1`, and `to_hsv/1` you can convert between any implicit or explicit
  color type to any explicit color type.
  """

  @g :color_g
  @ga :color_ga
  @rgb :color_rgb
  @rgba :color_rgba
  @hsv :color_hsv
  @hsl :color_hsl

  # Epsilon value from JS
  # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/EPSILON
  @epsilon 2.22044e-16

  @type implicit ::
          atom
          | {name :: atom, a :: integer}
          | (gray :: integer)
          | {gray :: integer, alpha :: integer}
          | {red :: integer, green :: integer, blue :: integer}
          | {red :: integer, green :: integer, blue :: integer, alpha :: integer}

  @type g :: {:color_g, grey :: integer}
  @type ga :: {:color_ga, {grey :: integer, alpha :: integer}}
  @type rgb :: {:color_rgb, {red :: integer, green :: integer, blue :: integer}}
  @type rgba ::
          {:color_rgba, {red :: integer, green :: integer, blue :: integer, alpha :: integer}}
  @type hsv :: {:color_hsv, {hue :: number, saturation :: number, value :: number}}
  @type hsl :: {:color_hsl, {hue :: number, saturation :: number, lightness :: number}}
  @type explicit :: g | ga | rgb | rgba | hsl | hsv

  @type t :: implicit | explicit

  # ============================================================================
  # https://www.w3schools.com/colors/colors_names.asp

  @doc false
  defguard is_uint8(x) when is_integer(x) and x >= 0 and x <= 255

  # --------------------------------------------------------
  @doc """
  Convert a specified color to G format (just grayscale)

  This is a lossy conversion and will lose any color information other than the gray level.
  """
  @spec to_g(color :: t()) :: g()
  def to_g(g) when is_uint8(g), do: {@g, g}
  def to_g({g, a}) when is_uint8(g) and is_uint8(a), do: {@g, g}

  def to_g({r, g, b}) when is_uint8(r) and is_uint8(g) and is_uint8(b) do
    {@g, do_rgb_to_g({r, g, b})}
  end

  def to_g({r, g, b, a})
      when is_uint8(r) and is_uint8(g) and is_uint8(b) and is_uint8(a) do
    {@g, do_rgb_to_g({r, g, b})}
  end

  def to_g({@g, g}), do: {@g, g}
  def to_g({@ga, {g, _a}}), do: {@g, g}
  def to_g({@rgb, rgb}), do: {@g, do_rgb_to_g(rgb)}
  def to_g({@rgba, {r, g, b, _a}}), do: {@g, do_rgb_to_g({r, g, b})}

  def to_g({@hsv, hsv}) do
    g =
      hsv
      |> do_hsv_to_rgb()
      |> do_rgb_to_g()

    {@g, g}
  end

  def to_g({@hsl, hsl}) do
    g =
      hsl
      |> do_hsl_to_rgb()
      |> do_rgb_to_g()

    {@g, g}
  end

  def to_g(name) when is_atom(name), do: {@g, name_to_rgb(name) |> do_rgb_to_g()}
  def to_g({name, _a}) when is_atom(name), do: {@g, name_to_rgb(name) |> do_rgb_to_g()}

  # --------------------------------------------------------
  @doc """
  Convert a specified color to GA format
  """
  @spec to_ga(color :: t()) :: ga()
  def to_ga(g) when is_uint8(g), do: {@ga, {g, 0xFF}}
  def to_ga({g, a}) when is_uint8(g) and is_uint8(a), do: {@ga, {g, a}}

  def to_ga({r, g, b}) when is_uint8(r) and is_uint8(g) and is_uint8(b) do
    {@ga, {do_rgb_to_g({r, g, b}), 0xFF}}
  end

  def to_ga({r, g, b, a})
      when is_uint8(r) and is_uint8(g) and is_uint8(b) and is_uint8(a) do
    {@ga, {do_rgb_to_g({r, g, b}), a}}
  end

  def to_ga({@g, g}), do: {@ga, {g, 0xFF}}
  def to_ga({@ga, ga}), do: {@ga, ga}
  def to_ga({@rgb, rgb}), do: {@ga, {do_rgb_to_g(rgb), 0xFF}}
  def to_ga({@rgba, {r, g, b, a}}), do: {@ga, {do_rgb_to_g({r, g, b}), a}}

  def to_ga({@hsv, hsv}) do
    g =
      hsv
      |> do_hsv_to_rgb()
      |> do_rgb_to_g()

    {@ga, {g, 0xFF}}
  end

  def to_ga({@hsl, hsl}) do
    g =
      hsl
      |> do_hsl_to_rgb()
      |> do_rgb_to_g()

    {@ga, {g, 0xFF}}
  end

  def to_ga(name) when is_atom(name) do
    {@ga, {name_to_rgb(name) |> do_rgb_to_g(), 0xFF}}
  end

  def to_ga({name, a}) when is_atom(name) and is_uint8(a) do
    {@ga, {name_to_rgb(name) |> do_rgb_to_g(), a}}
  end

  # --------------------------------------------------------
  @doc """
  Convert a specified color to RGB format
  """
  @spec to_rgb(color :: t()) :: rgb()
  def to_rgb(g) when is_uint8(g), do: {@rgb, {g, g, g}}
  def to_rgb({g, a}) when is_uint8(g) and is_uint8(a), do: {@rgb, {g, g, g}}

  def to_rgb({r, g, b}) when is_uint8(r) and is_uint8(g) and is_uint8(b) do
    {@rgb, {r, g, b}}
  end

  def to_rgb({r, g, b, a})
      when is_uint8(r) and is_uint8(g) and is_uint8(b) and is_uint8(a) do
    {@rgb, {r, g, b}}
  end

  def to_rgb({@g, g}), do: {@rgb, {g, g, g}}
  def to_rgb({@ga, {g, _}}), do: {@rgb, {g, g, g}}
  def to_rgb({@rgb, rgb}), do: {@rgb, rgb}
  def to_rgb({@rgba, {r, g, b, _}}), do: {@rgb, {r, g, b}}

  def to_rgb({@hsv, hsv}) do
    {@rgb, do_hsv_to_rgb(hsv)}
  end

  def to_rgb({@hsl, hsl}) do
    {@rgb, do_hsl_to_rgb(hsl)}
  end

  def to_rgb(name) when is_atom(name), do: {@rgb, name_to_rgb(name)}

  def to_rgb({name, a}) when is_atom(name) and is_uint8(a) do
    {@rgb, name_to_rgb(name)}
  end

  # --------------------------------------------------------
  @doc """
  Convert a specified color to RGBA format
  """
  @spec to_rgba(color :: t()) :: rgba()
  def to_rgba(g) when is_uint8(g), do: {@rgba, {g, g, g, 0xFF}}
  def to_rgba({g, a}) when is_uint8(g) and is_uint8(a), do: {@rgba, {g, g, g, a}}

  def to_rgba({r, g, b}) when is_uint8(r) and is_uint8(g) and is_uint8(b) do
    {@rgba, {r, g, b, 0xFF}}
  end

  def to_rgba({r, g, b, a})
      when is_uint8(r) and is_uint8(g) and is_uint8(b) and is_uint8(a) do
    {@rgba, {r, g, b, a}}
  end

  def to_rgba({@g, g}), do: {@rgba, {g, g, g, 0xFF}}
  def to_rgba({@ga, {g, a}}), do: {@rgba, {g, g, g, a}}
  def to_rgba({@rgb, {r, g, b}}), do: {@rgba, {r, g, b, 0xFF}}
  def to_rgba({@rgba, {r, g, b, a}}), do: {@rgba, {r, g, b, a}}

  def to_rgba({@hsv, hsv}) do
    {r, g, b} = do_hsv_to_rgb(hsv)
    {@rgba, {r, g, b, 0xFF}}
  end

  def to_rgba({@hsl, hsl}) do
    {r, g, b} = do_hsl_to_rgb(hsl)
    {@rgba, {r, g, b, 0xFF}}
  end

  def to_rgba(:clear), do: {@rgba, {0, 0, 0, 0}}
  def to_rgba(:transparent), do: {@rgba, {0, 0, 0, 0}}

  def to_rgba(name) when is_atom(name) do
    {r, g, b} = name_to_rgb(name)
    {@rgba, {r, g, b, 0xFF}}
  end

  def to_rgba({name, a}) when is_atom(name) and is_uint8(a) do
    {r, g, b} = name_to_rgb(name)
    {@rgba, {r, g, b, a}}
  end

  # --------------------------------------------------------
  @doc """
  Convert a color to the HSV color space
  """
  @spec to_hsv(color :: t()) :: hsv()
  def to_hsv({@hsv, hsv}), do: {@hsv, hsv}

  def to_hsv(color) do
    {@rgb, rgb} = to_rgb(color)
    {@hsv, do_rgb_to_hsv(rgb)}
  end

  # --------------------------------------------------------
  @doc """
  Convert a color to the HSL color space
  """
  @spec to_hsl(color :: t()) :: hsl()
  def to_hsl({@hsl, hsl}), do: {@hsl, hsl}

  def to_hsl(color) do
    {@rgb, rgb} = to_rgb(color)
    {@hsl, do_rgb_to_hsl(rgb)}
  end

  # --------------------------------------------------------
  # internal helpers

  # ------------------------------------
  defp do_rgb_to_g({r, g, b}) do
    round((r + g + b) / 3)
  end

  # ------------------------------------
  defp do_rgb_to_hsv({0, 0, 0}), do: {0, 0, 0}

  defp do_rgb_to_hsv({r, g, b}) do
    # convert to range of 0 to 1
    r = r / 255
    g = g / 255
    b = b / 255

    # prep
    min = min(r, g) |> min(b)
    max = max(r, g) |> max(b)
    delta = max - min

    # calculate hsv
    h = rgb_to_hue(r, g, b)
    s = delta / max * 100
    v = max * 100

    {h, s, v}
  end

  defp do_hsv_to_rgb({_, 0, v}), do: {v, v, v}

  defp do_hsv_to_rgb({h, s, v}) do
    s = s / 100
    v = v / 100

    # prep hue
    h =
      h
      |> rem_f(360.0)
      # convert away from degrees
      |> Kernel./(60.0)

    i = trunc(h)
    f = h - i

    # intermediate values
    p = v * (1.0 - s)
    q = v * (1.0 - s * f)
    t = v * (1.0 - s * (1.0 - f))

    {r, g, b} =
      case i do
        0 -> {v, t, p}
        1 -> {q, v, p}
        2 -> {p, v, t}
        3 -> {p, q, v}
        4 -> {t, p, v}
        _ -> {v, p, q}
      end

    # rgb is in 0 to 255 space
    {
      round(r * 255),
      round(g * 255),
      round(b * 255)
    }
  end

  defp do_rgb_to_hsl({0, 0, 0}), do: {0, 0, 0}

  defp do_rgb_to_hsl({r, g, b}) do
    # convert to range of 0 to 1
    r = r / 255
    g = g / 255
    b = b / 255

    # prep
    min = min(r, g) |> min(b)
    max = max(r, g) |> max(b)
    delta = max - min

    # calculate hsl
    h = rgb_to_hue(r, g, b)
    l = (max + min) / 2

    s =
      cond do
        delta < @epsilon -> 0.0
        true -> delta / (1 - abs(2 * l - 1))
      end

    {h, s * 100, l * 100}
  end

  defp do_hsl_to_rgb({h, s, l}) do
    s = s / 100
    l = l / 100

    # prep hue
    h =
      h
      |> rem_f(360.0)
      # convert away from degrees
      |> Kernel./(60.0)

    i = trunc(h)

    c = (1 - abs(2 * l - 1)) * s
    x = c * (1 - abs(rem_f(h, 2) - 1))
    m = l - c / 2

    {r, g, b} =
      case i do
        0 -> {c, x, 0}
        1 -> {x, c, 0}
        2 -> {0, c, x}
        3 -> {0, x, c}
        4 -> {x, 0, c}
        _ -> {c, 0, x}
      end

    # rgb is in 0 to 255 space
    {
      round((r + m) * 255),
      round((g + m) * 255),
      round((b + m) * 255)
    }
  end

  # rgb should be 0 to 1
  defp rgb_to_hue(r, g, b) do
    # prep
    min = min(r, g) |> min(b)
    max = max(r, g) |> max(b)
    delta = max - min

    # calculate hsv
    h =
      cond do
        delta == 0 -> 0
        # between yellow and magenta
        r == max -> (g - b) / delta
        # between cyan and yellow
        g == max -> 2.0 + (b - r) / delta
        # between magenta and cyan
        b == max -> 4.0 + (r - g) / delta
      end
      # convert to degrees
      |> Kernel.*(60.0)

    # make sure it is positive and return
    case h < 0.0 do
      true -> h + 360.0
      false -> h
    end
  end

  # similar to rem, but works with floats
  defp rem_f(num, base)
       when is_number(num) and is_number(base) and
              num >= 0 and base >= 0 do
    num - trunc(num / base) * base
  end

  # --------------------------------------------------------
  @spec named :: map
  @doc """
  Return map of all named colors and their values
  """
  def named(), do: Themes.get_palette()

  # --------------------------------------------------------
  # @doc """
  # Convert a named color to RGB format
  # """
  @spec name_to_rgb(name :: atom) ::
          {red :: pos_integer, green :: pos_integer, blue :: pos_integer}
  defp name_to_rgb(name) when is_atom(name) do
    named()
    |> Map.get(name)
  end
end
