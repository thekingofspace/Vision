# From Fusion

Fusion is the one whose ownership model you already know. A Fusion scope owns
what it made and `doCleanup` destroys it; a Vision scope owns what it made and
`Scope:Release` destroys it. That part carries over intact.

What changes is the graph. Fusion propagates through objects that hold values
and recompute. Vision has named values and callbacks, and builds nothing until
you mount.

The table below is Fusion 0.3. The 0.2 names are in the last column where
they differ.

## The table

| Fusion 0.3 | Vision | 0.2 |
| --- | --- | --- |
| `scoped(Fusion)` | `Vision.Scope()` | `Fusion` directly |
| `scope:New "Frame" { ... }` | `{ ClassName = "Frame", ... }` | `New "Frame"` |
| `[Children] = { ... }` | the array part of the declaration | same |
| `scope:Value(0)` | `event("Name", 0, Callback)` | `Value(0)` |
| `peek(Value)` | `Interface.Name()` | same |
| `Value:set(x)` | `Interface.Name(x)` | same |
| `scope:Computed(function(use) ... end)` | `derive("Name", Compute)` | `Computed(fn)` |
| `scope:Observer(v):onChange(fn)` | `merge("Name", fn)` | `Observer(v)` |
| `[OnEvent "Activated"] = fn` | `Activated = fn` | same |
| `[OnChange "Text"] = fn` | `PropertyChanged = { Text = fn }` | same |
| `[Out "Text"] = SomeValue` | `PropertyChanged` writing into a value | same |
| `[Ref] = SomeValue` | `Interface:Open()` or `ready` | same |
| `scope:Tween(v, Info)` | `Scope:SpringEvent(Info, Interface, { Name = Goal })` | `Tween(v, Info)` |
| `scope:Spring(v, Speed, Damping)` | `Scope:PhysicsEvent(Period, Damping, Interface, { Name = Goal })` | `Spring(...)` |
| `table.insert(scope, fn)` for teardown | `cleanup(function(self, vision) end)` | `[Cleanup]` |
| `doCleanup(scope)` | `Scope:Release()` | `Fusion.cleanup` |
| `scope:ForValues`, `ForKeys`, `ForPairs` | no equivalent, build the rows yourself | same |
| `scope:Hydrate(Instance) { ... }` | `fromInstance(Instance)` in the declaration | `Hydrate` |

## A counter

Fusion:

```lua
local scope = scoped(Fusion)

local Count = scope:Value(0)

scope:New "TextButton" {
    Parent = PlayerGui,

    Text = scope:Computed(function(use)
        return `Clicks: {use(Count)}`
    end),

    [OnEvent "Activated"] = function()
        Count:set(peek(Count) + 1)
    end,
}
```

Vision:

```lua
local Scope = Vision.Scope()

local Counter = Scope:Capture({
    ClassName = "TextButton",

    mount(PlayerGui),

    event("Count", 0, function(self, _, Value)
        self.Text = `Clicks: {Value}`
    end),

    Activated = function(_, Panel)
        Panel.Count(Panel.Count() + 1)
    end,
})

Counter:Mount()
```

Fusion computes a string and assigns it to `Text`. Vision hands the number to
a callback and lets it decide what to write.

## Hydrate maps onto fromInstance

`Hydrate` was the reason to reach for Fusion on a Studio-built tree, and
Vision has three answers rather than one:

```lua
Scope:Capture({
    fromInstance(Existing),      -- adopt it, never destroy it

    { FromParent = "Label", Text = "wired up" },
})
```

- `fromInstance(X)` adopts `X`. `Cleanup` disconnects everything Vision
  connected and leaves the instance exactly where it was.
- `fromClone(X)` copies `X` instead, and owns the copy, so `Cleanup` destroys
  it and mounting again stamps a fresh one.
- `FromParent = "Name"` finds a child by name on the node around it, which is
  how you reach into a template without redeclaring its children.

See [keywords](/api/keywords).

## Things that will trip you

**Nothing exists until `Mount`.** A Fusion `New` call creates the instance
there and then. `Capture` does not. Writes you make before mounting are
stored and applied once, so the tree appears already correct.

**Springs take a period, not a speed.** Fusion's `Spring` is tuned by speed;
`Scope:PhysicsEvent(Period, Damping, ...)` takes the period in seconds and a
damping ratio, where under 1 rings, 1 is critical and over 1 crawls in. There
is no clean conversion, so tune by feel.

**`Tween` is a spring method here.** `Scope:SpringEvent` takes a `TweenInfo`
and gives you real tween semantics, including repeat and reverse. The
`Physics*` family is the one that carries velocity. See [scope](/api/scope).

**Computeds do not track what you read.** There is no `use`. `derive` is
given an explicit `Read` and a `Mode`, and it can be written to as well,
pushing values back to its sources.

**Cleanup can be temporary.** `Interface:Cleanup()` destroys the instances but
keeps the values, and `Mount` rebuilds from the same declaration with the
same state. There is no Fusion equivalent. See
[sleeping](/tut/crash-course/6-sleeping).
