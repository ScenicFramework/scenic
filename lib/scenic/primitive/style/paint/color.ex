#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.Color do
  @moduledoc """
  Fill a primitive with a single color

  The color paint is used as the data for the [`:fill`](Scenic.Primitive.Style.Fill.html) style.

  ## Full Format

  `{:color, valid_color}`

  The full format is a tuple with two parameters. The first is the :color atom indicating
  that this is color paint data. The second is any valid color (see below).

  ## Shortcut Format

  `valid_color`

  Because the color paint type is used so frequently, you can simply pass in any valid
  color and the `:fill` style will infer that it is to be used as paint.

  Example:

      graph
      |> line({{0,0}, {100,100}}, fill: :blue)

  ## Valid Colors

  There are several ways to specify a color.

  #### Named Colors

  The simplest is to used a named color (see the table below). Named colors are simply
  referred to by an atom, which is their name. Named colors are opaque by default.

  #### Named Colors with Alpha / Transparency

  If you want a named color with a transparency, you can wrap it in a tuple and add
  a number between 0 and 255 (or 0x00 and 0xFF), to represent the alpha transparency.

  `{:blue, 128}`

  #### RGB Colors

  An RGB color directly specifies the three color channels as a tuple. It is opaque
  by default.

      {123, 231, 210}
      {0xA1, 0xB1, 0xC1}

  #### RGBA Colors

  An RGBA color directly specifies the three color channels and the alpha/transparecy
  as a tuple.

      {123, 231, 210, 128}
      {0xA1, 0xB1, 0xC1, 0x12}


  ## Named Colors

  The set of named colors is adapted from the formal named colors from html.

  | Name          | Value                  | Example   |
  |---------------|------------------------|-----------|
  |  `:alice_blue` | `{0xF0, 0xF8, 0xFF}` | <div style="width=100%; background-color: AliceBlue;">&nbsp;</div> |
  | `:antique_white` | `{0xFA, 0xEB, 0xD7}` | <div style="width=100%; background-color: AntiqueWhite;">&nbsp;</div> |
  | `:aqua` | `{0x00, 0xFF, 0xFF}` | <div style="width=100%; background-color: Aqua;">&nbsp;</div> |
  | `:aquamarine` | `{0x7F, 0xFF, 0xD4}` | <div style="width=100%; background-color: Aquamarine;">&nbsp;</div> |
  | `:azure` | `{0xF0, 0xFF, 0xFF}` | <div style="width=100%; background-color: Azure;">&nbsp;</div> |
  | `:beige` | `{0xF5, 0xF5, 0xDC}` | <div style="width=100%; background-color: Beige;">&nbsp;</div> |
  | `:bisque` | `{0xFF, 0xE4, 0xC4}` | <div style="width=100%; background-color: Bisque;">&nbsp;</div> |
  | `:black` | `{0x00, 0x00, 0x00}` | <div style="width=100%; background-color: Black;">&nbsp;</div> |
  | `:blanched_almond` | `{0xFF, 0xEB, 0xCD}` | <div style="width=100%; background-color: BlanchedAlmond;">&nbsp;</div> |
  | `:blue` | `{0x00, 0x00, 0xFF}` | <div style="width=100%; background-color: Blue;">&nbsp;</div> |
  | `:blue_violet` | `{0x8A, 0x2B, 0xE2}` | <div style="width=100%; background-color: BlueViolet;">&nbsp;</div> |
  | `:brown` | `{0xA5, 0x2A, 0x2A}` | <div style="width=100%; background-color: Brown;">&nbsp;</div> |
  | `:burly_wood` | `{0xDE, 0xB8, 0x87}` | <div style="width=100%; background-color: BurlyWood;">&nbsp;</div> |
  | `:cadet_blue` | `{0x5F, 0x9E, 0xA0}` | <div style="width=100%; background-color: CadetBlue;">&nbsp;</div> |
  | `:chartreuse` | `{0x7F, 0xFF, 0x00}` | <div style="width=100%; background-color: Chartreuse;">&nbsp;</div> |
  | `:chocolate` | `{0xD2, 0x69, 0x1E}` | <div style="width=100%; background-color: Chocolate;">&nbsp;</div> |
  | `:coral` | `{0xFF, 0x7F, 0x50}` | <div style="width=100%; background-color: Coral;">&nbsp;</div> |
  | `:cornflower_blue` | `{0x64, 0x95, 0xED}` | <div style="width=100%; background-color: CornflowerBlue;">&nbsp;</div> |
  | `:cornsilk` | `{0xFF, 0xF8, 0xDC}` | <div style="width=100%; background-color: Cornsilk;">&nbsp;</div> |
  | `:crimson` | `{0xDC, 0x14, 0x3C}` | <div style="width=100%; background-color: Crimson;">&nbsp;</div> |
  | `:cyan` | `{0x00, 0xFF, 0xFF}` | <div style="width=100%; background-color: Cyan;">&nbsp;</div> |
  | `:dark_blue` | `{0x00, 0x00, 0x8B}` | <div style="width=100%; background-color: DarkBlue;">&nbsp;</div> |
  | `:dark_cyan` | `{0x00, 0x8B, 0x8B}` | <div style="width=100%; background-color: DarkCyan;">&nbsp;</div> |
  | `:dark_golden_rod` | `{0xB8, 0x86, 0x0B}` | <div style="width=100%; background-color: DarkGoldenRod;">&nbsp;</div> |
  | `:dark_gray` | `{0xA9, 0xA9, 0xA9}` | <div style="width=100%; background-color: DarkGray;">&nbsp;</div> |
  | `:dark_grey` | `{0xA9, 0xA9, 0xA9}` | <div style="width=100%; background-color: DarkGrey;">&nbsp;</div> |
  | `:dark_green` | `{0x00, 0x64, 0x00}` | <div style="width=100%; background-color: DarkGreen;">&nbsp;</div> |
  | `:dark_khaki` | `{0xBD, 0xB7, 0x6B}` | <div style="width=100%; background-color: DarkKhaki;">&nbsp;</div> |
  | `:dark_magenta` | `{0x8B, 0x00, 0x8B}` | <div style="width=100%; background-color: DarkMagenta;">&nbsp;</div> |
  | `:dark_olive_green` | `{0x55, 0x6B, 0x2F}` | <div style="width=100%; background-color: DarkOliveGreen;">&nbsp;</div> |
  | `:dark_orange` | `{0xFF, 0x8C, 0x00}` | <div style="width=100%; background-color: DarkOrange;">&nbsp;</div> |
  | `:dark_orchid` | `{0x99, 0x32, 0xCC}` | <div style="width=100%; background-color: DarkOrchid;">&nbsp;</div> |
  | `:dark_red` | `{0x8B, 0x00, 0x00}` | <div style="width=100%; background-color: DarkRed;">&nbsp;</div> |
  | `:dark_salmon` | `{0xE9, 0x96, 0x7A}` | <div style="width=100%; background-color: DarkSalmon;">&nbsp;</div> |
  | `:dark_sea_green` | `{0x8F, 0xBC, 0x8F}` | <div style="width=100%; background-color: DarkSeaGreen;">&nbsp;</div> |
  | `:dark_slate_blue` | `{0x48, 0x3D, 0x8B}` | <div style="width=100%; background-color: DarkSlateBlue;">&nbsp;</div> |
  | `:dark_slate_gray` | `{0x2F, 0x4F, 0x4F}` | <div style="width=100%; background-color: DarkSlateGray;">&nbsp;</div> |
  | `:dark_slate_grey` | `{0x2F, 0x4F, 0x4F}` | <div style="width=100%; background-color: DarkSlateGrey;">&nbsp;</div> |
  | `:dark_turquoise` | `{0x00, 0xCE, 0xD1}` | <div style="width=100%; background-color: DarkTurquoise;">&nbsp;</div> |
  | `:dark_violet` | `{0x94, 0x00, 0xD3}` | <div style="width=100%; background-color: DarkViolet;">&nbsp;</div> |
  | `:deep_pink` | `{0xFF, 0x14, 0x93}` | <div style="width=100%; background-color: DeepPink;">&nbsp;</div> |
  | `:deep_sky_blue` | `{0x00, 0xBF, 0xFF}` | <div style="width=100%; background-color: DeepSkyBlue;">&nbsp;</div> |
  | `:dim_gray` | `{0x69, 0x69, 0x69}` | <div style="width=100%; background-color: DimGray;">&nbsp;</div> |
  | `:dim_grey` | `{0x69, 0x69, 0x69}` | <div style="width=100%; background-color: DimGrey;">&nbsp;</div> |
  | `:dodger_blue` | `{0x1E, 0x90, 0xFF}` | <div style="width=100%; background-color: DodgerBlue;">&nbsp;</div> |
  | `:fire_brick` | `{0xB2, 0x22, 0x22}` | <div style="width=100%; background-color: FireBrick;">&nbsp;</div> |
  | `:floral_white` | `{0xFF, 0xFA, 0xF0}` | <div style="width=100%; background-color: FloralWhite;">&nbsp;</div> |
  | `:forest_green` | `{0x22, 0x8B, 0x22}` | <div style="width=100%; background-color: ForestGreen;">&nbsp;</div> |
  | `:fuchsia` | `{0xFF, 0x00, 0xFF}` | <div style="width=100%; background-color: Fuchsia;">&nbsp;</div> |
  | `:gainsboro` | `{0xDC, 0xDC, 0xDC}` | <div style="width=100%; background-color: Gainsboro;">&nbsp;</div> |
  | `:ghost_white` | `{0xF8, 0xF8, 0xFF}` | <div style="width=100%; background-color: GhostWhite;">&nbsp;</div> |
  | `:gold` | `{0xFF, 0xD7, 0x00}` | <div style="width=100%; background-color: Gold;">&nbsp;</div> |
  | `:golden_rod` | `{0xDA, 0xA5, 0x20}` | <div style="width=100%; background-color: GoldenRod;">&nbsp;</div> |
  | `:gray` | `{0x80, 0x80, 0x80}` | <div style="width=100%; background-color: Gray;">&nbsp;</div> |
  | `:grey` | `{0x80, 0x80, 0x80}` | <div style="width=100%; background-color: Grey;">&nbsp;</div> |
  | `:green` | `{0x00, 0x80, 0x00}` | <div style="width=100%; background-color: Green;">&nbsp;</div> |
  | `:green_yellow` | `{0xAD, 0xFF, 0x2F}` | <div style="width=100%; background-color: GreenYellow;">&nbsp;</div> |
  | `:honey_dew` | `{0xF0, 0xFF, 0xF0}` | <div style="width=100%; background-color: HoneyDew;">&nbsp;</div> |
  | `:hot_pink` | `{0xFF, 0x69, 0xB4}` | <div style="width=100%; background-color: HotPink;">&nbsp;</div> |
  | `:indian_red` | `{0xCD, 0x5C, 0x5C}` | <div style="width=100%; background-color: IndianRed;">&nbsp;</div> |
  | `:indigo` | `{0x4B, 0x00, 0x82}` | <div style="width=100%; background-color: Indigo;">&nbsp;</div> |
  | `:ivory` | `{0xFF, 0xFF, 0xF0}` | <div style="width=100%; background-color: Ivory;">&nbsp;</div> |
  | `:khaki` | `{0xF0, 0xE6, 0x8C}` | <div style="width=100%; background-color: Khaki;">&nbsp;</div> |
  | `:lavender` | `{0xE6, 0xE6, 0xFA}` | <div style="width=100%; background-color: Lavender;">&nbsp;</div> |
  | `:lavender_blush` | `{0xFF, 0xF0, 0xF5}` | <div style="width=100%; background-color: LavenderBlush;">&nbsp;</div> |
  | `:lawn_green` | `{0x7C, 0xFC, 0x00}` | <div style="width=100%; background-color: LawnGreen;">&nbsp;</div> |
  | `:lemon_chiffon` | `{0xFF, 0xFA, 0xCD}` | <div style="width=100%; background-color: LemonChiffon;">&nbsp;</div> |
  | `:light_blue` | `{0xAD, 0xD8, 0xE6}` | <div style="width=100%; background-color: LightBlue;">&nbsp;</div> |
  | `:light_coral` | `{0xF0, 0x80, 0x80}` | <div style="width=100%; background-color: LightCoral;">&nbsp;</div> |
  | `:light_cyan` | `{0xE0, 0xFF, 0xFF}` | <div style="width=100%; background-color: LightCyan;">&nbsp;</div> |
  | `:light_golden_rod_yellow` | `{0xFA, 0xFA, 0xD2}` | <div style="width=100%; background-color: LightGoldenRodYellow;">&nbsp;</div> |
  | `:light_gray` | `{0xD3, 0xD3, 0xD3}` | <div style="width=100%; background-color: LightGray;">&nbsp;</div> |
  | `:light_grey` | `{0xD3, 0xD3, 0xD3}` | <div style="width=100%; background-color: LightGrey;">&nbsp;</div> |
  | `:light_green` | `{0x90, 0xEE, 0x90}` | <div style="width=100%; background-color: LightGreen;">&nbsp;</div> |
  | `:light_pink` | `{0xFF, 0xB6, 0xC1}` | <div style="width=100%; background-color: LightPink;">&nbsp;</div> |
  | `:light_salmon` | `{0xFF, 0xA0, 0x7A}` | <div style="width=100%; background-color: LightSalmon;">&nbsp;</div> |
  | `:light_sea_green` | `{0x20, 0xB2, 0xAA}` | <div style="width=100%; background-color: LightSeaGreen;">&nbsp;</div> |
  | `:light_sky_blue` | `{0x87, 0xCE, 0xFA}` | <div style="width=100%; background-color: LightSkyBlue;">&nbsp;</div> |
  | `:light_slate_gray` | `{0x77, 0x88, 0x99}` | <div style="width=100%; background-color: LightSlateGray;">&nbsp;</div> |
  | `:light_slate_grey` | `{0x77, 0x88, 0x99}` | <div style="width=100%; background-color: LightSlateGrey;">&nbsp;</div> |
  | `:light_steel_blue` | `{0xB0, 0xC4, 0xDE}` | <div style="width=100%; background-color: LightSteelBlue;">&nbsp;</div> |
  | `:light_yellow` | `{0xFF, 0xFF, 0xE0}` | <div style="width=100%; background-color: LightYellow;">&nbsp;</div> |
  | `:lime` | `{0x00, 0xFF, 0x00}` | <div style="width=100%; background-color: Lime;">&nbsp;</div> |
  | `:lime_green` | `{0x32, 0xCD, 0x32}` | <div style="width=100%; background-color: LimeGreen;">&nbsp;</div> |
  | `:linen` | `{0xFA, 0xF0, 0xE6}` | <div style="width=100%; background-color: Linen;">&nbsp;</div> |
  | `:magenta` | `{0xFF, 0x00, 0xFF}` | <div style="width=100%; background-color: Magenta;">&nbsp;</div> |
  | `:maroon` | `{0x80, 0x00, 0x00}` | <div style="width=100%; background-color: Maroon;">&nbsp;</div> |
  | `:medium_aqua_marine` | `{0x66, 0xCD, 0xAA}` | <div style="width=100%; background-color: MediumAquaMarine;">&nbsp;</div> |
  | `:medium_blue` | `{0x00, 0x00, 0xCD}` | <div style="width=100%; background-color: MediumBlue;">&nbsp;</div> |
  | `:medium_orchid` | `{0xBA, 0x55, 0xD3}` | <div style="width=100%; background-color: MediumOrchid;">&nbsp;</div> |
  | `:medium_purple` | `{0x93, 0x70, 0xDB}` | <div style="width=100%; background-color: MediumPurple;">&nbsp;</div> |
  | `:medium_sea_green` | `{0x3C, 0xB3, 0x71}` | <div style="width=100%; background-color: MediumSeaGreen;">&nbsp;</div> |
  | `:medium_slate_blue` | `{0x7B, 0x68, 0xEE}` | <div style="width=100%; background-color: MediumSlateBlue;">&nbsp;</div> |
  | `:medium_spring_green` | `{0x00, 0xFA, 0x9A}` | <div style="width=100%; background-color: MediumSpringGreen;">&nbsp;</div> |
  | `:medium_turquoise` | `{0x48, 0xD1, 0xCC}` | <div style="width=100%; background-color: MediumTurquoise;">&nbsp;</div> |
  | `:medium_violet_red` | `{0xC7, 0x15, 0x85}` | <div style="width=100%; background-color: MediumVioletRed;">&nbsp;</div> |
  | `:midnight_blue` | `{0x19, 0x19, 0x70}` | <div style="width=100%; background-color: MidnightBlue;">&nbsp;</div> |
  | `:mint_cream` | `{0xF5, 0xFF, 0xFA}` | <div style="width=100%; background-color: MintCream;">&nbsp;</div> |
  | `:misty_rose` | `{0xFF, 0xE4, 0xE1}` | <div style="width=100%; background-color: MistyRose;">&nbsp;</div> |
  | `:moccasin` | `{0xFF, 0xE4, 0xB5}` | <div style="width=100%; background-color: Moccasin;">&nbsp;</div> |
  | `:navajo_white` | `{0xFF, 0xDE, 0xAD}` | <div style="width=100%; background-color: NavajoWhite;">&nbsp;</div> |
  | `:navy` | `{0x00, 0x00, 0x80}` | <div style="width=100%; background-color: Navy;">&nbsp;</div> |
  | `:old_lace` | `{0xFD, 0xF5, 0xE6}` | <div style="width=100%; background-color: OldLace;">&nbsp;</div> |
  | `:olive` | `{0x80, 0x80, 0x00}` | <div style="width=100%; background-color: Olive;">&nbsp;</div> |
  | `:olive_drab` | `{0x6B, 0x8E, 0x23}` | <div style="width=100%; background-color: OliveDrab;">&nbsp;</div> |
  | `:orange` | `{0xFF, 0xA5, 0x00}` | <div style="width=100%; background-color: Orange;">&nbsp;</div> |
  | `:orange_red` | `{0xFF, 0x45, 0x00}` | <div style="width=100%; background-color: OrangeRed;">&nbsp;</div> |
  | `:orchid` | `{0xDA, 0x70, 0xD6}` | <div style="width=100%; background-color: Orchid;">&nbsp;</div> |
  | `:pale_golden_rod` | `{0xEE, 0xE8, 0xAA}` | <div style="width=100%; background-color: PaleGoldenRod;">&nbsp;</div> |
  | `:pale_green` | `{0x98, 0xFB, 0x98}` | <div style="width=100%; background-color: PaleGreen;">&nbsp;</div> |
  | `:pale_turquoise` | `{0xAF, 0xEE, 0xEE}` | <div style="width=100%; background-color: PaleTurquoise;">&nbsp;</div> |
  | `:pale_violet_red` | `{0xDB, 0x70, 0x93}` | <div style="width=100%; background-color: PaleVioletRed;">&nbsp;</div> |
  | `:papaya_whip` | `{0xFF, 0xEF, 0xD5}` | <div style="width=100%; background-color: PapayaWhip;">&nbsp;</div> |
  | `:peach_puff` | `{0xFF, 0xDA, 0xB9}` | <div style="width=100%; background-color: PeachPuff;">&nbsp;</div> |
  | `:peru` | `{0xCD, 0x85, 0x3F}` | <div style="width=100%; background-color: Peru;">&nbsp;</div> |
  | `:pink` | `{0xFF, 0xC0, 0xCB}` | <div style="width=100%; background-color: Pink;">&nbsp;</div> |
  | `:plum` | `{0xDD, 0xA0, 0xDD}` | <div style="width=100%; background-color: Plum;">&nbsp;</div> |
  | `:powder_blue` | `{0xB0, 0xE0, 0xE6}` | <div style="width=100%; background-color: PowderBlue;">&nbsp;</div> |
  | `:purple` | `{0x80, 0x00, 0x80}` | <div style="width=100%; background-color: Purple;">&nbsp;</div> |
  | `:rebecca_purple` | `{0x66, 0x33, 0x99}` | <div style="width=100%; background-color: RebeccaPurple;">&nbsp;</div> |
  | `:red` | `{0xFF, 0x00, 0x00}` | <div style="width=100%; background-color: Red;">&nbsp;</div> |
  | `:rosy_brown` | `{0xBC, 0x8F, 0x8F}` | <div style="width=100%; background-color: RosyBrown;">&nbsp;</div> |
  | `:royal_blue` | `{0x41, 0x69, 0xE1}` | <div style="width=100%; background-color: RoyalBlue;">&nbsp;</div> |
  | `:saddle_brown` | `{0x8B, 0x45, 0x13}` | <div style="width=100%; background-color: SaddleBrown;">&nbsp;</div> |
  | `:salmon` | `{0xFA, 0x80, 0x72}` | <div style="width=100%; background-color: Salmon;">&nbsp;</div> |
  | `:sandy_brown` | `{0xF4, 0xA4, 0x60}` | <div style="width=100%; background-color: SandyBrown;">&nbsp;</div> |
  | `:sea_green` | `{0x2E, 0x8B, 0x57}` | <div style="width=100%; background-color: SeaGreen;">&nbsp;</div> |
  | `:sea_shell` | `{0xFF, 0xF5, 0xEE}` | <div style="width=100%; background-color: SeaShell;">&nbsp;</div> |
  | `:sienna` | `{0xA0, 0x52, 0x2D}` | <div style="width=100%; background-color: Sienna;">&nbsp;</div> |
  | `:silver` | `{0xC0, 0xC0, 0xC0}` | <div style="width=100%; background-color: Silver;">&nbsp;</div> |
  | `:sky_blue` | `{0x87, 0xCE, 0xEB}` | <div style="width=100%; background-color: SkyBlue;">&nbsp;</div> |
  | `:slate_blue` | `{0x6A, 0x5A, 0xCD}` | <div style="width=100%; background-color: SlateBlue;">&nbsp;</div> |
  | `:slate_gray` | `{0x70, 0x80, 0x90}` | <div style="width=100%; background-color: SlateGray;">&nbsp;</div> |
  | `:slate_grey` | `{0x70, 0x80, 0x90}` | <div style="width=100%; background-color: SlateGrey;">&nbsp;</div> |
  | `:snow` | `{0xFF, 0xFA, 0xFA}` | <div style="width=100%; background-color: Snow;">&nbsp;</div> |
  | `:spring_green` | `{0x00, 0xFF, 0x7F}` | <div style="width=100%; background-color: SpringGreen;">&nbsp;</div> |
  | `:steel_blue` | `{0x46, 0x82, 0xB4}` | <div style="width=100%; background-color: SteelBlue;">&nbsp;</div> |
  | `:tan` | `{0xD2, 0xB4, 0x8C}` | <div style="width=100%; background-color: Tan;">&nbsp;</div> |
  | `:teal` | `{0x00, 0x80, 0x80}` | <div style="width=100%; background-color: Teal;">&nbsp;</div> |
  | `:thistle` | `{0xD8, 0xBF, 0xD8}` | <div style="width=100%; background-color: Thistle;">&nbsp;</div> |
  | `:tomato` | `{0xFF, 0x63, 0x47}` | <div style="width=100%; background-color: Tomato;">&nbsp;</div> |
  | `:turquoise` | `{0x40, 0xE0, 0xD0}` | <div style="width=100%; background-color: Turquoise;">&nbsp;</div> |
  | `:violet` | `{0xEE, 0x82, 0xEE}` | <div style="width=100%; background-color: Violet;">&nbsp;</div> |
  | `:wheat` | `{0xF5, 0xDE, 0xB3}` | <div style="width=100%; background-color: Wheat;">&nbsp;</div> |
  | `:white` | `{0xFF, 0xFF, 0xFF}` | <div style="width=100%; background-color: White;">&nbsp;</div> |
  | `:white_smoke` | `{0xF5, 0xF5, 0xF5}` | <div style="width=100%; background-color: WhiteSmoke;">&nbsp;</div> |
  | `:yellow` | `{0xFF, 0xFF, 0x00}` | <div style="width=100%; background-color: Yellow;">&nbsp;</div> |
  | `:yellow_green` | `{0x9A, 0xCD, 0x32}` | <div style="width=100%; background-color: YellowGreen;">&nbsp;</div> |

  ## Additional Named Colors

    | Name          | Value                  | Example   |
  |---------------|------------------------|-----------|
  | `:clear` | `{0x80, 0x80, 0x80, 0x00}` | |
  | `:transparent` | `{0x80, 0x80, 0x80, 0x00}` | |

  """

  @type rgb :: {r :: number, g :: number, b :: number}
  @type rgba :: {r :: number, g :: number, b :: number, a :: number}

  @type t ::
          atom
          | {name :: atom, a :: number}
          | rgb
          | rgba

  # ============================================================================
  # data verification and serialization

  @doc """
  Verify that a color is correctly described
  """
  def verify(color) do
    normalize(color)
    true
  rescue
    _ -> false
  end

  # --------------------------------------------------------
  # single color
  @doc false
  def normalize(color) when is_atom(color), do: to_rgba(color)

  def normalize({color, alpha}) when is_atom(color) and is_integer(alpha),
    do: to_rgba({color, alpha})

  def normalize({r, g, b}) when is_integer(r) and is_integer(g) and is_integer(b),
    do: to_rgba({r, g, b})

  def normalize({r, g, b, a})
      when is_integer(r) and is_integer(g) and is_integer(b) and is_integer(a),
      do: to_rgba({r, g, b, a})

  # ============================================================================
  # https://www.w3schools.com/colors/colors_names.asp

  @doc false
  defguard is_uint8(x) when is_integer(x) and x >= 0 and x <= 255

  @doc """
  Convert a named or RGB color to RGBA format
  """
  @spec to_rgba(color :: t()) :: rgba()
  def to_rgba(color)
  def to_rgba({:transparent, _}), do: to_rgba(:transparent)
  def to_rgba(:transparent), do: {0x80, 0x80, 0x80, 0x00}
  def to_rgba({:clear, _}), do: to_rgba(:transparent)
  def to_rgba(:clear), do: to_rgba(:transparent)

  def to_rgba({r, g, b}), do: to_rgba({r, g, b, 0xFF})

  def to_rgba({r, g, b, a})
      when is_uint8(r) and is_uint8(g) and is_uint8(b) and is_uint8(a) do
    {r, g, b, a}
  end

  def to_rgba(<<r::size(8), g::size(8), b::size(8), a::size(8)>>), do: {r, g, b, a}

  def to_rgba(named_color) when is_atom(named_color) do
    named_color
    |> name_to_rgb()
    |> to_rgba()
  end

  def to_rgba({named_color, alpha})
      when is_atom(named_color) and is_uint8(alpha) do
    {r, g, b} = name_to_rgb(named_color)
    {r, g, b, alpha}
  end

  @doc """
  Convert a named color to RGB format
  """
  @spec name_to_rgb(name :: atom) :: rgb()
  def name_to_rgb(name)
  def name_to_rgb(:alice_blue), do: {0xF0, 0xF8, 0xFF}
  def name_to_rgb(:antique_white), do: {0xFA, 0xEB, 0xD7}
  def name_to_rgb(:aqua), do: {0x00, 0xFF, 0xFF}
  def name_to_rgb(:aquamarine), do: {0x7F, 0xFF, 0xD4}
  def name_to_rgb(:azure), do: {0xF0, 0xFF, 0xFF}
  def name_to_rgb(:beige), do: {0xF5, 0xF5, 0xDC}
  def name_to_rgb(:bisque), do: {0xFF, 0xE4, 0xC4}
  def name_to_rgb(:black), do: {0x00, 0x00, 0x00}
  def name_to_rgb(:blanched_almond), do: {0xFF, 0xEB, 0xCD}
  def name_to_rgb(:blue), do: {0x00, 0x00, 0xFF}
  def name_to_rgb(:blue_violet), do: {0x8A, 0x2B, 0xE2}
  def name_to_rgb(:brown), do: {0xA5, 0x2A, 0x2A}
  def name_to_rgb(:burly_wood), do: {0xDE, 0xB8, 0x87}
  def name_to_rgb(:cadet_blue), do: {0x5F, 0x9E, 0xA0}
  def name_to_rgb(:chartreuse), do: {0x7F, 0xFF, 0x00}
  def name_to_rgb(:chocolate), do: {0xD2, 0x69, 0x1E}
  def name_to_rgb(:coral), do: {0xFF, 0x7F, 0x50}
  def name_to_rgb(:cornflower_blue), do: {0x64, 0x95, 0xED}
  def name_to_rgb(:cornsilk), do: {0xFF, 0xF8, 0xDC}
  def name_to_rgb(:crimson), do: {0xDC, 0x14, 0x3C}
  def name_to_rgb(:cyan), do: {0x00, 0xFF, 0xFF}
  def name_to_rgb(:dark_blue), do: {0x00, 0x00, 0x8B}
  def name_to_rgb(:dark_cyan), do: {0x00, 0x8B, 0x8B}
  def name_to_rgb(:dark_golden_rod), do: {0xB8, 0x86, 0x0B}
  def name_to_rgb(:dark_gray), do: {0xA9, 0xA9, 0xA9}
  def name_to_rgb(:dark_grey), do: {0xA9, 0xA9, 0xA9}
  def name_to_rgb(:dark_green), do: {0x00, 0x64, 0x00}
  def name_to_rgb(:dark_khaki), do: {0xBD, 0xB7, 0x6B}
  def name_to_rgb(:dark_magenta), do: {0x8B, 0x00, 0x8B}
  def name_to_rgb(:dark_olive_green), do: {0x55, 0x6B, 0x2F}
  def name_to_rgb(:dark_orange), do: {0xFF, 0x8C, 0x00}
  def name_to_rgb(:dark_orchid), do: {0x99, 0x32, 0xCC}
  def name_to_rgb(:dark_red), do: {0x8B, 0x00, 0x00}
  def name_to_rgb(:dark_salmon), do: {0xE9, 0x96, 0x7A}
  def name_to_rgb(:dark_sea_green), do: {0x8F, 0xBC, 0x8F}
  def name_to_rgb(:dark_slate_blue), do: {0x48, 0x3D, 0x8B}
  def name_to_rgb(:dark_slate_gray), do: {0x2F, 0x4F, 0x4F}
  def name_to_rgb(:dark_slate_grey), do: {0x2F, 0x4F, 0x4F}
  def name_to_rgb(:dark_turquoise), do: {0x00, 0xCE, 0xD1}
  def name_to_rgb(:dark_violet), do: {0x94, 0x00, 0xD3}
  def name_to_rgb(:deep_pink), do: {0xFF, 0x14, 0x93}
  def name_to_rgb(:deep_sky_blue), do: {0x00, 0xBF, 0xFF}
  def name_to_rgb(:dim_gray), do: {0x69, 0x69, 0x69}
  def name_to_rgb(:dim_grey), do: {0x69, 0x69, 0x69}
  def name_to_rgb(:dodger_blue), do: {0x1E, 0x90, 0xFF}
  def name_to_rgb(:fire_brick), do: {0xB2, 0x22, 0x22}
  def name_to_rgb(:floral_white), do: {0xFF, 0xFA, 0xF0}
  def name_to_rgb(:forest_green), do: {0x22, 0x8B, 0x22}
  def name_to_rgb(:fuchsia), do: {0xFF, 0x00, 0xFF}
  def name_to_rgb(:gainsboro), do: {0xDC, 0xDC, 0xDC}
  def name_to_rgb(:ghost_white), do: {0xF8, 0xF8, 0xFF}
  def name_to_rgb(:gold), do: {0xFF, 0xD7, 0x00}
  def name_to_rgb(:golden_rod), do: {0xDA, 0xA5, 0x20}
  def name_to_rgb(:gray), do: {0x80, 0x80, 0x80}
  def name_to_rgb(:grey), do: {0x80, 0x80, 0x80}
  def name_to_rgb(:green), do: {0x00, 0x80, 0x00}
  def name_to_rgb(:green_yellow), do: {0xAD, 0xFF, 0x2F}
  def name_to_rgb(:honey_dew), do: {0xF0, 0xFF, 0xF0}
  def name_to_rgb(:hot_pink), do: {0xFF, 0x69, 0xB4}
  def name_to_rgb(:indian_red), do: {0xCD, 0x5C, 0x5C}
  def name_to_rgb(:indigo), do: {0x4B, 0x00, 0x82}
  def name_to_rgb(:ivory), do: {0xFF, 0xFF, 0xF0}
  def name_to_rgb(:khaki), do: {0xF0, 0xE6, 0x8C}
  def name_to_rgb(:lavender), do: {0xE6, 0xE6, 0xFA}
  def name_to_rgb(:lavender_blush), do: {0xFF, 0xF0, 0xF5}
  def name_to_rgb(:lawn_green), do: {0x7C, 0xFC, 0x00}
  def name_to_rgb(:lemon_chiffon), do: {0xFF, 0xFA, 0xCD}
  def name_to_rgb(:light_blue), do: {0xAD, 0xD8, 0xE6}
  def name_to_rgb(:light_coral), do: {0xF0, 0x80, 0x80}
  def name_to_rgb(:light_cyan), do: {0xE0, 0xFF, 0xFF}
  def name_to_rgb(:light_golden_rod_yellow), do: {0xFA, 0xFA, 0xD2}
  def name_to_rgb(:light_gray), do: {0xD3, 0xD3, 0xD3}
  def name_to_rgb(:light_grey), do: {0xD3, 0xD3, 0xD3}
  def name_to_rgb(:light_green), do: {0x90, 0xEE, 0x90}
  def name_to_rgb(:light_pink), do: {0xFF, 0xB6, 0xC1}
  def name_to_rgb(:light_salmon), do: {0xFF, 0xA0, 0x7A}
  def name_to_rgb(:light_sea_green), do: {0x20, 0xB2, 0xAA}
  def name_to_rgb(:light_sky_blue), do: {0x87, 0xCE, 0xFA}
  def name_to_rgb(:light_slate_gray), do: {0x77, 0x88, 0x99}
  def name_to_rgb(:light_slate_grey), do: {0x77, 0x88, 0x99}
  def name_to_rgb(:light_steel_blue), do: {0xB0, 0xC4, 0xDE}
  def name_to_rgb(:light_yellow), do: {0xFF, 0xFF, 0xE0}
  def name_to_rgb(:lime), do: {0x00, 0xFF, 0x00}
  def name_to_rgb(:lime_green), do: {0x32, 0xCD, 0x32}
  def name_to_rgb(:linen), do: {0xFA, 0xF0, 0xE6}
  def name_to_rgb(:magenta), do: {0xFF, 0x00, 0xFF}
  def name_to_rgb(:maroon), do: {0x80, 0x00, 0x00}
  def name_to_rgb(:medium_aqua_marine), do: {0x66, 0xCD, 0xAA}
  def name_to_rgb(:medium_blue), do: {0x00, 0x00, 0xCD}
  def name_to_rgb(:medium_orchid), do: {0xBA, 0x55, 0xD3}
  def name_to_rgb(:medium_purple), do: {0x93, 0x70, 0xDB}
  def name_to_rgb(:medium_sea_green), do: {0x3C, 0xB3, 0x71}
  def name_to_rgb(:medium_slate_blue), do: {0x7B, 0x68, 0xEE}
  def name_to_rgb(:medium_spring_green), do: {0x00, 0xFA, 0x9A}
  def name_to_rgb(:medium_turquoise), do: {0x48, 0xD1, 0xCC}
  def name_to_rgb(:medium_violet_red), do: {0xC7, 0x15, 0x85}
  def name_to_rgb(:midnight_blue), do: {0x19, 0x19, 0x70}
  def name_to_rgb(:mint_cream), do: {0xF5, 0xFF, 0xFA}
  def name_to_rgb(:misty_rose), do: {0xFF, 0xE4, 0xE1}
  def name_to_rgb(:moccasin), do: {0xFF, 0xE4, 0xB5}
  def name_to_rgb(:navajo_white), do: {0xFF, 0xDE, 0xAD}
  def name_to_rgb(:navy), do: {0x00, 0x00, 0x80}
  def name_to_rgb(:old_lace), do: {0xFD, 0xF5, 0xE6}
  def name_to_rgb(:olive), do: {0x80, 0x80, 0x00}
  def name_to_rgb(:olive_drab), do: {0x6B, 0x8E, 0x23}
  def name_to_rgb(:orange), do: {0xFF, 0xA5, 0x00}
  def name_to_rgb(:orange_red), do: {0xFF, 0x45, 0x00}
  def name_to_rgb(:orchid), do: {0xDA, 0x70, 0xD6}
  def name_to_rgb(:pale_golden_rod), do: {0xEE, 0xE8, 0xAA}
  def name_to_rgb(:pale_green), do: {0x98, 0xFB, 0x98}
  def name_to_rgb(:pale_turquoise), do: {0xAF, 0xEE, 0xEE}
  def name_to_rgb(:pale_violet_red), do: {0xDB, 0x70, 0x93}
  def name_to_rgb(:papaya_whip), do: {0xFF, 0xEF, 0xD5}
  def name_to_rgb(:peach_puff), do: {0xFF, 0xDA, 0xB9}
  def name_to_rgb(:peru), do: {0xCD, 0x85, 0x3F}
  def name_to_rgb(:pink), do: {0xFF, 0xC0, 0xCB}
  def name_to_rgb(:plum), do: {0xDD, 0xA0, 0xDD}
  def name_to_rgb(:powder_blue), do: {0xB0, 0xE0, 0xE6}
  def name_to_rgb(:purple), do: {0x80, 0x00, 0x80}
  def name_to_rgb(:rebecca_purple), do: {0x66, 0x33, 0x99}
  def name_to_rgb(:red), do: {0xFF, 0x00, 0x00}
  def name_to_rgb(:rosy_brown), do: {0xBC, 0x8F, 0x8F}
  def name_to_rgb(:royal_blue), do: {0x41, 0x69, 0xE1}
  def name_to_rgb(:saddle_brown), do: {0x8B, 0x45, 0x13}
  def name_to_rgb(:salmon), do: {0xFA, 0x80, 0x72}
  def name_to_rgb(:sandy_brown), do: {0xF4, 0xA4, 0x60}
  def name_to_rgb(:sea_green), do: {0x2E, 0x8B, 0x57}
  def name_to_rgb(:sea_shell), do: {0xFF, 0xF5, 0xEE}
  def name_to_rgb(:sienna), do: {0xA0, 0x52, 0x2D}
  def name_to_rgb(:silver), do: {0xC0, 0xC0, 0xC0}
  def name_to_rgb(:sky_blue), do: {0x87, 0xCE, 0xEB}
  def name_to_rgb(:slate_blue), do: {0x6A, 0x5A, 0xCD}
  def name_to_rgb(:slate_gray), do: {0x70, 0x80, 0x90}
  def name_to_rgb(:slate_grey), do: {0x70, 0x80, 0x90}
  def name_to_rgb(:snow), do: {0xFF, 0xFA, 0xFA}
  def name_to_rgb(:spring_green), do: {0x00, 0xFF, 0x7F}
  def name_to_rgb(:steel_blue), do: {0x46, 0x82, 0xB4}
  def name_to_rgb(:tan), do: {0xD2, 0xB4, 0x8C}
  def name_to_rgb(:teal), do: {0x00, 0x80, 0x80}
  def name_to_rgb(:thistle), do: {0xD8, 0xBF, 0xD8}
  def name_to_rgb(:tomato), do: {0xFF, 0x63, 0x47}
  def name_to_rgb(:turquoise), do: {0x40, 0xE0, 0xD0}
  def name_to_rgb(:violet), do: {0xEE, 0x82, 0xEE}
  def name_to_rgb(:wheat), do: {0xF5, 0xDE, 0xB3}
  def name_to_rgb(:white), do: {0xFF, 0xFF, 0xFF}
  def name_to_rgb(:white_smoke), do: {0xF5, 0xF5, 0xF5}
  def name_to_rgb(:yellow), do: {0xFF, 0xFF, 0x00}
  def name_to_rgb(:yellow_green), do: {0x9A, 0xCD, 0x32}
end
