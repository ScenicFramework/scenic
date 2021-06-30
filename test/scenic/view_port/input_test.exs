#
#  Created by Boyd Multerer on 2021-02-07.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.ViewPort.InputTest do
  use ExUnit.Case, async: false
  doctest Scenic.ViewPort.Input

  alias Scenic.ViewPort
  alias Scenic.ViewPort.Input

  # import IEx

  defmodule TestInputScene do
    use Scenic.Scene
    def init(scene, pid, _) do
      Process.send( pid, {:test_up, scene}, [] )
      {:ok, assign(scene, :pid, pid) }
    end

    def handle_call( :ping, _from, scene ) do
      {:reply, :pong, scene}
    end
  end


  setup do
    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    # start and return the test ViewPort
    out = Scenic.Test.ViewPort.start({TestInputScene, self()})

    # wait for a signal that the scene is up before proceeding
    {:ok, scene} = receive do {:test_up, scene} -> {:ok, scene} end

    Map.put(out, :scene, scene)
  end


  test "Test that capture/release/list_captures work", %{vp: vp} do
    assert Input.fetch_captures(vp) == { :ok, [] }

    :ok = Input.capture(vp, :cursor_pos )
    assert Input.fetch_captures(vp) == { :ok, [:cursor_pos] }

    :ok = Input.capture(vp, [:key, :codepoint] )
    assert Input.fetch_captures(vp) == { :ok, [:key, :cursor_pos, :codepoint] }

    :ok = Input.release(vp, :key )
    assert Input.fetch_captures(vp) == { :ok, [:cursor_pos, :codepoint] }

    :ok = Input.release(vp, :all )
    assert Input.fetch_captures(vp) == { :ok, [] }
  end

  test "list_captures and list_captures! work", %{vp: vp} do
    assert Input.fetch_captures(vp) == { :ok, [] }
    assert Input.fetch_captures!(vp) == { :ok, [] }

    Agent.start(fn ->
      :ok = Input.capture(vp, [:codepoint] )
    end)

    assert Input.fetch_captures(vp) == { :ok, [] }
    assert Input.fetch_captures!(vp) == { :ok, [:codepoint] }

    :ok = Input.capture(vp, :cursor_pos )
    assert Input.fetch_captures(vp) == { :ok, [:cursor_pos] }
    assert Input.fetch_captures!(vp) == { :ok, [:codepoint, :cursor_pos] }
  end


  test "captures are cleaned up when the owning process stops", %{vp: vp} do
    # set up a capture
    :ok = Input.capture(vp, [:codepoint] )
    assert Input.fetch_captures!(vp) == { :ok, [:codepoint] }

    # fake indicate this process went down
    Process.send( vp.pid, {:DOWN, make_ref(), :process, self(), :test}, [] )

    assert Input.fetch_captures!(vp) == { :ok, [] }
  end

  test "Test that request/unrequest/list_requests work", %{vp: vp} do
    assert Input.fetch_requests(vp) == { :ok, [] }

    :ok = Input.request(vp, :cursor_pos )
    assert Input.fetch_requests(vp) == { :ok, [:cursor_pos] }

    :ok = Input.request(vp, [:key, :codepoint] )
    assert Input.fetch_requests(vp) == { :ok, [:key, :cursor_pos, :codepoint] }

    :ok = Input.unrequest(vp, :key )
    assert Input.fetch_requests(vp) == { :ok, [:cursor_pos, :codepoint] }

    :ok = Input.unrequest(vp, :all )
    assert Input.fetch_requests(vp) == { :ok, [] }
  end

  test "fetch_requests and fetch_requests! work", %{vp: vp} do
    assert Input.fetch_requests(vp) == { :ok, [] }
    assert Input.fetch_requests!(vp) == { :ok, [:cursor_button] }

    Agent.start(fn ->
      :ok = Input.request(vp, [:codepoint] )
    end)
    assert Input.fetch_captures(vp) == { :ok, [] }
    assert Input.fetch_requests!(vp) == { :ok, [:codepoint, :cursor_button] }

    :ok = Input.request(vp, :cursor_pos )
    assert Input.fetch_requests(vp) == { :ok, [:cursor_pos] }
    assert Input.fetch_requests!(vp) == { :ok, [:codepoint, :cursor_button, :cursor_pos] }
  end

  test "requests are cleaned up with the owning process stops", %{vp: vp, scene: scene} do
    :ok = Input.request(vp, :cursor_pos )
    assert Input.fetch_requests!(vp) == { :ok, [:cursor_button, :cursor_pos] }
    Scenic.Scene.stop( scene )
    assert Input.fetch_requests!(vp) == { :ok, [:cursor_pos] }
  end


  #----------------
  # drivers are sent input updates

  test "drivers are sent requested input updates", %{vp: vp} do
    assert Input.fetch_requests!(vp) == { :ok, [:cursor_button] }
    
    GenServer.cast(vp.pid, {:register_driver, self()})
    assert_receive( {:"$gen_cast", {:request_input, [:cursor_button]}}, 100 )

    # should NOT get an update when the same thing is requested again
    :ok = Input.request(vp, :cursor_button )
    refute_receive( {:"$gen_cast", {:request_input, _}}, 20 )

    # should get an update when something new is requested
    :ok = Input.request(vp, :cursor_pos )
    assert_receive( {:"$gen_cast", {:request_input, [:cursor_button, :cursor_pos]}}, 100 )

    # should get an update when something is removed
    :ok = Input.unrequest(vp, :cursor_pos )
    assert_receive( {:"$gen_cast", {:request_input, [:cursor_button]}}, 100 )
  end

  test "drivers are sent requested input updates when a scene goes down", %{vp: vp, scene: scene} do
    assert Input.fetch_requests!(vp) == { :ok, [:cursor_button] }

    GenServer.cast(vp.pid, {:register_driver, self()})
    assert_receive( {:"$gen_cast", {:request_input, [:cursor_button]}}, 100 )

    Scenic.Scene.stop( scene )

    # should get an update the owning scene goes down
    assert_receive( {:"$gen_cast", {:request_input, []}}, 100 )
  end


  test "drivers are sent captured input updates", %{vp: vp} do
    assert Input.fetch_captures!(vp) == { :ok, [] }
    assert Input.fetch_requests!(vp) == { :ok, [:cursor_button] }
    
    GenServer.cast(vp.pid, {:register_driver, self()})
    assert_receive( {:"$gen_cast", {:request_input, [:cursor_button]}}, 100 )

    # should NOT get an update when the same thing is captured
    :ok = Input.capture(vp, :cursor_button )
    refute_receive( {:"$gen_cast", {:request_input, _}}, 20 )

    # should get an update when something new is requested
    :ok = Input.capture(vp, :cursor_pos )
    assert_receive( {:"$gen_cast", {:request_input, [:cursor_button, :cursor_pos]}}, 100 )

    # should get an update when something is removed
    :ok = Input.release(vp, :all )
    assert_receive( {:"$gen_cast", {:request_input, [:cursor_button]}}, 100 )
  end

  test "drivers are sent captured input updates when a scene goes down", %{vp: vp} do
    assert Input.fetch_requests!(vp) == { :ok, [:cursor_button] }
    self = self()
    # have to have an agent do the capture so that it comes from a different pid than this
    # test, which is pretending to be a driver...
    {:ok, agent} = Agent.start(fn ->
      GenServer.cast(vp.pid, {:register_scene, self(), :agent, nil})
      :ok = Input.capture(vp, :cursor_pos )
      send( self, :sync )
    end)
    receive do :sync -> :ok end
    GenServer.call(vp.pid, :_ping_)

    GenServer.cast(vp.pid, {:register_driver, self()})
    assert_receive( {:"$gen_cast", {:request_input, [:cursor_button, :cursor_pos]}}, 100 )

    # stop the agent
    Agent.stop( agent )

    # should get an update when the owning pid goes down
    # calling fetch_requests! makes sure the vp has processed the agent DOWN message
    assert Input.fetch_requests!(vp) == { :ok, [:cursor_button] }
    assert_receive( {:"$gen_cast", {:request_input, [:cursor_button]}}, 100 )
  end



  #----------------
  # actual input is routed to listeners

  @codepoint {:codepoint, {"k", 0}}

  test "receives requested input", %{vp: vp} do
    :ok = Input.request(vp, :codepoint )
    :ok = Input.send(vp, @codepoint )
    assert_receive( {:_input, @codepoint, @codepoint, nil}, 100 )
  end

  test "receives continued input", %{vp: vp} do
    :ok = Input.request(vp, :codepoint )
    GenServer.cast( vp.pid, {:continue_input, @codepoint} )
    assert_receive( {:_input, @codepoint, @codepoint, nil}, 100 )
  end

  test "ViewPort.input equivalent to ViewPort.Input.send", %{vp: vp} do
    :ok = Input.request(vp, :codepoint )
    :ok = ViewPort.input(vp, @codepoint )
    assert_receive( {:_input, @codepoint, @codepoint, nil}, 100 )
  end

end