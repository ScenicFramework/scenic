#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Color do
  use Scenic.Primitive.Style


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Style :color must be qualified color. Please see documentation.\n" <>
    "In general, the color is a tuple containing a description of 1, 2, 3, or 4 colors.\n" <>
    "The numbers of colors you specify depends on what type of primitive you are applying\n" <>
    "it to. A single color is always safe. Any single color can be specified\n" <>
    "by name, such as :red, :green, or :cornflower_blue. All standard html colors should work\n" <>
    "Specify the RGB channels in a tuple, like this: {1, 2, 3}. Channels range from 0 to 255.\n" <>
    "You can add an alpha channel like this: {:orange, 128} or {1, 2, 3, 4}.\n" <>
    "Finally, specify multiple colors in a tuple: {:red, {:khaki, 128}, {1,2,3,4}}"
  end

  #--------------------------------------------------------
  # verify that a color is correctly described

  def verify( color ) do
    try do
      normalize( color )
      true
    rescue
      _ -> false
    end
  end

  #--------------------------------------------------------
  # single color
  def normalize( color )   when is_atom(color),  do: {to_rgba( color )}
  def normalize( {color} ) when is_atom(color),  do: {to_rgba( color )}

  def normalize( {color, alpha} )  when is_atom(color) and is_integer(alpha), do: normalize( {{color, alpha}} )
  def normalize( {{color, alpha}} ), do: {to_rgba( {color, alpha} )}

  def normalize( {r,g,b} ) when is_integer(r) and is_integer(g) and is_integer(b), do: normalize( {{r,g,b}} )
  def normalize( {{r,g,b}} ), do: {to_rgba( {r,g,b} )}

  def normalize( {r,g,b,a} ) when is_integer(r) and is_integer(g) and is_integer(b) and is_integer(a), do:
    normalize( {{r,g,b,a}} )
  def normalize( {{r,g,b,a}} ), do: {to_rgba( {r,g,b,a} )}

  # multi-color
  def normalize( {c0,c1} ) do
    {
      to_rgba( c0 ),
      to_rgba( c1 ),
    }
  end

  def normalize( {c0,c1,c2} ) do
    {
      to_rgba( c0 ),
      to_rgba( c1 ),
      to_rgba( c2 ),
    }
  end

  def normalize( {c0,c1,c2,c3} ) do
    {
      to_rgba( c0 ),
      to_rgba( c1 ),
      to_rgba( c2 ),
      to_rgba( c3 ),
    }
  end


  #--------------------------------------------------------

  def serialize( color, order \\ :native )
  def serialize( color, _ ) do
    normalize( color )
    |> do_serialize()
  end

  defp do_serialize( {c0} ) do
    <<
      1 :: size(8),
      do_serialize_one( c0 ) :: binary
    >>
  end

  defp do_serialize( {c0, c1} ) do
    <<
      2 :: size(8),
      do_serialize_one( c0 ) :: binary,
      do_serialize_one( c1 ) :: binary
    >>
  end

  defp do_serialize( {c0, c1, c2} ) do
    <<
      3 :: size(8),
      do_serialize_one( c0 ) :: binary,
      do_serialize_one( c1 ) :: binary,
      do_serialize_one( c2 ) :: binary
    >>
  end

  defp do_serialize( {c0, c1, c2, c3} ) do
    <<
      4 :: size(8),
      do_serialize_one( c0 ) :: binary,
      do_serialize_one( c1 ) :: binary,
      do_serialize_one( c2 ) :: binary,
      do_serialize_one( c3 ) :: binary
    >>
  end

  defp do_serialize_one( {r,g,b,a} ) do
    <<
      r ::  unsigned-integer-size(8),
      g ::  unsigned-integer-size(8),
      b ::  unsigned-integer-size(8),
      a ::  unsigned-integer-size(8)
    >>
  end

  # anything else fails


  #--------------------------------------------------------
  # note: deserialize only works on a single color at a time
  # the caller needs to call repeatedly for a multi-color

  def deserialize( binary_data, order \\ :native )
  def deserialize( <<
      1 :: size(8),
      r0 :: size(8), g0 :: size(8), b0 :: size(8), a0 :: size(8),
      bin :: binary
    >>, _ ) do
    {:ok, {{r0,g0,b0,a0}}, bin}
  end
  def deserialize( <<
      2 :: size(8),
      r0 :: size(8), g0 :: size(8), b0 :: size(8), a0 :: size(8),
      r1 :: size(8), g1 :: size(8), b1 :: size(8), a1 :: size(8),
      bin :: binary
    >>, _ ) do
    {:ok, {{r0,g0,b0,a0}, {r1,g1,b1,a1}}, bin}
  end
  def deserialize( <<
      3 :: size(8),
      r0 :: size(8), g0 :: size(8), b0 :: size(8), a0 :: size(8),
      r1 :: size(8), g1 :: size(8), b1 :: size(8), a1 :: size(8),
      r2 :: size(8), g2 :: size(8), b2 :: size(8), a2 :: size(8),
      bin :: binary
    >>, _ ) do
    {:ok, {{r0,g0,b0,a0}, {r1,g1,b1,a1}, {r2,g2,b2,a2}}, bin}
  end
  def deserialize( <<
      4 :: size(8),
      r0 :: size(8), g0 :: size(8), b0 :: size(8), a0 :: size(8),
      r1 :: size(8), g1 :: size(8), b1 :: size(8), a1 :: size(8),
      r2 :: size(8), g2 :: size(8), b2 :: size(8), a2 :: size(8),
      r3 :: size(8), g3 :: size(8), b3 :: size(8), a3 :: size(8),
      bin :: binary
    >>, _ ) do
    {:ok, {{r0,g0,b0,a0}, {r1,g1,b1,a1}, {r2,g2,b2,a2}, {r3,g3,b3,a3}}, bin}
  end

  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }





  #============================================================================
  #https://www.w3schools.com/colors/colors_names.asp
  def to_rgba( {r,g,b} ),                   do: {r,g,b,0xFF}
  def to_rgba( {r,g,b,a} ) when
      is_integer(r) and (r >= 0) and (r <= 255) and
      is_integer(g) and (g >= 0) and (g <= 255) and
      is_integer(b) and (b >= 0) and (b <= 255) and
      is_integer(a) and (a >= 0) and (a <= 255) do
    {r,g,b,a}
  end

  def to_rgba( <<r::size(8), g::size(8), b::size(8), a::size(8)>> ), do: {r,g,b,a}
  def to_rgba( named_color ) when is_atom(named_color) do
