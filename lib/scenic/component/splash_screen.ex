defmodule Scenic.SplashScreen do
  use Scenic.Scene, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort

  import IEx


  @splash_interval  32

  @default_min_time  1000

  @graph Graph.build( clear_color: :black, font: {:roboto, 20} )
    |> Primitive.Text.add_to_graph( {{40, 80}, "Welcome to Scenic"}, id: :text, color: :white )


  #--------------------------------------------------------
  def init( {initial_scene, args, opts} ) do
    {:ok, timer} = :timer.send_interval(@splash_interval, :splash_interval)

    state = %{
      graph: @graph,
      animations: @animations,
      timer: timer,
      start_time: :os.system_time(:milli_seconds),
      min_time: opts[:splash_time] || @default_min_time,
      initial_scene: initial_scene,
      initial_scene_args: args
    }

    push_graph( @graph )

    {:ok, state}
  end

  #--------------------------------------------------------
#  def handle_set_root(_vp, _args, %{graph: graph} = state ) do
#    {:noreply, state }
#  end

  #--------------------------------------------------------
  def handle_lose_root(_, %{timer: timer} = state ) do
    # stop the animation timer
    if timer, do: :timer.cancel(timer)
    {:noreply, %{state | timer: nil} }
  end


  #--------------------------------------------------------
  def handle_info( :splash_interval, %{
    start_time: start_time,
    min_time: min_time,
    initial_scene: initial_scene,
    initial_scene_args: args,
    timer: timer
  } = state ) do
    
    # if the minimum time has gone by, see if the target scene is running
    elapsed_time = :os.system_time(:milli_seconds) - start_time

    state = if elapsed_time >= min_time do
      case initial_scene do
        {mod, init_data} ->
          # dynamic scene. Can just start it up
          ViewPort.set_root( {mod, init_data}, args )

        name when is_atom(name) ->
          if Process.whereis(name) do
#            ViewPort.set_root( name, args )
          end
      end

      :timer.cancel(timer)
      %{state | timer: nil}
    else 
      state
    end

    {:noreply, state }
#    {:noreply, %{state | graph: graph} }
  end

end










