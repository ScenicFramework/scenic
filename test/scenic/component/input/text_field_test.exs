#
#  Created by Boyd Multerer on 2018-09-18.
#  Rewritten by Boyd Multerer on 2021-05-23
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Component.Input.TextFieldTest do
  use ExUnit.Case, async: false
  doctest Scenic.Component.Input.TextField

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort.Input

  # import IEx

  @initial_value "Initial value"
  # @initial_password "*************"
  # @hint "Hint String"

  @press_in {:cursor_button, {0, :press, 0, {14, 10}}}
  @press_move {:cursor_button, {0, :press, 0, {43, 10}}}
  @press_out {:cursor_button, {0, :press, 0, {1000, 1000}}}

  @cp_k {:codepoint, {"k", 0}}
  @cp_l {:codepoint, {"l", 0}}

  @key_right {:key, {"right", :press, 0}}
  @key_left {:key, {"left", :press, 0}}
  @key_page_up {:key, {"page_up", :press, 0}}
  @key_page_down {:key, {"page_down", :press, 0}}
  @key_home {:key, {"home", :press, 0}}
  @key_end {:key, {"end", :press, 0}}
  @key_backspace {:key, {"backspace", :press, 0}}
  @key_delete {:key, {"delete", :press, 0}}

  defmodule TestScene do
    use Scenic.Scene
    import Scenic.Components

    def graph(text) do
      Graph.build()
      |> text_field(text, id: :text_field, hint: "Hint")
      |> text_field("", id: :number_field, filter: :number, t: {0, 40})
      |> text_field("", id: :integer_field, filter: :integer, t: {0, 80})
      |> text_field("", id: :abcdefg_field, filter: "abcdefg", t: {0, 120})
      |> text_field("", id: :fn_field, t: {0, 160}, filter: fn char -> "hjkl" =~ char end)
      |> text_field("", id: :password_field, t: {0, 200}, type: :password)
    end

    @impl Scenic.Scene
    def init(scene, {pid, text}, _opts) do
      scene =
        scene
        |> assign(pid: pid)
        |> push_graph(graph(text))

      Process.send(pid, {:up, scene}, [])
      {:ok, scene}
    end

    @impl Scenic.Scene
    def handle_event(event, _from, %{assigns: %{pid: pid}} = scene) do
      send(pid, {:fwd_event, event})
      {:noreply, scene}
    end
  end

  setup do
    out = Scenic.Test.ViewPort.start({TestScene, {self(), @initial_value}})
    # wait for a signal that the scene is up before proceeding
    {:ok, scene} =
      receive do
        {:up, scene} -> {:ok, scene}
      end

    # make sure the button is up
    {:ok, [pid]} = Scene.child(scene, :text_field)
    :_pong_ = GenServer.call(pid, :_ping_)

    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    out
    |> Map.put(:scene, scene)
    |> Map.put(:pid, pid)
  end

  defp force_sync(vp_pid, scene_pid) do
    :_pong_ = GenServer.call(vp_pid, :_ping_)
    :_pong_ = GenServer.call(scene_pid, :_ping_)
    :_pong_ = GenServer.call(vp_pid, :_ping_)
  end

  test "press_in captures and starts editing", %{vp: vp, pid: pid} do
    assert Input.fetch_captures!(vp) == {:ok, []}
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)
    assert Input.fetch_captures!(vp) == {:ok, [:codepoint, :cursor_button, :key]}

    Input.send(vp, @cp_k)
    assert_receive({:fwd_event, {:value_changed, :text_field, "kInitial value"}}, 200)
  end

  test "press_out releases and ends editing", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)
    assert Input.fetch_captures!(vp) == {:ok, [:codepoint, :cursor_button, :key]}

    Input.send(vp, @press_out)
    force_sync(vp.pid, pid)
    assert Input.fetch_captures!(vp) == {:ok, []}

    Input.send(vp, @cp_k)
    refute_receive(_, 10)
  end

  test "pressing in the field moves the cursor to the nearst character gap", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)

    Input.send(vp, @cp_k)
    assert_receive({:fwd_event, {:value_changed, :text_field, "kInitial value"}}, 200)

    Input.send(vp, @press_move)
    Input.send(vp, @cp_l)
    assert_receive({:fwd_event, {:value_changed, :text_field, "kInlitial value"}}, 200)
  end

  test "right arrow moves the cursor to the right", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)

    Input.send(vp, @key_right)
    Input.send(vp, @cp_k)
    assert_receive({:fwd_event, {:value_changed, :text_field, "Iknitial value"}}, 200)
  end

  test "right arrow won't move past the end", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)

    Enum.each(1..20, fn _ -> Input.send(vp, @key_right) end)
    Input.send(vp, @cp_k)
    assert_receive({:fwd_event, {:value_changed, :text_field, "Initial valuek"}}, 200)
  end

  test "left arrow moves the cursor left", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)

    Enum.each(1..5, fn _ -> Input.send(vp, @key_right) end)
    Input.send(vp, @key_left)
    Input.send(vp, @cp_k)
    assert_receive({:fwd_event, {:value_changed, :text_field, "Initkial value"}}, 200)
  end

  test "left arrow won't move past the start", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)

    Enum.each(1..20, fn _ -> Input.send(vp, @key_left) end)
    Input.send(vp, @cp_k)
    assert_receive({:fwd_event, {:value_changed, :text_field, "kInitial value"}}, 200)
  end

  test "home and end move to the extends of the field", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)

    Input.send(vp, @key_end)
    Input.send(vp, @cp_k)
    Input.send(vp, @key_home)
    Input.send(vp, @cp_l)
    assert_receive({:fwd_event, {:value_changed, :text_field, "lInitial valuek"}}, 200)
  end

  test "page_up and page_down move to the extends of the field", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)

    Input.send(vp, @key_page_down)
    Input.send(vp, @cp_k)
    Input.send(vp, @key_page_up)
    Input.send(vp, @cp_l)
    assert_receive({:fwd_event, {:value_changed, :text_field, "lInitial valuek"}}, 200)
  end

  test "backspace removes characters backwards", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)

    Enum.each(1..5, fn _ -> Input.send(vp, @key_right) end)
    Input.send(vp, @key_backspace)
    assert_receive({:fwd_event, {:value_changed, :text_field, "Inital value"}}, 200)
  end

  test "backspace does nothing at the start of the string", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)

    Input.send(vp, @key_backspace)
    refute_receive(_, 10)
  end

  test "delete removes characters forwards", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)

    Input.send(vp, @key_delete)
    assert_receive({:fwd_event, {:value_changed, :text_field, "nitial value"}}, 200)
  end

  test "delete does nothing at the end of the field", %{vp: vp, pid: pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, pid)

    Input.send(vp, @key_end)
    Input.send(vp, @key_delete)
    refute_receive(_, 10)
  end

  test "filter :number works", %{vp: vp, scene: scene} do
    {:ok, [pid]} = Scene.child(scene, :number_field)
    :_pong_ = GenServer.call(pid, :_ping_)

    Input.send(vp, {:cursor_button, {0, :press, 0, {20, 60}}})
    force_sync(vp.pid, pid)

    Input.send(vp, {:codepoint, {"a", 0}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"1", 0}})
    assert_receive({:fwd_event, {:value_changed, :number_field, "1"}}, 200)
    Input.send(vp, {:codepoint, {"v", 0}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {".", 0}})
    assert_receive({:fwd_event, {:value_changed, :number_field, "1."}}, 200)
    Input.send(vp, {:codepoint, {"2", 0}})
    assert_receive({:fwd_event, {:value_changed, :number_field, "1.2"}}, 200)
  end

  test "filter :integer works", %{vp: vp, scene: scene} do
    {:ok, [pid]} = Scene.child(scene, :integer_field)
    :_pong_ = GenServer.call(pid, :_ping_)

    Input.send(vp, {:cursor_button, {0, :press, 0, {14, 86}}})
    force_sync(vp.pid, pid)

    Input.send(vp, {:codepoint, {"a", 0}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"1", 0}})
    assert_receive({:fwd_event, {:value_changed, :integer_field, "1"}}, 200)
    Input.send(vp, {:codepoint, {"v", 0}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {".", 0}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"2", 0}})
    assert_receive({:fwd_event, {:value_changed, :integer_field, "12"}}, 200)
  end

  test "filter \"abcdefg\" works", %{vp: vp, scene: scene} do
    {:ok, [pid]} = Scene.child(scene, :abcdefg_field)
    :_pong_ = GenServer.call(pid, :_ping_)

    Input.send(vp, {:cursor_button, {0, :press, 0, {14, 121}}})
    force_sync(vp.pid, pid)

    Input.send(vp, {:codepoint, {"a", 0}})
    assert_receive({:fwd_event, {:value_changed, :abcdefg_field, "a"}}, 200)
    Input.send(vp, {:codepoint, {"1", 0}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"v", 0}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"f", 0}})
    assert_receive({:fwd_event, {:value_changed, :abcdefg_field, "af"}}, 200)
  end

  test "filter fn works", %{vp: vp, scene: scene} do
    {:ok, [pid]} = Scene.child(scene, :fn_field)
    :_pong_ = GenServer.call(pid, :_ping_)

    Input.send(vp, {:cursor_button, {0, :press, 0, {14, 171}}})
    force_sync(vp.pid, pid)

    Input.send(vp, {:codepoint, {"a", 0}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"h", 0}})
    assert_receive({:fwd_event, {:value_changed, :fn_field, "h"}}, 200)
  end

  test "password field", %{vp: vp, scene: scene} do
    {:ok, [pid]} = Scene.child(scene, :password_field)
    :_pong_ = GenServer.call(pid, :_ping_)

    Input.send(vp, {:cursor_button, {0, :press, 0, {14, 214}}})
    force_sync(vp.pid, pid)

    Input.send(vp, {:codepoint, {"a", 0}})
    assert_receive({:fwd_event, {:value_changed, :password_field, "a"}}, 200)
    Input.send(vp, {:codepoint, {"2", 0}})
    assert_receive({:fwd_event, {:value_changed, :password_field, "a2"}}, 200)
  end

  test "ignores non-main button clicks", %{vp: vp} do
    Input.send(vp, {:cursor_button, {1, :press, 0, {14, 10}}})
    Input.send(vp, {:cursor_button, {2, :press, 0, {14, 10}}})
    refute_receive(_, 10)
  end

  test "implements get/put", %{scene: scene} do
    assert Scene.get_child(scene, :text_field) == ["Initial value"]
    assert Scene.put_child(scene, :text_field, "updated") == :ok
    assert Scene.get_child(scene, :text_field) == ["updated"]
  end

  test "implements fetch/update", %{scene: scene} do
    assert Scene.fetch_child(scene, :text_field) == {:ok, ["Initial value"]}
    %Scene{} = scene = Scene.update_child(scene, :text_field, "updated")
    assert Scene.fetch_child(scene, :text_field) == {:ok, ["updated"]}
    assert Scene.get_child(scene, :text_field) == ["updated"]
  end
end
