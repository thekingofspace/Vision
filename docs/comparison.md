# Comparison

Vision, [Vide](https://github.com/centau/vide) and writing no module at all,
measured with the same 100 row tree.

The benchmark lives in `src/client/Comparison.luau` and prints every number on
this page. Run the place and read the output - do not trust a table in a
readme over your own machine.

## Behaviour

This is the part that does not change between runs. Each column builds one
instance and writes a value five times *before* the instance is shown.

| | Vision | Vide | No module |
| --- | --- | --- | --- |
| instances before reveal | **0** | 1 | 1 |
| updates at declaration | **0** | 1 | 0 |
| updates for 5 writes | **0** | 5 | 5 |
| instances created at reveal | 1 | 0 | 0 |
| updates total | **1** | 6 | 5 |
| instances destroyed on teardown | **all** | none | yours to destroy |

Vision stages. `Capture` builds no instances, and writes made before `Mount`
only store - the callback runs once, with the last value. Vide is reactive:
the tree exists from `mount`, and every write re-runs the effects that depend
on it. Neither is better; they answer different questions.

The teardown row is a real difference and easy to miss. `Scope:Release`
destroys the instances it created. Vide's destructor tears down the reactive
graph and leaves the instances alone, so you destroy the container yourself.

## Ownership

| | Vision | Vide | No module |
| --- | --- | --- | --- |
| when instances exist | at `Mount` | at `mount` | at `Instance.new` |
| who assigns the property | your callback | the binding | you |
| one value, many targets | `event` + `merge` | one source, many effects | by hand |
| unchanged write | skipped | skipped | writes anyway |
| derived values | `derive`, tracked per run | `derive`, tracked per run | by hand |
| dependency tracking | explicit `Read` inside a derive | ambient, any source read | none |
| tween animation | `TweenInfo`, real `Tween` semantics | not built in | `TweenService` directly |
| physics animation | `Physics*`, carries velocity | `spring`, carries velocity | none |
| teardown | `Scope:Release` destroys | destructor keeps instances | you destroy |
| sleep and revive | `Cleanup` then `Mount`, state kept | rebuild it yourself | rebuild it yourself |

## Performance

Measured in Studio, 100 rows, 100 writes each, best of three rounds in
rotating order so no implementation always runs first.

Read the write row carefully. At this size a single `TextLabel.Text`
assignment costs roughly **72 µs**, and all three columns pay it 10,000
times. That one property write is about **99.9%** of the number.

For scale: Vision's own dispatch - the loop that calls each bound callback -
measures **~30 ns** per call over two million calls. Ten thousand of those is
**0.3 ms** against a total near 700 ms.

So treat differences of a few percent in the write row as noise, not as a
ranking. The `cost over raw` row is the honest one: it subtracts the
no-module baseline and shows what the framework actually charges you.

Across four Studio runs on one machine:

| | Vision | Vide |
| --- | --- | --- |
| total to on screen | 9.06 – 9.92 ms | 9.14 – 13.87 ms |
| 100 writes x 100 rows | 707 – 755 ms | 696 – 726 ms |
| teardown | 0.49 – 0.72 ms | 0.04 – 0.05 ms |

The teardown gap is not a loss. Vision destroys 101 instances in that time
and Vide destroys none.

## Animation

Both libraries can be made to feel identical, which is worth knowing before
you conclude one is bouncier than the other.

Vision uses a `TweenInfo` and reads its curve from `TweenService:GetValue`,
so the shape *is* TweenService's. `Back`/`Out` overshoots to **1.100** and
peaks at **0.35s** of a 0.6s tween.

Vide uses a damped spring, where overshoot is set by the damping ratio:

$$\text{overshoot} = e^{-\zeta\pi/\sqrt{1-\zeta^2}}$$

| damping | overshoot |
| --- | --- |
| 0.70 | +4.6% |
| 0.62 | +8.4% |
| 0.60 | +9.5% |
| **0.59** | **+10.1%** |
| 0.58 | +10.7% |

So `spring(goal, 0.6, 0.59)` peaks at 1.098 at 0.35s - the same bounce, at
the same moment, as `Back`/`Out`. The demo uses exactly that pairing.

The difference no easing can close is retargeting. Interrupt a `TweenInfo`
mid-flight and it restarts from the current value with **zero velocity**;
a spring carries velocity through the new goal and keeps flowing.

## Reactivity

Both libraries are fine grained in the sense that matters: a write updates
only what actually depends on it. Neither diffs a tree or re-renders a
component.

They differ in how a dependency is discovered.

Vide tracks **ambiently**. Any source you call inside an effect or a property
binding is recorded, so a binding is a plain closure:

```lua
Text = function()
    return `row {Index} :: {Tick()}`
end
```

Vision tracks **explicitly**. A binding names its value up front with `event`
or `merge`, and a `derive` reads through a `Read` handed to it:

```lua
derive("Total", function(Read)
    return Read("Price") * Read("Quantity")
end)
```

The tracking inside a derive is per run, so an untaken branch is not a
dependency, and the graph changes as conditions change. The trade is
verbosity for legibility: you can see a Vision value's dependencies without
running it, and there is no ambient state to reason about.

## Choosing

Pick **Vision** when the tree should not exist until the data is ready, when
you want to sleep a menu and revive it with its state intact, or when you
want real `TweenInfo` semantics with a handle you can `Await` and cancel.

Pick **Vide** when you want ambient dependency tracking, a component model
built around closures, and a mature library with a larger surface than this
one.

Pick **neither** when you are building three instances. A module earns its
place at scale, not at three labels - and the benchmark above says the
runtime cost of either choice is a rounding error next to Roblox's own
property writes.
