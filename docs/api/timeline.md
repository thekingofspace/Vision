# Timeline

Keyframe animation for 2D instances. You write the keyframes, Vision walks
them, interpolating each property and firing events on the way past.

```lua
local Run = Scope:Animate({
    Vision.Keyframe(TweenInfo.new(0, Enum.EasingStyle.Sine), 0, { BackgroundColor3 = White }),
    Vision.Keyframe(TweenInfo.new(0, Enum.EasingStyle.Sine), 1, { BackgroundColor3 = Black }),
}, Panel)
```

It starts playing immediately. The keyframe list is plain data, so the same
list can be handed to `Animate` again for another instance.

## Keyframe

```lua
Vision.Keyframe(Easing, Time: number, Properties: { [string]: any }, Events: { [string]: { any } }?)
```

`Time` is in seconds from the start. Keyframes do not have to be in order -
they are sorted for you.

### Easing arrives at the keyframe

A keyframe's easing describes how the animation **gets to it**, not how it
leaves. The first keyframe's easing is therefore never used, which matches
Roblox's own animation editor.

Only `EasingStyle` and `EasingDirection` are read from a `TweenInfo`. Timing
comes from the keyframe times, so `Time`, `DelayTime`, `RepeatCount` and
`Reverses` are all ignored.

Pass **`0`** as the time. `TweenInfo` is here for the shape of the curve, not
its length, and Roblox refuses `nil` for that first argument.

```lua
TweenInfo.new(0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
```

### Physics keyframes

Pass a table instead of a `TweenInfo` and that leg is solved as a spring.

```lua
Vision.Keyframe({ Damping = 0.3, Period = 0.4 }, 1, { Rotation = 90 })
```

| field | meaning |
| --- | --- |
| `Damping` or `Dampening` | damping ratio, under 1 rings, 1 is critical |
| `Period` | seconds per bounce, defaults to the length of the leg |

A spring is not obliged to arrive on time. When the next keyframe comes round
the spring is simply retargeted, keeping the velocity it had, so a run of
physics keyframes flows rather than stepping. If it is the last keyframe, the
animation stays alive until the spring settles.

Springs need a solvable type - `number`, `UDim`, `UDim2`, `Vector2`,
`Vector3`, `Color3`, `Rect`, `NumberRange`. Anything else needs a `TweenInfo`.

### One track per property

Each property gets its own timeline, built from the keyframes that mention it.
A property does not have to appear in every keyframe.

```lua
Vision.Keyframe(Ease, 0, { Rotation = 0, BackgroundTransparency = 0 }),
Vision.Keyframe(Ease, 1, { Rotation = 100 }),
Vision.Keyframe(Ease, 2, { BackgroundTransparency = 1 }),
```

Rotation finishes at one second and holds. Transparency keeps going to two.

A property also **spans the keyframes that do not mention it**. If colour is
set at keyframe one and again at keyframe three, it interpolates across the
whole gap - keyframe two is simply not a waypoint for that property.

```lua
Vision.Keyframe(Ease, 1, { BackgroundColor3 = White }),
Vision.Keyframe(Ease, 2, { Rotation = 90 }),
Vision.Keyframe(Ease, 3, { BackgroundColor3 = Red }),
```

Colour eases from white to red over the full two seconds while rotation does
its own thing at the halfway mark. A property with only one keyframe is simply
applied when that time arrives.

A track holds its value before its first keyframe and after its last, and
lands on the authored value exactly rather than wherever the final frame
happened to fall.

## Events

The fourth argument maps an event name to its arguments.

```lua
Vision.Keyframe(Ease, 0, { Rotation = 0 }, { Step = { "left", 3 } })
```

```lua
Run:Bind("Step", function(Object, Side, Count)
    print(Object.Name, Side, Count)
end)
```

The instance is always the first argument, as everywhere else in Vision.
Events at time zero fire on the first frame, **after** `Animate` returns, so
there is always time to bind to them. `Bind` returns a handle with
`Disconnect`.

## Playback

```lua
Run.Speed = 2           -- twice as fast
Run.Speed = 0.5         -- half
Run.Speed = 0           -- paused, still alive
Run.Looped = true       -- wraps at the end and fires its events again
Run.SmoothLoop = true   -- eases across the seam instead of cutting
```

`Speed` is a multiplier on elapsed time and cannot be negative. `Looped` can
be turned off mid-run, and the animation then finishes at the end of the
current pass.

### SmoothLoop

A loop normally cuts: at the end of a pass every property snaps back to its
first keyframe. That is right for a cycle that already ends where it began,
and jarring for one that does not.

With `SmoothLoop` on, the animation instead **restages**. Time holds at the
start while every property travels from where it ended back to its first
keyframe, and the next pass begins once they have all arrived.

```lua
Run.Looped = true
Run.SmoothLoop = true
Run.RestageTime = 0.4
```

`RestageTime` is how long that walk back takes, in seconds, and defaults to
`0.25`. Setting it to `0` turns the restage back into a hard cut.

Each property restages on **its own last keyframe's easing**, so a property
that ends on a `Sine` tween eases back, and one that ends on a spring springs
back - overshooting the start and settling, rather than sliding flatly into
it. A sprung property is allowed to finish settling even if that outlasts
`RestageTime`.

`SmoothLoop` does nothing unless `Looped` is on.

## Jumping

```lua
Run:Jump(Time: number)
```

Moves the playhead to that point in seconds and applies the pose there
immediately, without waiting a frame. The time is clamped to the length of the
timeline, so `Jump(0)` rewinds and a time past the end parks it on the last
keyframe.

```lua
Run.Speed = 0
Run:Jump(1.5)     -- scrub to a moment and hold there
```

Events **between where you were and where you land do not fire** - a jump is a
seek, not a fast forward. Events after the new position still fire as the
animation reaches them, and jumping backwards re-arms the ones you passed.

Jumping cancels a restage in progress, and a sprung property restarts its
spring from the pose at the new time, since a spring has no meaningful state
part way through a seek.

Jumping a stopped or destroyed animation does nothing.

## Stopping

| member | behaviour |
| --- | --- |
| `Run:Stop()` | freezes every property where it stands |
| `Run:Destroy()` | stops it and drops every listener |
| `Run:Jump(Time)` | seek to a point in seconds |
| `Run:Await()` | yields until it finishes or is stopped |
| `Run.Finished` | true once it has ended |

An animation is owned by the runtime while it plays, so you can drop the
handle and let it run. Keep it if you want to stop it, retime it, or bind to
its events.

After `Destroy` nothing holds the animation and nothing holds the functions
you bound to it.

## Sharing properties

An animation claims each property it drives, the same way a spring does.
Starting a spring on a property an animation is driving cancels the
animation, and starting an animation cancels the springs it overlaps. Last
call wins.

Destroying the instance stops the animation on the spot.
