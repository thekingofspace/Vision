# Animation

Vision animates through the scope, not the declaration. Every `Spring*` call
returns a `Linker` you can wait on or cancel.

They are tween-driven: you pass a `TweenInfo`, and the curve comes from
`TweenService:GetValue`. The shape is not an imitation of TweenService, it
*is* TweenService.

## Animating a value

`SpringValue` drives a name you declared with `event`. Every callback bound
to that value runs each frame, so the instances update themselves.

```lua
local Interface = Scope:Capture({
    ClassName = "Frame",
    mount(PlayerGui),

    event("Fill", 0.2, function(self, Value)
        self.Size = UDim2.fromScale(Value, 1)
    end),
})

Interface:Mount()

Scope:SpringValue(
    TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Interface,
    "Fill",
    0.8
)
```

Because it writes through the value, anything merged onto `Fill` animates
too — a bar and its percentage readout stay in step without extra work.

## Animating properties

`SpringInstance` skips the Vision and drives properties directly.

```lua
Scope:SpringInstance(TweenInfo.new(0.18), Button, {
    BackgroundColor3 = Color3.fromRGB(120, 132, 255),
})
```

## Animating anything else

`SpringFunction` hands each step to you, with the frame delta.

```lua
Scope:SpringFunction(TweenInfo.new(0.7), function(Value, DeltaTime)
    Accent.Rotation = Value
end, 0, 180)
```

## Waiting

`Await` yields until the link is done, which makes sequences read top to
bottom.

```lua
task.spawn(function()
    Scope:SpringInstance(Quick, Panel, { Size = Big }):Await()
    Scope:SpringInstance(Settle, Panel, { Size = Normal })
end)
```

## Interrupting

Starting a spring on something already animating cancels the old one first.

```lua
Button.MouseEnter:Connect(function()
    Scope:SpringInstance(Fade, Button, { BackgroundColor3 = Hover })
end)

Button.MouseLeave:Connect(function()
    Scope:SpringInstance(Fade, Button, { BackgroundColor3 = Idle })
end)
```

A fast mouse cannot leave two tweens fighting over the same property. This
works per claim — a Vision and value name, or an instance and property name.

::: warning A tween has no momentum
An interrupted tween restarts from the current value at **zero velocity**, so
it stops dead before accelerating again. That is inherent to a fixed duration
and a curve. If you need motion that flows through an interruption, you want
a physics spring — see the [comparison](/comparison).
:::

## Overshoot

`Back` and `Elastic` return alpha outside `0..1`, and Vision does not clamp
it. `Back`/`Out` peaks at **1.100**, so a bar tweening to `1.0` scale will
run past its track. Aim at `0.8` and let the overshoot land inside.

## Beyond TweenService

Vision animates three types TweenService cannot: `NumberSequence`,
`ColorSequence` and `string`.

```lua
Scope:SpringValue(TweenInfo.new(0.45), Interface, "Status", "Ready")
```

Strings type out on UTF-8 boundaries. Sequences interpolate keypoint by
keypoint and never insert or remove a waypoint.

## Cleaning up

Links are owned by the scope. `Scope:Release` cancels everything, and
`Interface:Cleanup` cancels whatever was driving that tree.

## Done

That is the whole library. The [API reference](/api/declarations) has the
details.
