defmodule Scenic.Test.ViewPort do
  alias Scenic.ViewPort

  @viewports :scenic_viewports

  defmodule DefaultScene do
    use Scenic.Scene

    def init(scene, _args, _opts) do
      {:ok, scene}
    end
  end

  def start(scene \\ DefaultScene) do
    supervisor =
      case DynamicSupervisor.start_link(name: @viewports, strategy: :one_for_one) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    {:ok, %ViewPort{} = vp} =
      ViewPort.start(
        size: {700, 600},
        opts: [font: :roboto, font_size: 30],
        default_scene: scene
      )

    scene_state = %{
      theme: :dark,
      has_children: true,
      name: nil,
      module: __MODULE__,
      parent: self(),
      viewport: vp,
      root_sup: supervisor,
      stop_pid: self(),
      children: %{},
      child_supervisor: supervisor
    }

    Process.put(:scene_state, scene_state)

    %{supervisor: supervisor, vp: vp}
  end
end
