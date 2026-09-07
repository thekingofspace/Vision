# From Vide

The closest neighbour on this list. Both are small, both give you a callable
that reads with no arguments and writes with one, and neither builds a
virtual tree.

The difference is when things happen. Vide is reactive: the tree exists from
`mount`, and a write re-runs the effects that read that source. Vision
stages: `Capture` builds nothing, writes before `Mount` only store, and the
callback runs once with the last value.

[The comparison page](/comparison) measures both side by side.

## The table

| Vide | Vision |
| --- | --- |
| `create "Frame" { ... }` | `{ ClassName = "Frame", ... }` |
| the array part of a `create` call | the array part of the declaration |
| `source(0)` | `event("Name", 0, Callback)` |
| `Src()` | `Interface.Name()` |
| `Src(Value)` | `Interface.Name(Value)` |
| `derive(function() return Src() * 2 end)` | `derive("Name", Compute)` |
| `effect(fn)` | the callback you give `event` or `merge` |
| a second effect on one source | `merge("Name", Callback)` |
| `mount(Component, Target)` | `Scope:Capture(Decl)` with `mount(Target)`, then `:Mount()` |
| the destroy function `mount` returns | `Interface:Cleanup()` or `Scope:Release()` |
| `cleanup(fn)` | `cleanup(function(self, vision) end)` |
| `spring(Src, Period, Damping)` | `Scope:PhysicsEvent(Period, Damping, Interface, { Name = Goal })` |
| `changed("Text", fn)` | `PropertyChanged = { Text = fn }` |
| `action(fn)` | `ready(function(self) end)` |
| `untrack` | not needed, dependencies are named rather than ambient |
| `batch` | not needed, writes are not deferred |
| `root(fn)` | `Vision.Scope()` |
| `indexes`, `values` | no equivalent, build the rows yourself |
| `show`, `switch` | no equivalent, bind `Visible` or mount whole visions |
| `context` | no equivalent |

## A counter

Vide:

```lua
local function Counter()
    local Count = source(0)

    return create "TextButton" {
        Text = function()
            return `Clicks: {Count()}`
        end,

        Activated = function()
            Count(Count() + 1)
        end,
    }
end

local Destroy = mount(Counter, PlayerGui)
```

Vision:

```lua
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

Vide binds a property to a function and re-runs it. Vision binds a callback
to a name and lets it assign whatever it likes, including several properties
across several instances.

## Derives are the biggest change

Vide tracks dependencies by watching which sources you read. Vision watches
nothing. You say what you read, and you can also say what happens when
someone writes to the derived value:

```lua
derive("Doubled", function(Mode, Read, Write, Value)
    if Mode == "set" then
        return Write("Charge", Value / 2)
    end

    return Read("Charge") * 2
end)
```

`Interface.Doubled()` computes from `Charge`. `Interface.Doubled(1.6)` runs
the `"set"` branch and pushes `0.8` back into `Charge`. Vide's derives are
read only.

## Things that will trip you

**Teardown destroys.** Vide's destructor tears down the reactive graph and
leaves the instances alone. `Scope:Release()` destroys the instances it
created. If you were relying on instances outliving the destructor, use
`fromInstance`, which adopts an instance and never destroys it.

**Properties are not functions.** Vide accepts a function for any property
and re-runs it. Vision takes a plain value for a property, and reactivity
comes from a named value plus a callback.

**A spring lives on the scope, not on the source.** Vide wraps a source in
`spring`. Vision animates toward a goal from the scope, and the target can be
a value, an instance, a style field or a plain function. See
[scope](/api/scope).

**Nothing is ambient.** There is no tracking context, so no `untrack`, and
reading a value inside a callback never subscribes you to it.
