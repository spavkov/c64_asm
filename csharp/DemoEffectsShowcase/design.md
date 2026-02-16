# Demo Scene Effects Showcase - Design Document

## 1. Purpose
Build a desktop program in **C#** using **SDL** to showcase classic demo scene effects inspired by Commodore, Amiga, and similar retro platforms.  
The UI has:
- **Left panel:** searchable list of available effects
- **Right panel:** real-time rendering of the selected effect

## 2. Goals
- Provide a smooth, simple explorer for many demo effects.
- Make each effect pluggable through a shared interface.
- Keep rendering architecture stable so effects can be added independently.
- Support continuous animation at a target frame rate (e.g., 60 FPS).

## 3. Non-Goals (initial version)
- Full emulation of original hardware timing/chipset behavior.
- Audio playback/synchronization.
- In-app effect editor.
- Network features.

## 4. Technology Stack
- **Language:** C# (.NET 8+ recommended)
- **Project type:** Desktop app
- **Runtime**: .NET Core (latest stable LTS target)
- **Graphics/Input/Windowing**: SDL library (SDL2 via SDL2-CS bindings)
- **Rendering rule**: all visual effects render through SDL renderer APIs (`SDL_Render*`)
- **UI**: left-side controls are rendered by app UI layer; effect code must not use UI drawing APIs


### 4.1 Native Runtime Dependency (Important)
- `SDL2-CS` is a managed wrapper and still requires native `SDL2.dll` at runtime.
- The app target should be **x64** and `SDL2.dll` must be present in the output folder next to the executable.
- Recommended packaging/build approach:
  - Add a native SDL redist NuGet package.
  - Copy `SDL2.dll` from package path to `bin\<configuration>\<target-framework>\`.
- If startup fails with `Unable to load DLL 'SDL2.dll'`, treat it as a deployment/runtime dependency issue first (not effect/render logic).
- On Windows, ensure Visual C++ runtime prerequisites for the shipped SDL2 binary are available.

## 5. High-Level Architecture

### 5.1 Core Components
1. **Application Host**
   - Initializes SDL, window, renderer, and main loop.
   - Coordinates UI and selected effect lifecycle.

2. **Effect Registry**
   - Holds all available `DemoSceneEffect` implementations.
   - Provides metadata for list/search (name, category, tags, description).

3. **UI Layer**
   - Left searchable list and selection state.
   - Right render viewport.
   - Keyboard/mouse navigation handling.

4. **Render Loop**
   - Poll input events.
   - Update selected effect timing/state.
   - Render current frame.
   - Present frame via SDL.

5. **Effect Implementations**
   - Independent classes implementing `DemoSceneEffect`.
   - Produce one animation frame per render cycle.

## 6. Interface Design

Each visual effect must implement `DemoSceneEffect`.

```csharp
public interface DemoSceneEffect
{
    string Id { get; }
    string Name { get; }
    string Description { get; }
    IReadOnlyList<string> Tags { get; }

    void Initialize(in EffectInitContext context);
    void Resize(int width, int height);
    void Update(double deltaSeconds);

    // Renders one frame for this effect.
    // renderer is the SDL renderer/screen target pointer.
    void Render(IntPtr renderer);

    // Optional per-effect UI controls for runtime tuning.
    IReadOnlyList<EffectParameterDefinition> GetParameters();

