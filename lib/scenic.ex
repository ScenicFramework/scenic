defmodule Scenic do
  @moduledoc """

  Scenic is an application framework written directly on the Elixir/Erlang/OTP stack.
  With it you can build client-side applications that operate identically across all
  supported operating systems, including MacOS, Ubuntu, Nerves/Linux, and more.

  ## Helpful Guides

    * [Getting Started](getting_started.html)
    * [Overview of a Scene](overview_scene.html)
    * [Overview of a ViewPort](overview_viewport.html)
    * [Overview of a Driver](overview_driver.html)


  ## Goals
  
  Scenic's design attempts to meet multiple important goals. In general, it is about
  bringing the highly-available world of OTP to client applications.

  goal | description
  --- | ---
  **Available** | Scenic takes full advantage of OTP supervision trees to create applications that are fault-tolerant, self-healing, and highly available under adverse conditions.
  **Small and Fast** | The only core dependencies are Erlang/OTP and OpenGL.
  **Self Contained** | “Never trust a device if you don’t know where it keeps its brain.” The logic to run a device should be on the device and it should remain operational even if the service it talks to becomes unavailable.
  **Maintainable** | Each device knows how to run itself. This lets teams focus on new products and only updating the old ones as the business needs.
  **Remotable** | Scenic devices know how to run themselves, but can still be accessed remotely. Remote traffic attempts to be as small so it can be used over the internet, cellular modems, bluetooth, etc.
  **Reusable** | Collections of UI can be packaged up for reuse with, and across applications. I expect to see Hex packages of controls, graphs, and more available for Scenic applications.
  **Flexible** | Scenic uses matrices similar to game development  to position everything. This makes reuse, scale, positioning and more very flexible and simple.
  **Secure** | Scenic is designed with an eye towards security. For now, the main effort is to keep it simple. No browser, javascript and other complexity presenting vulnerabilities. There will be much more to say about security later.


  ## Non-Goals

  !goal | description
  --- | ---
  **Browser** | Scenic is **not** a web browser. It is aimed at fixed screen devices and certain types of windowed apps. It knows nothing about HTML.
  **3D** | Scenic is a 2D UI framework. It uses techniques from game development (such as transform matrices), but it does not support 3D drawing at this time.
  **Immediate Mode** | In graphics speak, Scenic is a retained mode system. If you need immediate mode, then Scenic isn’t for you. If you don’t know what retained and immediate modes are, then you are probably just fine. For reference: HTML is a retained mode model.


  ## Architecture

  Scenic is built as a three-layer architectural cake.

  At the top is the **Scene Layer**, which encapsulates all application business logic. The developer will do most of their Scenic work in the Scene layer.

  At the bottom is the **Driver layer**, which is where knowledge of the graphics hardware and/or remote configuration lives. Drivers draw everything on the screen and originate the raw user input. Developers can write their own drivers, but that will be rare if at all. Dealing with Sensors and other hardware is a different problem space.

  In the middle is the **ViewPort Layer**, which acts as bridge between the Scenes and the Drivers. The ViewPort controls the scene lifecycle (More on that in [Scene Overview](overview_scene.html)), sends graphs down to the drivers, and routes user input up to the correct scene.

  ## Mental Model

  Scenic is definitely not a browser and has nothing to do with HTML. However, its design attempts to draw analogies to web design so that a developer with experience building web pages will catch on very quickly.

  The following terms include HTML analogies as appropriate…

  ## Terms and Definitions

  Term | Definition
  --- | ---
  **Scene** | Scenes are sort of like a web page. Each scene is a GenServer process that contains state and business logic to handle user input. As the device navigates to different screens, it is moving between scenes.
  **Graph** | A Graph is sort of like the DOM. It is a hierarchical set of data that describes things to draw on the screen. The Graph is immutable in the functional coding sense and is manipulated through transform functions.
  **Primitive** | Each node in a Graph is a Primitive. There is relatively small, fixed set of primitives, but they can be combined to draw pretty much any UI you need.
  **Component** | A component is a Scene, with added sugar so that it can be referenced/used by other Scenes. This allows you to build libraries of reusable components and isolates logic into sensible containers. Standard controls such as Button, RadioGroup, Slider and more are written as components. 
  **Style** | Styles are sort of analogous to CSS styles. Styles are optional parameters you can add to any primitive in a graph. They are inherited down the graph.
  **Transform** | All positioning, rotation, scale and such is expressed by applying transform matrices to nodes in a Graph. Transforms are inherited down the graph. You will almost never interact directly with the matrices, as there are very easy helpers that manage them for you.
  **ViewPort** | A ViewPort is sort of like a tab in your browser. It manages the scene lifecycle, routes graphs to the drivers, and input back up to the scenes. If you want two windows in your app, you need to start two ViewPorts.
  **Driver** | Drivers know nothing about scenes, but are able to render Graphs to a specific device. That could be a graphics chip, or the network… Drivers also collect raw user input and route it back up to the ViewPort.
  **Input** | There is a fixed set of user input data (mouse, keyboard, touch, etc…) that drivers generate and hand up to the ViewPort. The ViewPort in turn sends the input as a message to the appropriate Scene. Scene’s handle raw user input via the `handle_input/3` callback.
  **Event** | In response to user input (or timers or any other message), a component can generate an event that it sends up to its parent scene. Unlike user input, if the parent doesn’t handle it, it is passed up again to that component’s parent until it reaches the root scene. Scenes handle events that are bubbling up the chain via the `filter_event/3` callback. This is analogous to event bubbling on a web page.

  # What to read next

  If you are new to Scenic, you should read and follow the exercise in [Getting Started](getting_started.html).

  If you want to dig deeper into the lifecycle of a Scene, then read the [Scene Overview](overview_scene.html).
  """







  use Supervisor

  @viewports :scenic_dyn_viewports

  #--------------------------------------------------------
  @doc false
  def child_spec(opts) do
    %{
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end


  #--------------------------------------------------------
  @doc false
  def start_link( opts \\ [] )
  def start_link( {a,b} ), do: start_link( [{a,b}] )
  def start_link( opts ) when is_list(opts) do
    Supervisor.start_link(__MODULE__, opts, name: :scenic)
  end

  #--------------------------------------------------------
  @doc false
  def init( opts ) do
    opts
    |> Keyword.get( :viewports, [] )
    |> do_init
  end

  #--------------------------------------------------------
  # init with no default viewports
  defp do_init( [] ) do
    [
      {Scenic.ViewPort.Tables, nil},
      supervisor(Scenic.Cache.Supervisor, []),
      {DynamicSupervisor, name: @viewports, strategy: :one_for_one}
    ]
    |> Supervisor.init( strategy: :one_for_one )
  end

  #--------------------------------------------------------
  # init with default viewports
  defp do_init( viewports ) do
    [
      {Scenic.ViewPort.Tables, nil},
      supervisor(Scenic.Cache.Supervisor, []),
      supervisor(Scenic.ViewPort.SupervisorTop, [viewports]),
      {DynamicSupervisor, name: @viewports, strategy: :one_for_one}
    ]
    |> Supervisor.init( strategy: :one_for_one )
  end


end
