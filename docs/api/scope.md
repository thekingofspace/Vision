# Scope

A scope owns the Visions you capture and the animation runtime that drives
them. It is the only thing you construct directly.

```lua
local Scope = Vision.Scope()
```

One scope per screen, per feature, or per session is all reasonable - the
runtime inside it costs nothing until something is animating.

## Capture

```lua
Scope:Capture(Declaration: Declaration) -> Vision
```

Reads a declaration tree and returns a [Vision](/api/vision). **Creates no
instances.** Capture parses the tree, registers values and names, and hands
back a handle you can write to.

```lua
local Interface = Scope:Capture({
    ClassName = "Frame",
    mount(PlayerGui),
    event("Count", 0, function(self, Value)
        self.Name = `Count{Value}`
    end),
})
```

## LoadStyle

```lua
Scope:LoadStyle(Declaration: { name: string, [string]: any }) -> Style
```

Creates or updates a named style and returns the sheet. Declarations bind to
its fields with the [style](/api/keywords#style) keyword, and changing a
field updates every instance bound to it.

```lua
const Dark = Scope:LoadStyle({
    name = "Dark",
    Surface = Color3.fromRGB(20, 20, 26),
    Ink = Color3.fromRGB(240, 240, 250),
})

Dark:Set("Surface", Accent)
```

Styles can also be animated, so a theme change can crossfade instead of
snapping:

```lua
Scope:SpringStyle(TweenInfo.new(0.4), Dark, { Surface = Paper, Ink = Coal })
Scope:PhysicsStyle(0.5, 0.7, "Dark", { Radius = 20 })
```

See [Style](/api/style) for the full page.

## Update

```lua
Scope:Update(EventName: string, Value: any)
```

Writes one value into **every Vision the scope has captured** that declares
that name. Visions without it are skipped, so a scope holding a mix of trees
is fine.

```lua
Scope:Update("Theme", Color3.fromRGB(88, 101, 242))
```

It reaches everything the scope currently owns: captured Visions that have
not been mounted yet, and mounted ones. A staged Vision stores the write and
applies it on its first mount.

`Cleanup` takes a Vision out of the scope, so a cleaned up Vision is **not**
updated. Mounting it again puts it back and later updates reach it.

```lua
Interface:Cleanup()
Scope:Update("Theme", Red)     -- Interface is not touched

Interface:Mount()
Scope:Update("Theme", Blue)    -- now it is
```

A derived value is skipped unless its compute handles `"set"`, the same as
writing it directly.

::: tip
The scope holds its Visions weakly here, so `Update` never keeps one alive.
Drop your reference to a Vision and it is still collectable.
:::

## SpringValue <Badge type="danger" text="deprecated" />

::: danger Deprecated
Use [SpringEvent](#springevent) instead. It does the same thing and takes any
number of values in one call, so `SpringEvent(Info, Target, { Fill = 0.8 })`
replaces `SpringValue(Info, Target, "Fill", 0.8)` directly.
:::

```lua
Scope:SpringValue(
    Info: TweenInfo,
    Target: Vision | { Vision },
    ValueName: string,
    TargetValue: any
) -> Linker
```

Animates a single named value. Prefer [SpringEvent](#springevent), which does
the same thing for any number of values in one call.

Writes through the CapFunc each frame - so every callback bound to that
value runs, and the instances update themselves.

```lua
Scope:SpringValue(
    TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Interface,
    "Fill",
    0.8
)
```

Accepts a list of Visions to drive several at once.

## SpringEvent

```lua
Scope:SpringEvent(
    Info: TweenInfo,
    Target: Vision | { Vision },
    Values: { [string]: any }
) -> Linker
```

Animates several named values at once, as one link. The table maps value
names to their targets.

```lua
Scope:SpringEvent(TweenInfo.new(0.6), Interface, {
    Fill = 0.8,
    Tint = Color3.fromRGB(88, 101, 242),
})
```

Pass a list of Visions and every one of them animates from the same call, so
one link can drive a whole grid.

```lua
Scope:SpringEvent(TweenInfo.new(0.6), Tiles, { Tint = Accent })
```

Each value keeps its own start, and each Vision keeps its own, so they can be
at different places when the call is made. Naming a value the Vision does not
declare raises.

## SpringInstance

```lua
Scope:SpringInstance(
    Info: TweenInfo,
    Target: Instance | { Instance },
    Properties: { [string]: any }
) -> Linker
```

Animates properties on instances directly, without going through a Vision.

```lua
Scope:SpringInstance(
    TweenInfo.new(0.18),
    Button,
    { BackgroundColor3 = Hover }
)
```

## SpringFunction

```lua
Scope:SpringFunction(
    Info: TweenInfo,
    Callback: (NewValue: any, DeltaTime: number) -> (),
    InitialValue: any,
    TargetValue: any
) -> Linker
```

Animates between two values and hands each step to your callback, along with
the frame delta. For anything that is neither a Vision value nor a plain
property.

```lua
Scope:SpringFunction(TweenInfo.new(0.7), function(Value, DeltaTime)
    Accent.Rotation = Value
end, 0, 180)
```

## PhysicsInstance, PhysicsFunction

```lua
Scope:PhysicsInstance(Period: number, Damping: number, Target, Properties) -> Linker
Scope:PhysicsFunction(Period: number, Damping: number, Callback, Initial, Goal) -> Linker
```

The same three shapes as the `Spring*` methods, driven by a damped spring
instead of a `TweenInfo`. There is no duration: `Period` is the undamped
period in seconds, `Damping` is the ratio, and the motion ends when it
settles.

```lua
Scope:PhysicsInstance(0.6, 0.7, Button, { BackgroundColor3 = Hover })
```

## PhysicsValue <Badge type="danger" text="deprecated" />

::: danger Deprecated
Use [PhysicsEvent](#physicsevent) instead.
`PhysicsEvent(Period, Damping, Target, { Fill = 0.8 })` replaces
`PhysicsValue(Period, Damping, Target, "Fill", 0.8)` directly.
:::

```lua
Scope:PhysicsValue(Period: number, Damping: number, Target, ValueName, Goal) -> Linker
```

Animates a single named value with a solver. Still works, still cancels
against the same claims, but every call it can make `PhysicsEvent` can make
too.

| damping | behaviour |
| --- | --- |
| `1` | critically damped, no overshoot |
| `0.7` | overshoots ~4.6% |
| `0.59` | overshoots ~10%, close to `Back`/`Out` |
| `> 1` | overdamped, slow approach |

### Velocity survives interruption

This is the reason to reach for these over the tween ones. Retarget a running
physics spring and it **keeps its velocity**, so the motion flows into the new
goal instead of stopping dead.

```lua
Scope:PhysicsInstance(0.6, 1, Panel, { Position = A })
-- mid flight
Scope:PhysicsInstance(0.6, 1, Panel, { Position = B })  -- carries the speed
```

A `TweenInfo` spring cannot do this: it restarts from the current value at
zero velocity.

### Supported types

`number`, `UDim`, `UDim2`, `Vector2`, `Vector3`, `Color3`, `Rect` and
`NumberRange`. Anything else raises, because a solver needs numeric
components to integrate. Use a tween for `CFrame`, strings, sequences and
booleans.

### They share the claim system

A physics spring and a tween spring claim targets the same way, so starting
either cancels whatever was driving that value or property.

## Release

```lua
Scope:Release()
```

Cleans up every Vision the scope captured - running `cleanup` callbacks,
disconnecting connections and destroying instances - cancels every link, and
disconnects the runtime.

## Conflicts

Every link claims what it drives: a Vision and value name, an instance and
property name, or a callback. Starting a new spring on a claim that is
already held **cancels the old link first**.

```lua
Scope:SpringInstance(Info, Button, { BackgroundColor3 = Hover })
Scope:SpringInstance(Info, Button, { BackgroundColor3 = Idle })
-- the first link is cancelled; only one tween ever drives that property
```

This is why a fast mouse cannot leave two colour tweens fighting. A partial
overlap cancels the whole earlier link - `{ Rotation, Transparency }`
followed by `{ Rotation }` cancels the first entirely.

## The runtime

Each scope drives its links from one connection: `RenderStepped` on the
client, `Heartbeat` on the server. It connects when the first link starts and
disconnects when the last one finishes, so an idle scope costs nothing.
