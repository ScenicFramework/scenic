defmodule Scenic.Component.CustomMessageTest do
  use ExUnit.Case

  setup do
    ast =
      quote do
        use Scenic.Component, name: C

        @graph Scenic.Graph.build()

        @impl Scenic.Scene
        def handle_info({:ping, pid}, state) do
          send(pid, :pong)
          {:noreply, state}
        end

        @impl Scenic.Scene
        def handle_info({:DOWN, _, :process, _, _}, state),
          do: {:noreply, state}

        @impl Scenic.Scene
        def init(_args, _opts \\ []) do
          graph = @graph

          state = %{
            graph: graph
          }

          {:ok, state, push: graph}
        end

        @impl Scenic.Component
        def verify(data), do: {:ok, data}
      end

    {:module, component, _, _} = Module.create(C, ast, Macro.Env.location(__ENV__))

    on_exit(fn ->
      :code.purge(C)
      :code.delete(C)
    end)

    [component: component]
  end

  test "send message to named component", %{component: component} do
    {:ok, sup} = Supervisor.start_link([{C, {[], []}}], strategy: :one_for_one)

    send(component, {:ping, self()})
    assert_receive(:pong, 200)
    Supervisor.stop(sup)
  end
end
