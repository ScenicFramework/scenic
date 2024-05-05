defmodule Scenic.ColorTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest Scenic.Color

  alias Scenic.Color

  test "to_g implied" do
    # from bisque
    g = round((0xFF + 0xE4 + 0xC4) / 3)
    assert Color.to_g(128) == {:color_g, 128}
    assert Color.to_g({128, 200}) == {:color_g, 128}
    assert Color.to_g(:bisque) == {:color_g, g}
    assert Color.to_g({:bisque, 200}) == {:color_g, g}
    assert Color.to_g({0xFF, 0xE4, 0xC4}) == {:color_g, g}
    assert Color.to_g({0xFF, 0xE4, 0xC4, 0xFF}) == {:color_g, g}
  end

  test "to_g explicit" do
    # from bisque
    hsv = Color.to_hsv(:bisque)
    hsl = Color.to_hsl(:bisque)
    g = round((0xFF + 0xE4 + 0xC4) / 3)

    assert Color.to_g({:color_g, 128}) == {:color_g, 128}
    assert Color.to_g({:color_ga, {128, 200}}) == {:color_g, 128}
    assert Color.to_g({:color_rgb, {0xFF, 0xE4, 0xC4}}) == {:color_g, g}
    assert Color.to_g({:color_rgba, {0xFF, 0xE4, 0xC4, 0xFF}}) == {:color_g, g}
    assert Color.to_g(hsv) == {:color_g, g}
    assert Color.to_g(hsl) == {:color_g, g}
  end

  test "to_ga implied" do
    # from bisque
    g = round((0xFF + 0xE4 + 0xC4) / 3)
    assert Color.to_ga(128) == {:color_ga, {128, 0xFF}}
    assert Color.to_ga({128, 200}) == {:color_ga, {128, 200}}
    assert Color.to_ga(:bisque) == {:color_ga, {g, 0xFF}}
    assert Color.to_ga({:bisque, 200}) == {:color_ga, {g, 200}}
    assert Color.to_ga({0xFF, 0xE4, 0xC4}) == {:color_ga, {g, 0xFF}}
    assert Color.to_ga({0xFF, 0xE4, 0xC4, 200}) == {:color_ga, {g, 200}}
  end

  test "to_ga explicit" do
    # from bisque
    hsv = Color.to_hsv(:bisque)
    hsl = Color.to_hsl(:bisque)
    g = round((0xFF + 0xE4 + 0xC4) / 3)

    assert Color.to_ga({:color_g, 128}) == {:color_ga, {128, 0xFF}}
    assert Color.to_ga({:color_ga, {128, 200}}) == {:color_ga, {128, 200}}
    assert Color.to_ga({:color_rgb, {0xFF, 0xE4, 0xC4}}) == {:color_ga, {g, 0xFF}}
    assert Color.to_ga({:color_rgba, {0xFF, 0xE4, 0xC4, 200}}) == {:color_ga, {g, 200}}
    assert Color.to_ga(hsv) == {:color_ga, {g, 0xFF}}
    assert Color.to_ga(hsl) == {:color_ga, {g, 0xFF}}
  end

  test "to_rgb implied" do
    # from bisque
    assert Color.to_rgb(128) == {:color_rgb, {128, 128, 128}}
    assert Color.to_rgb({128, 200}) == {:color_rgb, {128, 128, 128}}
    assert Color.to_rgb(:bisque) == {:color_rgb, {0xFF, 0xE4, 0xC4}}
    assert Color.to_rgb({:bisque, 200}) == {:color_rgb, {0xFF, 0xE4, 0xC4}}
    assert Color.to_rgb({0xFF, 0xE4, 0xC4}) == {:color_rgb, {0xFF, 0xE4, 0xC4}}
    assert Color.to_rgb({0xFF, 0xE4, 0xC4, 200}) == {:color_rgb, {0xFF, 0xE4, 0xC4}}
  end

  test "to_rgb explicit" do
    # from bisque
    hsv = Color.to_hsv(:bisque)
    hsl = Color.to_hsl(:bisque)
    assert Color.to_rgb({:color_g, 128}) == {:color_rgb, {128, 128, 128}}
    assert Color.to_rgb({:color_ga, {128, 200}}) == {:color_rgb, {128, 128, 128}}
    assert Color.to_rgb({:color_rgb, {0xFF, 0xE4, 0xC4}}) == {:color_rgb, {0xFF, 0xE4, 0xC4}}

    assert Color.to_rgb({:color_rgba, {0xFF, 0xE4, 0xC4, 200}}) ==
             {:color_rgb, {0xFF, 0xE4, 0xC4}}

    assert Color.to_rgb(hsv) == {:color_rgb, {0xFF, 0xE4, 0xC4}}
    assert Color.to_rgb(hsl) == {:color_rgb, {0xFF, 0xE4, 0xC4}}
  end

  test "to_rgba implied" do
    # from bisque
    assert Color.to_rgba(128) == {:color_rgba, {128, 128, 128, 0xFF}}
    assert Color.to_rgba({128, 200}) == {:color_rgba, {128, 128, 128, 200}}
    assert Color.to_rgba(:bisque) == {:color_rgba, {0xFF, 0xE4, 0xC4, 0xFF}}
    assert Color.to_rgba({:bisque, 200}) == {:color_rgba, {0xFF, 0xE4, 0xC4, 200}}
    assert Color.to_rgba({0xFF, 0xE4, 0xC4}) == {:color_rgba, {0xFF, 0xE4, 0xC4, 0xFF}}
    assert Color.to_rgba({0xFF, 0xE4, 0xC4, 200}) == {:color_rgba, {0xFF, 0xE4, 0xC4, 200}}
  end

  test "to_rgba explicit" do
    # from bisque
    hsv = Color.to_hsv(:bisque)
    hsl = Color.to_hsl(:bisque)
    assert Color.to_rgba({:color_g, 128}) == {:color_rgba, {128, 128, 128, 0xFF}}
    assert Color.to_rgba({:color_ga, {128, 200}}) == {:color_rgba, {128, 128, 128, 200}}

    assert Color.to_rgba({:color_rgb, {0xFF, 0xE4, 0xC4}}) ==
             {:color_rgba, {0xFF, 0xE4, 0xC4, 0xFF}}

    assert Color.to_rgba({:color_rgba, {0xFF, 0xE4, 0xC4, 200}}) ==
             {:color_rgba, {0xFF, 0xE4, 0xC4, 200}}

    assert Color.to_rgba(hsv) == {:color_rgba, {0xFF, 0xE4, 0xC4, 0xFF}}
    assert Color.to_rgba(hsl) == {:color_rgba, {0xFF, 0xE4, 0xC4, 0xFF}}
  end

  test "to_hsv implied - using to_rgb as truth" do
    # from bisque
    rgb = Color.to_rgb(:bisque)

    assert Color.to_hsv(0) == {:color_hsv, {0, 0, 0}}

    {:color_hsv, {+0.0, +0.0, v}} = Color.to_hsv(128)
    assert v > 50 && v < 51

    {:color_hsv, {+0.0, +0.0, v}} = Color.to_hsv({128, 200})
    assert v > 50 && v < 51

    assert Color.to_hsv(:bisque) |> Color.to_rgb() == rgb
    assert Color.to_hsv({:bisque, 200}) |> Color.to_rgb() == rgb
    assert Color.to_hsv({0xFF, 0xE4, 0xC4}) |> Color.to_rgb() == rgb
    assert Color.to_hsv({0xFF, 0xE4, 0xC4, 200}) |> Color.to_rgb() == rgb
  end

  test "to_hsv explicit - using to_rgb as truth" do
    # from bisque
    hsl = Color.to_hsl(:bisque)
    rgb = Color.to_rgb(:bisque)

    {:color_hsv, {+0.0, +0.0, v}} = Color.to_hsv({:color_g, 128})
    assert v > 50 && v < 51

    {:color_hsv, {+0.0, +0.0, v}} = Color.to_hsv({:color_ga, {128, 200}})
    assert v > 50 && v < 51

    assert Color.to_hsv(rgb) |> Color.to_rgb() == rgb
    assert Color.to_hsv(hsl) |> Color.to_rgb() == rgb
    assert Color.to_hsv({:color_rgba, {0xFF, 0xE4, 0xC4, 200}}) |> Color.to_rgb() == rgb
    assert Color.to_hsv({:color_hsv, {1.1, 1.2, 1.3}}) == {:color_hsv, {1.1, 1.2, 1.3}}
  end

  test "to_hsl implied - using to_rgb as truth" do
    # from bisque
    rgb = Color.to_rgb(:bisque)

    assert Color.to_hsl(0) == {:color_hsl, {0, 0, 0}}

    {:color_hsl, {+0.0, +0.0, l}} = Color.to_hsl(128)
    assert l > 50 && l < 51

    {:color_hsl, {+0.0, +0.0, l}} = Color.to_hsl({128, 200})
    assert l > 50 && l < 51

    assert Color.to_hsl(:bisque) |> Color.to_rgb() == rgb
    assert Color.to_hsl({:bisque, 200}) |> Color.to_rgb() == rgb
    assert Color.to_hsl({0xFF, 0xE4, 0xC4}) |> Color.to_rgb() == rgb
    assert Color.to_hsl({0xFF, 0xE4, 0xC4, 200}) |> Color.to_rgb() == rgb
  end

  test "to_hsl explicit - using to_rgb as truth" do
    # from bisque
    rgb = Color.to_rgb(:bisque)

    {:color_hsl, {+0.0, +0.0, l}} = Color.to_hsl({:color_g, 128})
    assert l > 50 && l < 51

    {:color_hsl, {+0.0, +0.0, l}} = Color.to_hsl({:color_ga, {128, 200}})
    assert l > 50 && l < 51

    assert Color.to_hsl({:color_rgb, {0xFF, 0xE4, 0xC4}}) |> Color.to_rgb() == rgb
    assert Color.to_hsl({:color_rgba, {0xFF, 0xE4, 0xC4, 200}}) |> Color.to_rgb() == rgb
    assert Color.to_hsl({:color_hsl, {1.1, 1.2, 1.3}}) == {:color_hsl, {1.1, 1.2, 1.3}}
  end

  test "white hsl to hsv to rgb" do
    assert Color.to_hsv(:white)
           |> Color.to_hsl()
           |> Color.to_rgb() == {:color_rgb, {255, 255, 255}}
  end

  test "named looks right" do
    Color.named()
    |> Enum.each(fn {n, {r, g, b}} ->
      assert is_atom(n)
      assert is_integer(r) && r >= 0 && r <= 255
      assert is_integer(g) && g >= 0 && g <= 255
      assert is_integer(b) && b >= 0 && b <= 255
    end)
  end

  test ":alice_blue", do: assert(Color.to_rgb(:alice_blue) == {:color_rgb, {0xF0, 0xF8, 0xFF}})

  test ":antique_white",
    do: assert(Color.to_rgb(:antique_white) == {:color_rgb, {0xFA, 0xEB, 0xD7}})

  test ":aqua", do: assert(Color.to_rgb(:aqua) == {:color_rgb, {0x00, 0xFF, 0xFF}})
  test ":aquamarine", do: assert(Color.to_rgb(:aquamarine) == {:color_rgb, {0x7F, 0xFF, 0xD4}})
  test ":azure", do: assert(Color.to_rgb(:azure) == {:color_rgb, {0xF0, 0xFF, 0xFF}})

  test ":beige", do: assert(Color.to_rgb(:beige) == {:color_rgb, {0xF5, 0xF5, 0xDC}})
  test ":bisque", do: assert(Color.to_rgb(:bisque) == {:color_rgb, {0xFF, 0xE4, 0xC4}})
  test ":black", do: assert(Color.to_rgb(:black) == {:color_rgb, {0x00, 0x00, 0x00}})

  test ":blanched_almond",
    do: assert(Color.to_rgb(:blanched_almond) == {:color_rgb, {0xFF, 0xEB, 0xCD}})

  test ":blue", do: assert(Color.to_rgb(:blue) == {:color_rgb, {0x00, 0x00, 0xFF}})
  test ":blue_violet", do: assert(Color.to_rgb(:blue_violet) == {:color_rgb, {0x8A, 0x2B, 0xE2}})
  test ":brown", do: assert(Color.to_rgb(:brown) == {:color_rgb, {0xA5, 0x2A, 0x2A}})
  test ":burly_wood", do: assert(Color.to_rgb(:burly_wood) == {:color_rgb, {0xDE, 0xB8, 0x87}})

  test ":cadet_blue", do: assert(Color.to_rgb(:cadet_blue) == {:color_rgb, {0x5F, 0x9E, 0xA0}})
  test ":chartreuse", do: assert(Color.to_rgb(:chartreuse) == {:color_rgb, {0x7F, 0xFF, 0x00}})
  test ":chocolate", do: assert(Color.to_rgb(:chocolate) == {:color_rgb, {0xD2, 0x69, 0x1E}})
  test ":coral", do: assert(Color.to_rgb(:coral) == {:color_rgb, {0xFF, 0x7F, 0x50}})

  test ":cornflower_blue",
    do: assert(Color.to_rgb(:cornflower_blue) == {:color_rgb, {0x64, 0x95, 0xED}})

  test ":cornsilk", do: assert(Color.to_rgb(:cornsilk) == {:color_rgb, {0xFF, 0xF8, 0xDC}})
  test ":crimson", do: assert(Color.to_rgb(:crimson) == {:color_rgb, {0xDC, 0x14, 0x3C}})
  test ":cyan", do: assert(Color.to_rgb(:cyan) == {:color_rgb, {0x00, 0xFF, 0xFF}})

  test ":dark_blue", do: assert(Color.to_rgb(:dark_blue) == {:color_rgb, {0x00, 0x00, 0x8B}})
  test ":dark_cyan", do: assert(Color.to_rgb(:dark_cyan) == {:color_rgb, {0x00, 0x8B, 0x8B}})

  test ":dark_golden_rod",
    do: assert(Color.to_rgb(:dark_golden_rod) == {:color_rgb, {0xB8, 0x86, 0x0B}})

  test ":dark_gray", do: assert(Color.to_rgb(:dark_gray) == {:color_rgb, {0xA9, 0xA9, 0xA9}})
  test ":dark_grey", do: assert(Color.to_rgb(:dark_grey) == {:color_rgb, {0xA9, 0xA9, 0xA9}})
  test ":dark_green", do: assert(Color.to_rgb(:dark_green) == {:color_rgb, {0x00, 0x64, 0x00}})
  test ":dark_khaki", do: assert(Color.to_rgb(:dark_khaki) == {:color_rgb, {0xBD, 0xB7, 0x6B}})

  test ":dark_magenta",
    do: assert(Color.to_rgb(:dark_magenta) == {:color_rgb, {0x8B, 0x00, 0x8B}})

  test ":dark_olive_green",
    do: assert(Color.to_rgb(:dark_olive_green) == {:color_rgb, {0x55, 0x6B, 0x2F}})

  test ":dark_orange", do: assert(Color.to_rgb(:dark_orange) == {:color_rgb, {0xFF, 0x8C, 0x00}})
  test ":dark_orchid", do: assert(Color.to_rgb(:dark_orchid) == {:color_rgb, {0x99, 0x32, 0xCC}})
  test ":dark_red", do: assert(Color.to_rgb(:dark_red) == {:color_rgb, {0x8B, 0x00, 0x00}})
  test ":dark_salmon", do: assert(Color.to_rgb(:dark_salmon) == {:color_rgb, {0xE9, 0x96, 0x7A}})

  test ":dark_sea_green",
    do: assert(Color.to_rgb(:dark_sea_green) == {:color_rgb, {0x8F, 0xBC, 0x8F}})

  test ":dark_slate_blue",
    do: assert(Color.to_rgb(:dark_slate_blue) == {:color_rgb, {0x48, 0x3D, 0x8B}})

  test ":dark_slate_gray",
    do: assert(Color.to_rgb(:dark_slate_gray) == {:color_rgb, {0x2F, 0x4F, 0x4F}})

  test ":dark_slate_grey",
    do: assert(Color.to_rgb(:dark_slate_grey) == {:color_rgb, {0x2F, 0x4F, 0x4F}})

  test ":dark_turquoise",
    do: assert(Color.to_rgb(:dark_turquoise) == {:color_rgb, {0x00, 0xCE, 0xD1}})

  test ":dark_violet", do: assert(Color.to_rgb(:dark_violet) == {:color_rgb, {0x94, 0x00, 0xD3}})
  test ":deep_pink", do: assert(Color.to_rgb(:deep_pink) == {:color_rgb, {0xFF, 0x14, 0x93}})

  test ":deep_sky_blue",
    do: assert(Color.to_rgb(:deep_sky_blue) == {:color_rgb, {0x00, 0xBF, 0xFF}})

  test ":dim_gray", do: assert(Color.to_rgb(:dim_gray) == {:color_rgb, {0x69, 0x69, 0x69}})
  test ":dim_grey", do: assert(Color.to_rgb(:dim_grey) == {:color_rgb, {0x69, 0x69, 0x69}})
  test ":dodger_blue", do: assert(Color.to_rgb(:dodger_blue) == {:color_rgb, {0x1E, 0x90, 0xFF}})

  test ":fire_brick", do: assert(Color.to_rgb(:fire_brick) == {:color_rgb, {0xB2, 0x22, 0x22}})

  test ":floral_white",
    do: assert(Color.to_rgb(:floral_white) == {:color_rgb, {0xFF, 0xFA, 0xF0}})

  test ":forest_green",
    do: assert(Color.to_rgb(:forest_green) == {:color_rgb, {0x22, 0x8B, 0x22}})

  test ":fuchsia", do: assert(Color.to_rgb(:fuchsia) == {:color_rgb, {0xFF, 0x00, 0xFF}})

  test ":gainsboro", do: assert(Color.to_rgb(:gainsboro) == {:color_rgb, {0xDC, 0xDC, 0xDC}})
  test ":ghost_white", do: assert(Color.to_rgb(:ghost_white) == {:color_rgb, {0xF8, 0xF8, 0xFF}})
  test ":gold", do: assert(Color.to_rgb(:gold) == {:color_rgb, {0xFF, 0xD7, 0x00}})
  test ":golden_rod", do: assert(Color.to_rgb(:golden_rod) == {:color_rgb, {0xDA, 0xA5, 0x20}})
  test ":gray", do: assert(Color.to_rgb(:gray) == {:color_rgb, {0x80, 0x80, 0x80}})
  test ":grey", do: assert(Color.to_rgb(:grey) == {:color_rgb, {0x80, 0x80, 0x80}})
  test ":green", do: assert(Color.to_rgb(:green) == {:color_rgb, {0x00, 0x80, 0x00}})

  test ":green_yellow",
    do: assert(Color.to_rgb(:green_yellow) == {:color_rgb, {0xAD, 0xFF, 0x2F}})

  test ":honey_dew", do: assert(Color.to_rgb(:honey_dew) == {:color_rgb, {0xF0, 0xFF, 0xF0}})
  test ":hot_pink", do: assert(Color.to_rgb(:hot_pink) == {:color_rgb, {0xFF, 0x69, 0xB4}})

  test ":indian_red", do: assert(Color.to_rgb(:indian_red) == {:color_rgb, {0xCD, 0x5C, 0x5C}})
  test ":indigo", do: assert(Color.to_rgb(:indigo) == {:color_rgb, {0x4B, 0x00, 0x82}})
  test ":ivory", do: assert(Color.to_rgb(:ivory) == {:color_rgb, {0xFF, 0xFF, 0xF0}})

  test ":khaki", do: assert(Color.to_rgb(:khaki) == {:color_rgb, {0xF0, 0xE6, 0x8C}})

  test ":lavender", do: assert(Color.to_rgb(:lavender) == {:color_rgb, {0xE6, 0xE6, 0xFA}})

  test ":lavender_blush",
    do: assert(Color.to_rgb(:lavender_blush) == {:color_rgb, {0xFF, 0xF0, 0xF5}})

  test ":lawn_green", do: assert(Color.to_rgb(:lawn_green) == {:color_rgb, {0x7C, 0xFC, 0x00}})

  test ":lemon_chiffon",
    do: assert(Color.to_rgb(:lemon_chiffon) == {:color_rgb, {0xFF, 0xFA, 0xCD}})

  test ":light_blue", do: assert(Color.to_rgb(:light_blue) == {:color_rgb, {0xAD, 0xD8, 0xE6}})
  test ":light_coral", do: assert(Color.to_rgb(:light_coral) == {:color_rgb, {0xF0, 0x80, 0x80}})
  test ":light_cyan", do: assert(Color.to_rgb(:light_cyan) == {:color_rgb, {0xE0, 0xFF, 0xFF}})

  test ":light_golden_rod",
    do: assert(Color.to_rgb(:light_golden_rod) == {:color_rgb, {0xFA, 0xFA, 0xD2}})

  test ":light_golden_rod_yellow",
    do: assert(Color.to_rgb(:light_golden_rod_yellow) == {:color_rgb, {0xFA, 0xFA, 0xD2}})

  test ":light_gray", do: assert(Color.to_rgb(:light_gray) == {:color_rgb, {0xD3, 0xD3, 0xD3}})
  test ":light_grey", do: assert(Color.to_rgb(:light_grey) == {:color_rgb, {0xD3, 0xD3, 0xD3}})
  test ":light_green", do: assert(Color.to_rgb(:light_green) == {:color_rgb, {0x90, 0xEE, 0x90}})
  test ":light_pink", do: assert(Color.to_rgb(:light_pink) == {:color_rgb, {0xFF, 0xB6, 0xC1}})

  test ":light_salmon",
    do: assert(Color.to_rgb(:light_salmon) == {:color_rgb, {0xFF, 0xA0, 0x7A}})

  test ":light_sea_green",
    do: assert(Color.to_rgb(:light_sea_green) == {:color_rgb, {0x20, 0xB2, 0xAA}})

  test ":light_sky_blue",
    do: assert(Color.to_rgb(:light_sky_blue) == {:color_rgb, {0x87, 0xCE, 0xFA}})

  test ":light_slate_gray",
    do: assert(Color.to_rgb(:light_slate_gray) == {:color_rgb, {0x77, 0x88, 0x99}})

  test ":light_steel_blue",
    do: assert(Color.to_rgb(:light_steel_blue) == {:color_rgb, {0xB0, 0xC4, 0xDE}})

  test ":light_yellow",
    do: assert(Color.to_rgb(:light_yellow) == {:color_rgb, {0xFF, 0xFF, 0xE0}})

  test ":lime", do: assert(Color.to_rgb(:lime) == {:color_rgb, {0x00, 0xFF, 0x00}})
  test ":lime_green", do: assert(Color.to_rgb(:lime_green) == {:color_rgb, {0x32, 0xCD, 0x32}})
  test ":linen", do: assert(Color.to_rgb(:linen) == {:color_rgb, {0xFA, 0xF0, 0xE6}})

  test ":magenta", do: assert(Color.to_rgb(:magenta) == {:color_rgb, {0xFF, 0x00, 0xFF}})
  test ":maroon", do: assert(Color.to_rgb(:maroon) == {:color_rgb, {0x80, 0x00, 0x00}})

  test ":medium_aqua_marine",
    do: assert(Color.to_rgb(:medium_aqua_marine) == {:color_rgb, {0x66, 0xCD, 0xAA}})

  test ":medium_blue", do: assert(Color.to_rgb(:medium_blue) == {:color_rgb, {0x00, 0x00, 0xCD}})

  test ":medium_orchid",
    do: assert(Color.to_rgb(:medium_orchid) == {:color_rgb, {0xBA, 0x55, 0xD3}})

  test ":medium_purple",
    do: assert(Color.to_rgb(:medium_purple) == {:color_rgb, {0x93, 0x70, 0xDB}})

  test ":medium_sea_green",
    do: assert(Color.to_rgb(:medium_sea_green) == {:color_rgb, {0x3C, 0xB3, 0x71}})

  test ":medium_slate_blue",
    do: assert(Color.to_rgb(:medium_slate_blue) == {:color_rgb, {0x7B, 0x68, 0xEE}})

  test ":medium_spring_green",
    do: assert(Color.to_rgb(:medium_spring_green) == {:color_rgb, {0x00, 0xFA, 0x9A}})

  test ":medium_turquoise",
    do: assert(Color.to_rgb(:medium_turquoise) == {:color_rgb, {0x48, 0xD1, 0xCC}})

  test ":medium_violet_red",
    do: assert(Color.to_rgb(:medium_violet_red) == {:color_rgb, {0xC7, 0x15, 0x85}})

  test ":midnight_blue",
    do: assert(Color.to_rgb(:midnight_blue) == {:color_rgb, {0x19, 0x19, 0x70}})

  test ":mint_cream", do: assert(Color.to_rgb(:mint_cream) == {:color_rgb, {0xF5, 0xFF, 0xFA}})
  test ":misty_rose", do: assert(Color.to_rgb(:misty_rose) == {:color_rgb, {0xFF, 0xE4, 0xE1}})
  test ":moccasin", do: assert(Color.to_rgb(:moccasin) == {:color_rgb, {0xFF, 0xE4, 0xB5}})

  test ":navajo_white",
    do: assert(Color.to_rgb(:navajo_white) == {:color_rgb, {0xFF, 0xDE, 0xAD}})

  test ":navy", do: assert(Color.to_rgb(:navy) == {:color_rgb, {0x00, 0x00, 0x80}})

  test ":old_lace", do: assert(Color.to_rgb(:old_lace) == {:color_rgb, {0xFD, 0xF5, 0xE6}})
  test ":olive", do: assert(Color.to_rgb(:olive) == {:color_rgb, {0x80, 0x80, 0x00}})
  test ":olive_drab", do: assert(Color.to_rgb(:olive_drab) == {:color_rgb, {0x6B, 0x8E, 0x23}})
  test ":orange", do: assert(Color.to_rgb(:orange) == {:color_rgb, {0xFF, 0xA5, 0x00}})
  test ":orange_red", do: assert(Color.to_rgb(:orange_red) == {:color_rgb, {0xFF, 0x45, 0x00}})
  test ":orchid", do: assert(Color.to_rgb(:orchid) == {:color_rgb, {0xDA, 0x70, 0xD6}})

  test ":pale_golden_rod",
    do: assert(Color.to_rgb(:pale_golden_rod) == {:color_rgb, {0xEE, 0xE8, 0xAA}})

  test ":pale_green", do: assert(Color.to_rgb(:pale_green) == {:color_rgb, {0x98, 0xFB, 0x98}})

  test ":pale_turquoise",
    do: assert(Color.to_rgb(:pale_turquoise) == {:color_rgb, {0xAF, 0xEE, 0xEE}})

  test ":pale_violet_red",
    do: assert(Color.to_rgb(:pale_violet_red) == {:color_rgb, {0xDB, 0x70, 0x93}})

  test ":papaya_whip", do: assert(Color.to_rgb(:papaya_whip) == {:color_rgb, {0xFF, 0xEF, 0xD5}})
  test ":peach_puff", do: assert(Color.to_rgb(:peach_puff) == {:color_rgb, {0xFF, 0xDA, 0xB9}})
  test ":peru", do: assert(Color.to_rgb(:peru) == {:color_rgb, {0xCD, 0x85, 0x3F}})
  test ":pink", do: assert(Color.to_rgb(:pink) == {:color_rgb, {0xFF, 0xC0, 0xCB}})
  test ":plum", do: assert(Color.to_rgb(:plum) == {:color_rgb, {0xDD, 0xA0, 0xDD}})
  test ":powder_blue", do: assert(Color.to_rgb(:powder_blue) == {:color_rgb, {0xB0, 0xE0, 0xE6}})
  test ":purple", do: assert(Color.to_rgb(:purple) == {:color_rgb, {0x80, 0x00, 0x80}})

  test ":rebecca_purple",
    do: assert(Color.to_rgb(:rebecca_purple) == {:color_rgb, {0x66, 0x33, 0x99}})

  test ":red", do: assert(Color.to_rgb(:red) == {:color_rgb, {0xFF, 0x00, 0x00}})
  test ":rosy_brown", do: assert(Color.to_rgb(:rosy_brown) == {:color_rgb, {0xBC, 0x8F, 0x8F}})
  test ":royal_blue", do: assert(Color.to_rgb(:royal_blue) == {:color_rgb, {0x41, 0x69, 0xE1}})

  test ":saddle_brown",
    do: assert(Color.to_rgb(:saddle_brown) == {:color_rgb, {0x8B, 0x45, 0x13}})

  test ":salmon", do: assert(Color.to_rgb(:salmon) == {:color_rgb, {0xFA, 0x80, 0x72}})
  test ":sandy_brown", do: assert(Color.to_rgb(:sandy_brown) == {:color_rgb, {0xF4, 0xA4, 0x60}})
  test ":sea_green", do: assert(Color.to_rgb(:sea_green) == {:color_rgb, {0x2E, 0x8B, 0x57}})
  test ":sea_shell", do: assert(Color.to_rgb(:sea_shell) == {:color_rgb, {0xFF, 0xF5, 0xEE}})
  test ":sienna", do: assert(Color.to_rgb(:sienna) == {:color_rgb, {0xA0, 0x52, 0x2D}})
  test ":silver", do: assert(Color.to_rgb(:silver) == {:color_rgb, {0xC0, 0xC0, 0xC0}})
  test ":sky_blue", do: assert(Color.to_rgb(:sky_blue) == {:color_rgb, {0x87, 0xCE, 0xEB}})
  test ":slate_blue", do: assert(Color.to_rgb(:slate_blue) == {:color_rgb, {0x6A, 0x5A, 0xCD}})
  test ":slate_gray", do: assert(Color.to_rgb(:slate_gray) == {:color_rgb, {0x70, 0x80, 0x90}})
  test ":slate_grey", do: assert(Color.to_rgb(:slate_grey) == {:color_rgb, {0x70, 0x80, 0x90}})
  test ":snow", do: assert(Color.to_rgb(:snow) == {:color_rgb, {0xFF, 0xFA, 0xFA}})

  test ":spring_green",
    do: assert(Color.to_rgb(:spring_green) == {:color_rgb, {0x00, 0xFF, 0x7F}})

  test ":steel_blue", do: assert(Color.to_rgb(:steel_blue) == {:color_rgb, {0x46, 0x82, 0xB4}})

  test ":tan", do: assert(Color.to_rgb(:tan) == {:color_rgb, {0xD2, 0xB4, 0x8C}})
  test ":teal", do: assert(Color.to_rgb(:teal) == {:color_rgb, {0x00, 0x80, 0x80}})
  test ":thistle", do: assert(Color.to_rgb(:thistle) == {:color_rgb, {0xD8, 0xBF, 0xD8}})
  test ":tomato", do: assert(Color.to_rgb(:tomato) == {:color_rgb, {0xFF, 0x63, 0x47}})
  test ":turquoise", do: assert(Color.to_rgb(:turquoise) == {:color_rgb, {0x40, 0xE0, 0xD0}})

  test ":violet", do: assert(Color.to_rgb(:violet) == {:color_rgb, {0xEE, 0x82, 0xEE}})

  test ":wheat", do: assert(Color.to_rgb(:wheat) == {:color_rgb, {0xF5, 0xDE, 0xB3}})
  test ":white", do: assert(Color.to_rgb(:white) == {:color_rgb, {0xFF, 0xFF, 0xFF}})
  test ":white_smoke", do: assert(Color.to_rgb(:white_smoke) == {:color_rgb, {0xF5, 0xF5, 0xF5}})

  test ":yellow", do: assert(Color.to_rgb(:yellow) == {:color_rgb, {0xFF, 0xFF, 0x00}})

  test ":yellow_green",
    do: assert(Color.to_rgb(:yellow_green) == {:color_rgb, {0x9A, 0xCD, 0x32}})

  test ":clear", do: assert(Color.to_rgba(:clear) == {:color_rgba, {0, 0, 0, 0}})
  test ":transparent", do: assert(Color.to_rgba(:transparent) == {:color_rgba, {0, 0, 0, 0}})
end
