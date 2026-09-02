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

## SpringValue

```lua
Scope:SpringValue(
    Info: TweenInfo,
    Target: Vision | { Vision },
    ValueName: string,
    TargetValue: any
) -> Linker
```

Animates a Vision's named value from its current value to `TargetValue`,
writing through the CapFunc each frame - so every callback bound to that
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

## PhysicsValue, PhysicsInstance, PhysicsFunction

```lua
Scope:PhysicsValue(Period: number, Damping: number, Target, ValueName, Goal) -> Linker
Scope:PhysicsInstance(Period: number, Damping: number, Target, Properties) -> Linker
Scope:PhysicsFunction(Period: number, Damping: number, Callback, Initial, Goal) -> Linker
```

The same three shapes as the `Spring*` methods, driven by a damped spring
instead of a `TweenInfo`. There is no duration: `Period` is the undamped
period in seconds, `Damping` is the ratio, and the motion ends when it
settles.

```lua
Scope:PhysicsValue(0.6, 0.7, Interface, "Fill", 0.8)
```

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
