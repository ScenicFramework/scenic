defmodule Scenic.Driver.KeyMapTest do
  use ExUnit.Case, async: false
  doctest Scenic.Driver.KeyMap
  alias Scenic.Driver.KeyMap

  test "caps_lock? works" do
    refute KeyMap.caps_lock?(%{})
    refute KeyMap.caps_lock?(%{virt_caps_lock: 0})
    assert KeyMap.caps_lock?(%{virt_caps_lock: 1})

    refute KeyMap.caps_lock?(%{key_capslock: 1})
    refute KeyMap.caps_lock?(%{key_capslock: 0})
  end

  test "shift? works" do
    refute KeyMap.shift?(%{})
    refute KeyMap.shift?(%{key_leftshift: 0})
    refute KeyMap.shift?(%{key_rightshift: 0})
    refute KeyMap.shift?(%{key_leftshift: 0, key_rightshift: 0})

    assert KeyMap.shift?(%{key_leftshift: 1})
    assert KeyMap.shift?(%{key_rightshift: 1})
    assert KeyMap.shift?(%{key_leftshift: 1, key_rightshift: 0})
    assert KeyMap.shift?(%{key_leftshift: 0, key_rightshift: 1})
    assert KeyMap.shift?(%{key_leftshift: 1, key_rightshift: 1})
  end

  test "alt? works" do
    refute KeyMap.alt?(%{})
    refute KeyMap.alt?(%{key_leftalt: 0})
    refute KeyMap.alt?(%{key_rightalt: 0})
    refute KeyMap.alt?(%{key_leftalt: 0, key_rightalt: 0})

    assert KeyMap.alt?(%{key_leftalt: 1})
    assert KeyMap.alt?(%{key_rightalt: 1})
    assert KeyMap.alt?(%{key_leftalt: 1, key_rightalt: 0})
    assert KeyMap.alt?(%{key_leftalt: 0, key_rightalt: 1})
    assert KeyMap.alt?(%{key_leftalt: 1, key_rightalt: 1})
  end

  test "ctrl? works" do
    refute KeyMap.ctrl?(%{})
    refute KeyMap.ctrl?(%{key_leftctrl: 0})
    refute KeyMap.ctrl?(%{key_rightctrl: 0})
    refute KeyMap.ctrl?(%{key_leftctrl: 0, key_rightctrl: 0})

    assert KeyMap.ctrl?(%{key_leftctrl: 1})
    assert KeyMap.ctrl?(%{key_rightctrl: 1})
    assert KeyMap.ctrl?(%{key_leftctrl: 1, key_rightctrl: 0})
    assert KeyMap.ctrl?(%{key_leftctrl: 0, key_rightctrl: 1})
    assert KeyMap.ctrl?(%{key_leftctrl: 1, key_rightctrl: 1})
  end

  test "meta? works" do
    refute KeyMap.meta?(%{})
    refute KeyMap.meta?(%{key_leftmeta: 0})
    refute KeyMap.meta?(%{key_rightmeta: 0})
    refute KeyMap.meta?(%{key_leftmeta: 0, key_rightmeta: 0})

    assert KeyMap.meta?(%{key_leftmeta: 1})
    assert KeyMap.meta?(%{key_rightmeta: 1})
    assert KeyMap.meta?(%{key_leftmeta: 1, key_rightmeta: 0})
    assert KeyMap.meta?(%{key_leftmeta: 0, key_rightmeta: 1})
    assert KeyMap.meta?(%{key_leftmeta: 1, key_rightmeta: 1})
  end

  test "mods works - single" do
    assert KeyMap.mods(%{}) == []
    assert KeyMap.mods(%{virt_caps_lock: 1}) == [:caps_lock]
    assert KeyMap.mods(%{key_leftshift: 1}) == [:shift]
    assert KeyMap.mods(%{key_rightshift: 1}) == [:shift]
    assert KeyMap.mods(%{key_leftalt: 1}) == [:alt]
    assert KeyMap.mods(%{key_leftctrl: 1}) == [:ctrl]
    assert KeyMap.mods(%{key_rightctrl: 1}) == [:ctrl]
  end

  test "mods works - multiple" do
    assert KeyMap.mods(%{}) == []
    assert KeyMap.mods(%{virt_caps_lock: 1, key_rightctrl: 1}) == [:caps_lock, :ctrl]
    assert KeyMap.mods(%{key_leftshift: 1, key_rightmeta: 1}) == [:shift, :meta]
  end
end