    void Dispose();
}
```

### Notes
- `Render(IntPtr renderer)` maps to SDL render target usage and is called once per frame.
- Effects must draw only into the provided SDL renderer/viewport.
- `Update(deltaSeconds)` keeps animation speed time-based, not frame-based.
- `Initialize` allows precomputed tables/textures/buffers.
- `Resize` handles right-panel viewport size changes.
- `GetParameters()` exposes effect-specific configurable values to GUI.

### 6.1 Effect Parameter Abstraction
- Use a shared `EffectParameterDefinition` model (key, label, kind, min/max, getter/setter delegates).
- Supported parameter kinds in current implementation:
  - `Float` (rendered as slider)
  - `Color3` (rendered as RGB color picker)
- `EffectParameters` helper factory methods (`Float`, `Color3`) reduce per-effect boilerplate.
- App UI renders controls generically by iterating `selectedEffect.GetParameters()`.

## 7. UI/UX Design

## 7.1 Layout
- **Left panel (fixed width):**
  - Search textbox at top
  - Scrollable list of effects below
- **Right panel (remaining width):**
  - Active effect viewport
  - Optional small overlay (effect name, FPS)

## 7.2 Interaction
- Typing filters list by name/tags/description.
- Arrow keys or mouse select effect.
- Enter/click activates effect.
- Switching effects disposes previous effect resources, initializes new one.
- Left panel includes **Effect Controls** section for the currently selected effect.
- Control changes apply immediately and affect next rendered frames.
- Left panel controls are application UI concerns; right panel visuals are SDL effect rendering concerns.

## 8. Data Model

```csharp
public sealed class EffectDescriptor
{
    public required string Id { get; init; }
    public required string Name { get; init; }
    public string Description { get; init; } = "";
    public string Category { get; init; } = "General";
    public IReadOnlyList<string> Tags { get; init; } = Array.Empty<string>();
    public Func<DemoSceneEffect> Factory { get; init; } = default!;
}
```

Registry stores `EffectDescriptor` objects and builds `DemoSceneEffect` instances on demand.

## 9. Rendering and Timing
- Main loop uses SDL event polling and frame presentation.
- Use high-resolution timer for `deltaSeconds`.
- Clear and render:
  1. UI background/panels
  2. Right viewport effect frame (`selectedEffect.Render(rendererPtr)`)
  3. UI overlays/list text
- Optionally cap frame rate (e.g., VSync or fixed delay fallback).

## 10. Resource Management
- Effects own their textures/buffers and free them in `Dispose`.
- On effect switch:
  1. `currentEffect.Dispose()`
  2. `newEffect = descriptor.Factory()`
  3. `newEffect.Initialize(context)`
- On app exit: dispose active effect, then destroy SDL resources in reverse init order.

## 11. Suggested Folder Structure

```text
src/
  App/
    Program.cs
    DemoShowcaseApp.cs
  Core/
    DemoSceneEffect.cs
    EffectDescriptor.cs
    EffectRegistry.cs
    EffectInitContext.cs
  UI/
    SearchBox.cs
    EffectListView.cs
    LayoutState.cs
  Effects/
    PlasmaEffect.cs
    CopperBarsEffect.cs
    StarfieldEffect.cs
```

## 12. Initial Effect Backlog (examples)
- Plasma
- Copper bars
- Starfield
- Tunnel
- donut
- image textured donut
- Rotozoom
- Fire effect
- twister effect with texture
- wireframe cube
- glenz vectors cube
- textured cube
- cube with plasma on one side
- meatballs 
- vectorballs
- Sine scroller
- Cube twister (https://www.4rknova.com/blog/2020/04/21/twister-effect)
- more effects here: https://democyclopedia.wordpress.com/2015/12/31/c-comme-city-skyline/

### 12.1 Runtime Config Controls (implemented)
- Plasma: speed, color tint
- Copper bars: speed, glow strength
- Starfield: speed, FOV
- Tunnel: speed, twist, color tint (https://lodev.org/cgtutor/tunnel.html)
- Rotozoom: speed, zoom amount
- Fire: intensity, cooling
- Sine scroller: scroll speed, wave amplitude
- DYCP scroller: scroll speed, wave amplitude
- Cube twister: speed, spin amount
- Wireframe cube: speed, line width, line color
- Glenz cube: speed, transparency
- Textured cube: speed, texture density
- Cube with plasma on one of the sides: rotation speed, plasma speed
- Meatballs: speed, blob threshold
- Vectorballs: speed, ball scale

## 13. Performance Considerations
- Avoid per-frame allocations in effect code.
- Reuse buffers and textures.
- Prefer integer/fixed-point math when practical for retro-style effects.
- Keep UI drawing lightweight to preserve effect frame rate.

## 14. Error Handling and Diagnostics
- If effect creation fails, show fallback message in right panel and keep app running.
- Log effect switch, initialization failures, and SDL errors.
- Add optional FPS counter and frame time display for debugging.
- During startup, explicitly surface missing native SDL dependency errors with actionable guidance (x64 target, `SDL2.dll` placement, VC++ runtime).

## 15. Milestones
1. SDL window + split layout scaffold
2. Searchable effect list with keyboard/mouse selection
3. `DemoSceneEffect` interface + lifecycle wiring
4. Resource cleanup hardening and performance pass

## 16. Reference
- Example inspiration list: https://demo-effects.sourceforge.net/