#    {r,g,b} = name_to_rgb(named_color)
#    {r, g, b, 0xFF}
    name_to_rgb(named_color)
    |> to_rgba()
  end
  def to_rgba( {named_color, alpha} ) when is_atom(named_color) and
        is_integer(alpha) and (alpha >= 0) and (alpha <= 255) do
    {r,g,b} = name_to_rgb(named_color)
    {r, g, b, alpha}
  end


  def name_to_rgb(:transparent),             do: { 0x80, 0x80, 0x80, 0x00 }

  def name_to_rgb(:alice_blue),              do: { 0xF0, 0xF8, 0xFF }
  def name_to_rgb(:antique_white),           do: { 0xFA, 0xEB, 0xD7 }
  def name_to_rgb(:aqua),                    do: { 0x00, 0xFF, 0xFF }
  def name_to_rgb(:aquamarine),              do: { 0x7F, 0xFF, 0xD4 }
  def name_to_rgb(:azure),                   do: { 0xF0, 0xFF, 0xFF }
  def name_to_rgb(:beige),                   do: { 0xF5, 0xF5, 0xDC }
  def name_to_rgb(:bisque),                  do: { 0xFF, 0xE4, 0xC4 }
  def name_to_rgb(:black),                   do: { 0x00, 0x00, 0x00 }
  def name_to_rgb(:blanched_almond),         do: { 0xFF, 0xEB, 0xCD }
  def name_to_rgb(:blue),                    do: { 0x00, 0x00, 0xFF }
  def name_to_rgb(:blue_violet),             do: { 0x8A, 0x2B, 0xE2 }
  def name_to_rgb(:brown),                   do: { 0xA5, 0x2A, 0x2A }
  def name_to_rgb(:burly_wood),              do: { 0xDE, 0xB8, 0x87 }
  def name_to_rgb(:cadet_blue),              do: { 0x5F, 0x9E, 0xA0 }
  def name_to_rgb(:chartreuse),              do: { 0x7F, 0xFF, 0x00 }
  def name_to_rgb(:chocolate),               do: { 0xD2, 0x69, 0x1E }
  def name_to_rgb(:coral),                   do: { 0xFF, 0x7F, 0x50 }
  def name_to_rgb(:cornflower_blue),         do: { 0x64, 0x95, 0xED }
  def name_to_rgb(:cornsilk),                do: { 0xFF, 0xF8, 0xDC }
  def name_to_rgb(:crimson),                 do: { 0xDC, 0x14, 0x3C }
  def name_to_rgb(:cyan),                    do: { 0x00, 0xFF, 0xFF }
  def name_to_rgb(:dark_blue),               do: { 0x00, 0x00, 0x8B }
  def name_to_rgb(:dark_cyan),               do: { 0x00, 0x8B, 0x8B }
  def name_to_rgb(:dark_golden_rod),         do: { 0xB8, 0x86, 0x0B }
  def name_to_rgb(:dark_gray),               do: { 0xA9, 0xA9, 0xA9 }
  def name_to_rgb(:dark_grey),               do: { 0xA9, 0xA9, 0xA9 }
  def name_to_rgb(:dark_green),              do: { 0x00, 0x64, 0x00 }
  def name_to_rgb(:dark_khaki),              do: { 0xBD, 0xB7, 0x6B }
  def name_to_rgb(:dark_magenta),            do: { 0x8B, 0x00, 0x8B }
  def name_to_rgb(:dark_olive_green),        do: { 0x55, 0x6B, 0x2F }
  def name_to_rgb(:dark_orange),             do: { 0xFF, 0x8C, 0x00 }
  def name_to_rgb(:dark_orchid),             do: { 0x99, 0x32, 0xCC }
  def name_to_rgb(:dark_red),                do: { 0x8B, 0x00, 0x00 }
  def name_to_rgb(:dark_salmon),             do: { 0xE9, 0x96, 0x7A }
  def name_to_rgb(:dark_sea_green),          do: { 0x8F, 0xBC, 0x8F }
  def name_to_rgb(:dark_slate_blue),         do: { 0x48, 0x3D, 0x8B }
  def name_to_rgb(:dark_slate_gray),         do: { 0x2F, 0x4F, 0x4F }
  def name_to_rgb(:dark_slate_grey),         do: { 0x2F, 0x4F, 0x4F }
  def name_to_rgb(:dark_turquoise),          do: { 0x00, 0xCE, 0xD1 }
  def name_to_rgb(:dark_violet),             do: { 0x94, 0x00, 0xD3 }
  def name_to_rgb(:deep_pink),               do: { 0xFF, 0x14, 0x93 }
  def name_to_rgb(:deep_sky_blue),           do: { 0x00, 0xBF, 0xFF }
  def name_to_rgb(:dim_gray),                do: { 0x69, 0x69, 0x69 }
  def name_to_rgb(:dim_grey),                do: { 0x69, 0x69, 0x69 }
  def name_to_rgb(:dodger_blue),             do: { 0x1E, 0x90, 0xFF }
  def name_to_rgb(:fire_brick),              do: { 0xB2, 0x22, 0x22 }
  def name_to_rgb(:floral_white),            do: { 0xFF, 0xFA, 0xF0 }
  def name_to_rgb(:forest_green),            do: { 0x22, 0x8B, 0x22 }
  def name_to_rgb(:fuchsia),                 do: { 0xFF, 0x00, 0xFF }
  def name_to_rgb(:gainsboro),               do: { 0xDC, 0xDC, 0xDC }
  def name_to_rgb(:ghost_white),             do: { 0xF8, 0xF8, 0xFF }
  def name_to_rgb(:gold),                    do: { 0xFF, 0xD7, 0x00 }
  def name_to_rgb(:golden_rod),              do: { 0xDA, 0xA5, 0x20 }
  def name_to_rgb(:gray),                    do: { 0x80, 0x80, 0x80 }
  def name_to_rgb(:grey),                    do: { 0x80, 0x80, 0x80 }
  def name_to_rgb(:green),                   do: { 0x00, 0x80, 0x00 }
  def name_to_rgb(:green_yellow),            do: { 0xAD, 0xFF, 0x2F }
  def name_to_rgb(:honey_dew),               do: { 0xF0, 0xFF, 0xF0 }
  def name_to_rgb(:hot_pink),                do: { 0xFF, 0x69, 0xB4 }
  def name_to_rgb(:indian_red),              do: { 0xCD, 0x5C, 0x5C }
  def name_to_rgb(:indigo),                  do: { 0x4B, 0x00, 0x82 }
  def name_to_rgb(:ivory),                   do: { 0xFF, 0xFF, 0xF0 }
  def name_to_rgb(:khaki),                   do: { 0xF0, 0xE6, 0x8C }
  def name_to_rgb(:lavender),                do: { 0xE6, 0xE6, 0xFA }
  def name_to_rgb(:lavender_blush),          do: { 0xFF, 0xF0, 0xF5 }
  def name_to_rgb(:lawn_green),              do: { 0x7C, 0xFC, 0x00 }
  def name_to_rgb(:lemon_chiffon),           do: { 0xFF, 0xFA, 0xCD }
  def name_to_rgb(:light_blue),              do: { 0xAD, 0xD8, 0xE6 }
  def name_to_rgb(:light_coral),             do: { 0xF0, 0x80, 0x80 }
  def name_to_rgb(:light_cyan),              do: { 0xE0, 0xFF, 0xFF }
  def name_to_rgb(:light_golden_rod_yellow), do: { 0xFA, 0xFA, 0xD2 }
  def name_to_rgb(:light_gray),              do: { 0xD3, 0xD3, 0xD3 }
  def name_to_rgb(:light_grey),              do: { 0xD3, 0xD3, 0xD3 }
  def name_to_rgb(:light_green),             do: { 0x90, 0xEE, 0x90 }
  def name_to_rgb(:light_pink),              do: { 0xFF, 0xB6, 0xC1 }
  def name_to_rgb(:light_salmon),            do: { 0xFF, 0xA0, 0x7A }
  def name_to_rgb(:light_sea_green),         do: { 0x20, 0xB2, 0xAA }
  def name_to_rgb(:light_sky_blue),          do: { 0x87, 0xCE, 0xFA }
  def name_to_rgb(:light_slate_gray),        do: { 0x77, 0x88, 0x99 }
  def name_to_rgb(:light_slate_grey),        do: { 0x77, 0x88, 0x99 }
  def name_to_rgb(:light_steel_blue),        do: { 0xB0, 0xC4, 0xDE }
  def name_to_rgb(:light_yellow),            do: { 0xFF, 0xFF, 0xE0 }
  def name_to_rgb(:lime),                    do: { 0x00, 0xFF, 0x00 }
  def name_to_rgb(:lime_green),              do: { 0x32, 0xCD, 0x32 }
  def name_to_rgb(:linen),                   do: { 0xFA, 0xF0, 0xE6 }
  def name_to_rgb(:magenta),                 do: { 0xFF, 0x00, 0xFF }
  def name_to_rgb(:maroon),                  do: { 0x80, 0x00, 0x00 }
  def name_to_rgb(:medium_aqua_marine),      do: { 0x66, 0xCD, 0xAA }
  def name_to_rgb(:medium_blue),             do: { 0x00, 0x00, 0xCD }
  def name_to_rgb(:medium_orchid),           do: { 0xBA, 0x55, 0xD3 }
  def name_to_rgb(:medium_purple),           do: { 0x93, 0x70, 0xDB }
  def name_to_rgb(:medium_sea_green),        do: { 0x3C, 0xB3, 0x71 }
  def name_to_rgb(:medium_slate_blue),       do: { 0x7B, 0x68, 0xEE }
  def name_to_rgb(:medium_spring_green),     do: { 0x00, 0xFA, 0x9A }
  def name_to_rgb(:medium_turquoise),        do: { 0x48, 0xD1, 0xCC }
  def name_to_rgb(:medium_violet_red),       do: { 0xC7, 0x15, 0x85 }
  def name_to_rgb(:midnight_blue),           do: { 0x19, 0x19, 0x70 }
  def name_to_rgb(:mint_cream),              do: { 0xF5, 0xFF, 0xFA }
  def name_to_rgb(:misty_rose),              do: { 0xFF, 0xE4, 0xE1 }
  def name_to_rgb(:moccasin),                do: { 0xFF, 0xE4, 0xB5 }
  def name_to_rgb(:navajo_white),            do: { 0xFF, 0xDE, 0xAD }
  def name_to_rgb(:navy),                    do: { 0x00, 0x00, 0x80 }
  def name_to_rgb(:old_lace),                do: { 0xFD, 0xF5, 0xE6 }
  def name_to_rgb(:olive),                   do: { 0x80, 0x80, 0x00 }
  def name_to_rgb(:olive_drab),              do: { 0x6B, 0x8E, 0x23 }
  def name_to_rgb(:orange),                  do: { 0xFF, 0xA5, 0x00 }
  def name_to_rgb(:orange_red),              do: { 0xFF, 0x45, 0x00 }
  def name_to_rgb(:orchid),                  do: { 0xDA, 0x70, 0xD6 }
  def name_to_rgb(:pale_golden_rod),         do: { 0xEE, 0xE8, 0xAA }
  def name_to_rgb(:pale_green),              do: { 0x98, 0xFB, 0x98 }
  def name_to_rgb(:pale_turquoise),          do: { 0xAF, 0xEE, 0xEE }
  def name_to_rgb(:pale_violet_red),         do: { 0xDB, 0x70, 0x93 }
  def name_to_rgb(:papaya_whip),             do: { 0xFF, 0xEF, 0xD5 }
  def name_to_rgb(:peach_puff),              do: { 0xFF, 0xDA, 0xB9 }
  def name_to_rgb(:peru),                    do: { 0xCD, 0x85, 0x3F }
  def name_to_rgb(:pink),                    do: { 0xFF, 0xC0, 0xCB }
  def name_to_rgb(:plum),                    do: { 0xDD, 0xA0, 0xDD }
  def name_to_rgb(:powder_blue),             do: { 0xB0, 0xE0, 0xE6 }
  def name_to_rgb(:purple),                  do: { 0x80, 0x00, 0x80 }
  def name_to_rgb(:rebecca_purple),          do: { 0x66, 0x33, 0x99 }
  def name_to_rgb(:red),                     do: { 0xFF, 0x00, 0x00 }
  def name_to_rgb(:rosy_brown),              do: { 0xBC, 0x8F, 0x8F }
  def name_to_rgb(:royal_blue),              do: { 0x41, 0x69, 0xE1 }
  def name_to_rgb(:saddle_brown),            do: { 0x8B, 0x45, 0x13 }
  def name_to_rgb(:salmon),                  do: { 0xFA, 0x80, 0x72 }
  def name_to_rgb(:sandy_brown),             do: { 0xF4, 0xA4, 0x60 }
  def name_to_rgb(:sea_green),               do: { 0x2E, 0x8B, 0x57 }
  def name_to_rgb(:sea_shell),               do: { 0xFF, 0xF5, 0xEE }
  def name_to_rgb(:sienna),                  do: { 0xA0, 0x52, 0x2D }
  def name_to_rgb(:silver),                  do: { 0xC0, 0xC0, 0xC0 }
  def name_to_rgb(:sky_blue),                do: { 0x87, 0xCE, 0xEB }
  def name_to_rgb(:slate_blue),              do: { 0x6A, 0x5A, 0xCD }
  def name_to_rgb(:slate_gray),              do: { 0x70, 0x80, 0x90 }
  def name_to_rgb(:slate_grey),              do: { 0x70, 0x80, 0x90 }
  def name_to_rgb(:snow),                    do: { 0xFF, 0xFA, 0xFA }
  def name_to_rgb(:spring_green),            do: { 0x00, 0xFF, 0x7F }
  def name_to_rgb(:steel_blue),              do: { 0x46, 0x82, 0xB4 }
  def name_to_rgb(:tan),                     do: { 0xD2, 0xB4, 0x8C }
  def name_to_rgb(:teal),                    do: { 0x00, 0x80, 0x80 }
  def name_to_rgb(:thistle),                 do: { 0xD8, 0xBF, 0xD8 }
  def name_to_rgb(:tomato),                  do: { 0xFF, 0x63, 0x47 }
  def name_to_rgb(:turquoise),               do: { 0x40, 0xE0, 0xD0 }
  def name_to_rgb(:violet),                  do: { 0xEE, 0x82, 0xEE }
  def name_to_rgb(:wheat),                   do: { 0xF5, 0xDE, 0xB3 }
  def name_to_rgb(:white),                   do: { 0xFF, 0xFF, 0xFF }
  def name_to_rgb(:white_smoke),             do: { 0xF5, 0xF5, 0xF5 }
  def name_to_rgb(:yellow),                  do: { 0xFF, 0xFF, 0x00 }
  def name_to_rgb(:yellow_green),            do: { 0x9A, 0xCD, 0x32 }



end