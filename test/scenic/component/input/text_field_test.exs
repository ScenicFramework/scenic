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

  @press_in {:cursor_button, {:btn_left, 1, [], {14, 10}}}
  @press_move {:cursor_button, {:btn_left, 1, [], {43, 10}}}
  @press_out {:cursor_button, {:btn_left, 1, [], {1000, 1000}}}

  @cp_k {:codepoint, {"k", []}}
  @cp_l {:codepoint, {"l", []}}

  @key_right {:key, {:key_right, 1, []}}
  @key_left {:key, {:key_left, 1, []}}
  @key_page_up {:key, {:key_pageup, 1, []}}
  @key_page_down {:key, {:key_pagedown, 1, []}}
  @key_home {:key, {:key_home, 1, []}}
  @key_end {:key, {:key_end, 1, []}}
  @key_backspace {:key, {:key_backspace, 1, []}}
  @key_delete {:key, {:key_delete, 1, []}}

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

    Input.send(vp, {:cursor_button, {:btn_left, 1, [], {20, 60}}})
    force_sync(vp.pid, pid)

    Input.send(vp, {:codepoint, {"a", []}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"1", []}})
    assert_receive({:fwd_event, {:value_changed, :number_field, "1"}}, 200)
    Input.send(vp, {:codepoint, {"v", []}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {".", []}})
    assert_receive({:fwd_event, {:value_changed, :number_field, "1."}}, 200)
    Input.send(vp, {:codepoint, {"2", []}})
    assert_receive({:fwd_event, {:value_changed, :number_field, "1.2"}}, 200)
  end

  test "filter :integer works", %{vp: vp, scene: scene} do
    {:ok, [pid]} = Scene.child(scene, :integer_field)
    :_pong_ = GenServer.call(pid, :_ping_)

    Input.send(vp, {:cursor_button, {:btn_left, 1, [], {14, 86}}})
    force_sync(vp.pid, pid)

    Input.send(vp, {:codepoint, {"a", []}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"1", []}})
    assert_receive({:fwd_event, {:value_changed, :integer_field, "1"}}, 200)
    Input.send(vp, {:codepoint, {"v", []}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {".", []}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"2", []}})
    assert_receive({:fwd_event, {:value_changed, :integer_field, "12"}}, 200)
  end

  test "filter \"abcdefg\" works", %{vp: vp, scene: scene} do
    {:ok, [pid]} = Scene.child(scene, :abcdefg_field)
    :_pong_ = GenServer.call(pid, :_ping_)

    Input.send(vp, {:cursor_button, {:btn_left, 1, [], {14, 121}}})
    force_sync(vp.pid, pid)

    Input.send(vp, {:codepoint, {"a", []}})
    assert_receive({:fwd_event, {:value_changed, :abcdefg_field, "a"}}, 200)
    Input.send(vp, {:codepoint, {"1", []}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"v", []}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"f", []}})
    assert_receive({:fwd_event, {:value_changed, :abcdefg_field, "af"}}, 200)
  end

  test "filter fn works", %{vp: vp, scene: scene} do
    {:ok, [pid]} = Scene.child(scene, :fn_field)
    :_pong_ = GenServer.call(pid, :_ping_)

    Input.send(vp, {:cursor_button, {:btn_left, 1, [], {14, 171}}})
    force_sync(vp.pid, pid)

    Input.send(vp, {:codepoint, {"a", []}})
    refute_receive(_, 10)
    Input.send(vp, {:codepoint, {"h", []}})
    assert_receive({:fwd_event, {:value_changed, :fn_field, "h"}}, 200)
  end

  test "password field", %{vp: vp, scene: scene} do
    {:ok, [pid]} = Scene.child(scene, :password_field)
    :_pong_ = GenServer.call(pid, :_ping_)

    Input.send(vp, {:cursor_button, {:btn_left, 1, [], {14, 214}}})
    force_sync(vp.pid, pid)

    Input.send(vp, {:codepoint, {"a", []}})
    assert_receive({:fwd_event, {:value_changed, :password_field, "a"}}, 200)
    Input.send(vp, {:codepoint, {"2", []}})
    assert_receive({:fwd_event, {:value_changed, :password_field, "a2"}}, 200)
  end

  test "ignores non-main button clicks", %{vp: vp} do
    Input.send(vp, {:cursor_button, {:btn_right, 1, [], {14, 10}}})
    Input.send(vp, {:cursor_button, {:btn_middle, 1, [], {14, 10}}})
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

  test "bounds works with defaults" do
    graph =
      Graph.build()
      |> Scenic.Components.text_field("Test Field")

    {0.0, 0.0, 288.0, 30.0} = Graph.bounds(graph)
  end

  test "bounds works with overrides" do
    graph =
      Graph.build()
      |> Scenic.Components.text_field("Test Field", width: 300, height: 40)

    {0.0, 0.0, 300.0, 40.0} = Graph.bounds(graph)
  end
end
