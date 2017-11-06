#
#  Created by Boyd Multerer on 11/05/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# The main helpers and organizers for input


defmodule Scenic.ViewPort.Input do
  use GenServer
  use Bitwise

  require Logger
  alias Scenic.ViewPort

  @valid_input_types  [
    :input_key,
    :input_codepoint,
    :input_mouse_move,
    :input_mouse_button,
    :input_mouse_scroll,
    :input_mouse_enter
  ]

  @registry     :input_registry

  #===========================================================================
  defmodule Error do
    defexception [ message: nil ]
  end

  #============================================================================
  # client apis - meant to be called from the listener process

  #--------------------------------------------------------
  def register_input( type, cookie \\ nil )
  def register_input( :input_all, cookie ) do 
    ref = make_ref()
    Enum.each(@valid_input_types, &Registry.register(@registry, &1, {cookie, ref} ) )
    update_input_request()
    {:input_ref, ref}
  end
  def register_input( type, cookie ) when is_atom(type) do
    ref = make_ref()
    do_register( type, ref, cookie )
    update_input_request()
    {:input_ref, ref}
  end
  def register_input( types, cookie ) when is_list(types) do
    ref = make_ref()
    Enum.each( types, &do_register(&1, ref, cookie) )
    update_input_request()
    {:input_ref, ref}
  end
  defp do_register( type, ref, cookie ) when is_atom(type) do
    case Enum.member?(@valid_input_types, type) do
      true ->
        Registry.register(@registry, type, {cookie, ref} )
      false ->
        raise Error, message: "Invalid input type: #{inspect(type)}"
    end
  end

  #--------------------------------------------------------
  def unregister_input( type )
  def unregister_input( {:input_ref, ref} ) when is_reference(ref) do
    Enum.each(@valid_input_types, fn(type) ->
      Registry.unregister_match(@registry, type, {:_, ref} )
    end)
    update_input_request()
  end
  def unregister_input( :input_all ) do
    Enum.each(@valid_input_types, &Registry.unregister(@registry, &1 ) )
    update_input_request()
  end
  def unregister_input( type ) when is_atom(type) do
    do_unregister( type )
    update_input_request()
  end
  def unregister_input( types ) when is_list(types) do
    Enum.each( types, &do_unregister(&1) )
    update_input_request()
  end
  defp do_unregister( type ) when is_atom(type) do
    case Enum.member?(@valid_input_types, type) do
      true ->
        Registry.unregister(@registry, type )
      false ->
        raise Error, message: "Invalid input type: #{inspect(type)}"
    end
  end


  #--------------------------------------------------------
  # gather registrations from the registry. Turn that into a flag field,
  # then send that to the driver
  defp update_input_request() do
  end


  #============================================================================
  # driver apis - meant to be called from a driver that is sending input

  #----------------------------------------------
  def send_input( {input_type, message} ) do
    # needs a different dispatcher than sending a message to the driver. The pid to
    # send the message to is the value stored in the registry, not the pid that
    # set up the registry entry. That would be the viewport...

    # dispatch the call to any listening drivers
    Registry.dispatch(@registry, input_type, fn(entries) ->
      for {pid, {cookie, ref}} <- entries do
        try do
          GenServer.cast(pid, {input_type, message, cookie})
        catch
          kind, reason ->
            formatted = Exception.format(kind, reason, System.stacktrace)
            Logger.error "Registry.dispatch/3 failed with #{formatted}"
        end
      end
    end)
  end
  #============================================================================
  # keyboard input helpers
  # these are for reading the keyboard directly. If you are trying to do text input
  # use the text/char helpers instead

  # key codes use the standards defined by GLFW
  # http://www.glfw.org/docs/latest/group__keys.html

  #--------------------------------------------------------
  def key_to_atom( key_code )
  def key_to_atom( 32 ),    do: :key_space
  def key_to_atom( 39 ),    do: :key_apostrophe
  def key_to_atom( 44 ),    do: :key_comma
  def key_to_atom( 45 ),    do: :key_minus
  def key_to_atom( 46 ),    do: :key_period
  def key_to_atom( 47 ),    do: :key_slash

  def key_to_atom( 48 ),    do: :key_0
  def key_to_atom( 49 ),    do: :key_1
  def key_to_atom( 50 ),    do: :key_2
  def key_to_atom( 51 ),    do: :key_3
  def key_to_atom( 52 ),    do: :key_4
  def key_to_atom( 53 ),    do: :key_5
  def key_to_atom( 54 ),    do: :key_6
  def key_to_atom( 55 ),    do: :key_7
  def key_to_atom( 56 ),    do: :key_8
  def key_to_atom( 57 ),    do: :key_9

  def key_to_atom( 59 ),    do: :key_semicolon
  def key_to_atom( 61 ),    do: :key_equal

  def key_to_atom( 65 ),    do: :key_a
  def key_to_atom( 66 ),    do: :key_b
  def key_to_atom( 67 ),    do: :key_c
  def key_to_atom( 68 ),    do: :key_d
  def key_to_atom( 69 ),    do: :key_e
  def key_to_atom( 70 ),    do: :key_f
  def key_to_atom( 71 ),    do: :key_g
  def key_to_atom( 72 ),    do: :key_h
  def key_to_atom( 73 ),    do: :key_i
  def key_to_atom( 74 ),    do: :key_j
  def key_to_atom( 75 ),    do: :key_k
  def key_to_atom( 76 ),    do: :key_l
  def key_to_atom( 77 ),    do: :key_m
  def key_to_atom( 78 ),    do: :key_n
  def key_to_atom( 79 ),    do: :key_o
  def key_to_atom( 80 ),    do: :key_p
  def key_to_atom( 81 ),    do: :key_q
  def key_to_atom( 82 ),    do: :key_r
  def key_to_atom( 83 ),    do: :key_s
  def key_to_atom( 84 ),    do: :key_t
  def key_to_atom( 85 ),    do: :key_u
  def key_to_atom( 86 ),    do: :key_v
  def key_to_atom( 87 ),    do: :key_w
  def key_to_atom( 88 ),    do: :key_x
  def key_to_atom( 89 ),    do: :key_y
  def key_to_atom( 90 ),    do: :key_z

  def key_to_atom( 91 ),    do: :key_left_bracket         # [
  def key_to_atom( 92 ),    do: :key_backslash            # \
  def key_to_atom( 93 ),    do: :key_right_bracket        # ]
  def key_to_atom( 96 ),    do: :key_grave_accent         # `

  def key_to_atom( 161 ),   do: :key_world_1              # non-US #1
  def key_to_atom( 162 ),   do: :key_world_2              # non-US #2

  def key_to_atom( 256 ),   do: :key_escape
  def key_to_atom( 257 ),   do: :key_enter
  def key_to_atom( 258 ),   do: :key_tab
  def key_to_atom( 259 ),   do: :key_backspace
  def key_to_atom( 260 ),   do: :key_insert
  def key_to_atom( 261 ),   do: :key_delete

  def key_to_atom( 262 ),   do: :key_right
  def key_to_atom( 263 ),   do: :key_left
  def key_to_atom( 264 ),   do: :key_down
  def key_to_atom( 265 ),   do: :key_up
  def key_to_atom( 266 ),   do: :key_page_up
  def key_to_atom( 267 ),   do: :key_page_down
  def key_to_atom( 268 ),   do: :key_home
  def key_to_atom( 269 ),   do: :key_end

  def key_to_atom( 280 ),   do: :key_caps_lock
  def key_to_atom( 281 ),   do: :key_scroll_lock
  def key_to_atom( 282 ),   do: :key_num_lock

  def key_to_atom( 283 ),   do: :key_print_screen
  def key_to_atom( 284 ),   do: :key_pause

  def key_to_atom( 290 ),   do: :key_f1
  def key_to_atom( 291 ),   do: :key_f2
  def key_to_atom( 292 ),   do: :key_f3
  def key_to_atom( 293 ),   do: :key_f4
  def key_to_atom( 294 ),   do: :key_f5
  def key_to_atom( 295 ),   do: :key_f6
  def key_to_atom( 296 ),   do: :key_f7
  def key_to_atom( 297 ),   do: :key_f8
  def key_to_atom( 298 ),   do: :key_f9
  def key_to_atom( 299 ),   do: :key_f10
  def key_to_atom( 300 ),   do: :key_f11
  def key_to_atom( 301 ),   do: :key_f12
  def key_to_atom( 302 ),   do: :key_f13
  def key_to_atom( 303 ),   do: :key_f14
  def key_to_atom( 304 ),   do: :key_f15
  def key_to_atom( 305 ),   do: :key_f16
  def key_to_atom( 306 ),   do: :key_f17
  def key_to_atom( 307 ),   do: :key_f18
  def key_to_atom( 308 ),   do: :key_f19
  def key_to_atom( 309 ),   do: :key_f20
  def key_to_atom( 310 ),   do: :key_f21
  def key_to_atom( 311 ),   do: :key_f22
  def key_to_atom( 312 ),   do: :key_f23
  def key_to_atom( 313 ),   do: :key_f24
  def key_to_atom( 314 ),   do: :key_f25

  def key_to_atom( 320 ),   do: :key_kp_0
  def key_to_atom( 321 ),   do: :key_kp_1
  def key_to_atom( 322 ),   do: :key_kp_2
  def key_to_atom( 323 ),   do: :key_kp_3
  def key_to_atom( 324 ),   do: :key_kp_4
  def key_to_atom( 325 ),   do: :key_kp_5
  def key_to_atom( 326 ),   do: :key_kp_6
  def key_to_atom( 327 ),   do: :key_kp_7
  def key_to_atom( 328 ),   do: :key_kp_8
  def key_to_atom( 329 ),   do: :key_kp_9

  def key_to_atom( 330 ),   do: :key_kp_decimal
  def key_to_atom( 331 ),   do: :key_kp_divide
  def key_to_atom( 332 ),   do: :key_kp_multiply
  def key_to_atom( 333 ),   do: :key_kp_subtract
  def key_to_atom( 334 ),   do: :key_kp_add
  def key_to_atom( 335 ),   do: :key_kp_enter
  def key_to_atom( 336 ),   do: :key_kp_equal

  def key_to_atom( 340 ),   do: :key_left_shift
  def key_to_atom( 341 ),   do: :key_left_control
  def key_to_atom( 342 ),   do: :key_left_alt
  def key_to_atom( 343 ),   do: :key_left_super

  def key_to_atom( 344 ),   do: :key_right_shift
  def key_to_atom( 345 ),   do: :key_right_control
  def key_to_atom( 346 ),   do: :key_right_alt
  def key_to_atom( 347 ),   do: :key_right_super

  def key_to_atom( 348 ),   do: :key_menu

  def key_to_atom( key ) do
    IO.puts "Unknown key: #{inspect(key)}"
    :key_unknown
  end


  #--------------------------------------------------------
  # defined to follow the GLFW modifier keys
  # http://www.glfw.org/docs/latest/group__mods.html

  @key_mod_shift    0x0001
  @key_mod_control  0x0002
  @key_mod_alt      0x0004
  @key_mod_super    0x0008
  @key_mods         [
    {@key_mod_shift,   :key_mod_shift},
    {@key_mod_control, :key_mod_control},
    {@key_mod_alt,     :key_mod_alt},
    {@key_mod_super,   :key_mod_super}
  ]

  def key_mods_to_atoms( key_mods )
  def key_mods_to_atoms( key_mods ) do
    Enum.reduce(@key_mods, [], fn({mask,mod_atom}, acc) ->
      case Bitwise.band(mask, key_mods) do
        0 -> acc
        _ -> [mod_atom | acc]
      end
    end)
  end

  #--------------------------------------------------------
  def action_to_atom( action )
  def action_to_atom( 0 ),  do: :action_release
  def action_to_atom( 1 ),  do: :action_press
  def action_to_atom( 2 ),  do: :action_repeat
  def action_to_atom( _ ),  do: :action_unknown

  #--------------------------------------------------------
  def codepoint_to_char( codepoint_to_atom )
  def codepoint_to_char( cp ),  do: << cp :: utf8 >>


  #--------------------------------------------------------
  def mouse_button_to_atom( 0 ), do: :button_left
  def mouse_button_to_atom( 1 ), do: :button_right
  def mouse_button_to_atom( _ ), do: :button_unknown

  #--------------------------------------------------------
  def input_type_to_flags( type )
  def input_type_to_flags( types ) when is_list(types) do
    Enum.reduce(types, 0, &(input_type_to_flags(&1) ||| &2) )
  end
  def input_type_to_flags( :input_key ),            do: 0x0001
  def input_type_to_flags( :input_codepoint ),      do: 0x0002
  def input_type_to_flags( :input_mouse_move ),     do: 0x0004
  def input_type_to_flags( :input_mouse_button ),   do: 0x0008
  def input_type_to_flags( :input_mouse_scroll ),   do: 0x0010
  def input_type_to_flags( :input_mouse_enter ),    do: 0x0020
  def input_type_to_flags( :input_all ),            do: 0xFFFF
#  def input_type_to_flags( :none ),                 do: 0x0000
#  def input_type_to_flags( :input_none ),           do: 0x0000
  def input_type_to_flags( type ), do: raise "Driver.Glfw Unknown input type: #{inspect(type)}"


end















