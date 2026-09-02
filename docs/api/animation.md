# Animation

Vision's springs are tween-driven. They take a `TweenInfo` and read their
curve from `TweenService:GetValue`, so the shape is not an approximation of
TweenService — it *is* TweenService.

Only the timeline is Vision's own, and it reproduces real `Tween` behaviour
including delay, repeat and reverses.

## Linker

Every `Spring*` call returns one.

```lua
export type Linker = {
    Cancel: (self: Linker) -> (),
    Await: (self: Linker) -> (),
    Finished: boolean,
}
```

### Await

Yields the calling thread until the link finishes or is cancelled. Returns
immediately if it is already done.

```lua
task.spawn(function()
    Scope:SpringInstance(Out, Panel, { Size = Big }):Await()
    Scope:SpringInstance(Back, Panel, { Size = Normal })
end)
```

### Cancel

Stops the link where it is. The value keeps whatever it last held.

### Finished

`true` once the link has completed or been cancelled. A finished link drops
its claims, its callback and its runtime reference, so nothing is retained.

## TweenInfo support

Every field is honoured.

| field | behaviour |
| --- | --- |
| `Time` | length of one direction |
| `EasingStyle`, `EasingDirection` | passed to `TweenService:GetValue` |
| `DelayTime` | held at the start value, **re-applied before every repeat** |
| `RepeatCount` | extra plays after the first; `-1` never ends |
| `Reverses` | plays forward then back, ending at the start value |

One cycle is `DelayTime + Time * (Reverses and 2 or 1)`, and a tween runs
`RepeatCount + 1` of them.

### Repeats land on the goal

At a cycle boundary the goal value is emitted on that frame, and the next
cycle starts from it. This matters — without it a repeating tween never
visually reaches its target.

This is real TweenService behaviour, confirmed frame by frame against a live
`Tween`:

```
   t     roblox   vision
0.283s    94.63    94.63
0.299s   100.00   100.00   <- the goal, on the boundary frame
0.317s     5.32     5.32
0.333s    11.30    11.30
```

A consequence worth knowing: because the next cycle starts from the boundary
*frame*, a repeating tween's total runtime is frame-quantised and drifts
slightly past the arithmetic ideal. Roblox does the same.

## Interpolation

| type | behaviour |
| --- | --- |
| `number` | linear |
| `Vector2`, `Vector3`, `UDim2`, `CFrame`, `Color3` | Roblox's own `:Lerp` |
| `UDim` | scale linear, **offset rounded** |
| `Rect`, `NumberRange` | component-wise |
| `Vector2int16`, `Vector3int16` | component-wise, rounded |
| `NumberSequence`, `ColorSequence` | keypoint-wise |
| `string` | typewriter, UTF-8 safe |
| anything else | switches at the halfway point |

That last row covers booleans and EnumItems, and matches TweenService, which
flips values it cannot interpolate at the midpoint rather than at the end.

### Beyond TweenService

`NumberSequence`, `ColorSequence` and `string` are **not** tweenable by
TweenService. Vision animates them anyway.

Sequences interpolate keypoint by keypoint — time, value and envelope — and
never insert or remove a waypoint. If the two sequences have different
keypoint counts there is nothing sensible to interpolate, so the value
switches at the halfway point instead.

Strings type out: the visible length moves from the start string's length to
the goal's, sliced from the goal on UTF-8 boundaries.

```lua
Scope:SpringValue(TweenInfo.new(0.45), Interface, "Status", "Ready")
```

## Overshoot

`Back` and `Elastic` return alpha outside `0..1`, and Vision does not clamp
it — an overshooting curve overshoots the value, as it should. `Back`/`Out`
peaks at **1.100** at 0.35s of a 0.6s tween.

Leave room for it. A bar tweening to `1.0` scale with `Back` will pass its
track; tween to `0.8` instead.

## Retargeting

Starting a spring on a value that is already animating cancels the old link
and starts from the current value at **zero velocity**. A tween has a fixed
duration and no momentum, so an interrupted animation stops dead before
re-accelerating.

If you need motion that survives interruption, that is what a physics spring
is for — see the [comparison](/comparison).
