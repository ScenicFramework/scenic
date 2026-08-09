# ViewPort Overview

The ViewPort is the central orchestrator in Scenic's architecture. It acts as a liaison between the application logic (Scenes) and the rendering/input systems (Drivers), coordinating the flow of information while keeping these layers completely decoupled.

## Core Responsibilities

### 1. Script Management
The ViewPort owns and manages ETS tables that store compiled scripts. When scenes push graphs, the ViewPort:
- Compiles graphs into optimized scripts using `Scenic.Graph.Compiler`
- Stores scripts in public ETS tables for concurrent access by drivers
- Notifies drivers when scripts are updated or deleted
- Manages script lifecycle and cleanup

### 2. Input Processing and Routing
The ViewPort handles all user input from drivers and routes it to appropriate scenes:
- **Positional Input**: Clicks, scrolls, cursor movement - requires hit testing through the scene hierarchy
- **Non-Positional Input**: Key presses, window events - routed to root or capturing scenes
- **Input Capture**: Allows scenes to capture input types temporarily (e.g., drag operations)
- **Transform Projection**: Converts global coordinates to local scene coordinates

### 3. Scene Lifecycle Management
- Monitors scene processes and cleans up on crashes
- Manages scene hierarchy and parent-child relationships
- Tracks scene transforms for coordinate space conversions
- Handles scene startup coordination with gate mechanisms

### 4. Driver Coordination
- Manages multiple drivers running simultaneously
- Broadcasts script updates to all connected drivers
- Communicates input requirements and theme changes
- Provides driver lifecycle management

## Architecture Patterns

### Script Compilation Pipeline
```
Scene Graph → Graph Compiler → Script → ETS Table → Driver
```

1. Scene creates/modifies a graph
2. Scene calls `push_graph` 
3. ViewPort compiles graph to script via `Scenic.Graph.Compiler`
4. Script stored in ETS table with change detection
5. Drivers notified of script updates
6. Drivers read scripts and render

### Input Processing Pipeline  
```
Driver Input → ViewPort → Hit Testing → Scene Routing → Event Delivery
```

1. Driver captures raw input (mouse, keyboard, etc.)
2. ViewPort receives input and determines type
3. For positional input: hit testing against scene hierarchy
4. Transform coordinates to target scene's local space
5. Route to appropriate scene(s) based on capture/request state

### The ETS Table Strategy
The ViewPort uses public ETS tables to achieve high-performance concurrent access:
- **Script Table**: `[:public, {:read_concurrency, true}]` - Multiple drivers can read simultaneously
- Scenes write compiled scripts directly to avoid serializing through ViewPort
- Change detection prevents unnecessary driver notifications
- Ownership tracked for cleanup when processes crash

## Key Concepts

### Transform Hierarchy
The ViewPort maintains a transform hierarchy that mirrors the scene structure:
- Each scene has a cumulative transform from root to local space
- Coordinate projection uses matrix operations for precision
- Enables complex nested UI layouts with proper input handling

### Input Capture vs Request
- **Input Request**: Normal operation - scenes register interest in input types
- **Input Capture**: Temporary override - one scene captures all input of a type
- Used for drag operations, modal dialogs, or focus management

### Gating Mechanism
The ViewPort can "gate" drivers during scene transitions:
- Prevents flickering during complex scene startup
- Coordinates when multiple scenes are initializing
- Signals completion when scene hierarchy is stable

## Performance Characteristics

### Concurrent Script Access
- Multiple drivers read the same scripts simultaneously
- No serialization bottleneck at ViewPort
- Scripts are immutable once compiled

### Change Detection
- Scripts only sent to drivers when actually changed
- Reduces network traffic for remote drivers
- Enables efficient update batching

### Input Rate Limiting
- Optional input rate limiting prevents overwhelming scenes
- Configurable per-driver for different hardware capabilities
- Buffers and batches high-frequency input like mouse movement

## Error Handling and Recovery

### Process Monitoring
- ViewPort monitors all scene and driver processes
- Automatic cleanup of scripts and state on process crash
- Maintains system integrity even with buggy scenes

### Graceful Degradation
- ViewPort continues operating with partial driver failures
- Scene crashes don't affect other scenes or drivers
- Input routing adapts to scene hierarchy changes

## Related Documentation

- [Driver Overview](overview_driver.html) - How drivers interact with ViewPort
- [Scene Structure](overview_scene.html) - How scenes use ViewPort services  
- [Script Overview](overview_scripts.html) - The rendering data structure
- [Input Handling](overview_input.html) - Detailed input processing

## Example: Simple ViewPort Setup

```elixir
# Start a ViewPort
{:ok, viewport} = Scenic.ViewPort.start([
  name: :main_viewport,
  size: {800, 600},
  default_scene: MyApp.MainScene,
  drivers: [
    [module: Scenic.Driver.Local, window: [title: "My App"]]
  ]
])

# Scene pushes a graph
scene = push_graph(scene, my_graph)  # Compiles to script, stores in ETS

# Driver automatically receives script update and renders

# User clicks - driver sends input to ViewPort
# ViewPort performs hit testing and routes to correct scene
```

The ViewPort's design achieves Scenic's goals of high performance, fault tolerance, and clean architectural separation while handling the complex coordination required for real-time GUI applications.
