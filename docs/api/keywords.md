# Keywords

The five functions that go in the array part of a declaration. Each returns a
marker that `Capture` reads and removes.

```lua
local event = Vision.event
local merge = Vision.merge
local ready = Vision.ready
local cleanup = Vision.cleanup
local mount = Vision.mount
```

## event

```lua
event(Name: string, InitialValue: any, Callback: (self: Instance, Value: any) -> ()) -> Marker
```

Declares a named value on the Vision and binds this node's callback to it.
The value becomes callable as `Interface[Name]`, a [CapFunc](/api/vision).

```lua
event("Count", 0, function(self, Value)
    self.Text = `Clicks: {Value}`
end)
```

Declaring the same name twice does not create a second value - the second
declaration behaves as a `merge`, adding another binding. The first
declaration's `InitialValue` wins.

The callback runs **once at mount** with the value at that moment, then on
every change that actually changes it.

## merge

```lua
merge(Name: string, Callback: (self: Instance, Value: any) -> ()) -> Marker
```

Binds another callback to a value declared elsewhere in the same tree. This
is how one value drives several instances - each callback receives its own
`self`.

```lua
{
    ClassName = "TextLabel",
    event("Fill", 0.2, function(self, Value)
        self.Text = string.format("%.0f%%", Value * 100)
    end),
},

{
    ClassName = "Frame",
    merge("Fill", function(self, Value)
        self.Size = UDim2.fromScale(Value, 1)
    end),
},
```

A `merge` may name a value that has not been declared yet.

## derive

```lua
derive(Name: string, Compute: (Read: (string) -> any) -> any) -> Marker
```

Declares a value computed from other values. The `Read` you are handed both
returns a value and records it as a dependency, so the graph is discovered as
the function runs.

```lua
event("Price", 10, function() end),
event("Quantity", 2, function() end),

derive("Total", function(Read)
    return Read("Price") * Read("Quantity")
end),
```

`Total` behaves like any other value: `merge` onto it, read it with
`Interface.Total()`, animate it. It recomputes whenever a value it read
changes, and derived values chain, so a derive that reads another derive
updates after it.

::: warning A derive must be pure
This is the one place purity is required. A derive may run more than once for
a single change, and it only re-runs when something it read through `Read`
changes.

So it must have no side effects, and it must read every input through `Read`.
A derive that reads an ordinary upvalue silently goes stale, because Vision
has no way to know that value moved:

```lua
local Bonus = 10

derive("Total", function(Read)
    return Read("Base") + Bonus   -- wrong, Bonus is untracked
end),
```

Changing `Bonus` will not recompute anything, and the stale result survives
until some tracked value happens to change. Make it a value and `Read` it.
:::

### Tracking is per run

Dependencies are re-recorded on every recompute, so a branch you did not take
is not a dependency:

```lua
derive("Shown", function(Read)
    if Read("UseFallback") then
        return Read("Fallback")
    end

    return Read("Primary")
end),
```

While `UseFallback` is false, writing `Fallback` recomputes nothing. Flip it
and `Fallback` becomes live while `Primary` goes quiet.

::: warning Derived values are read only
`Interface.Total(5)` raises. A derive owns its value. Reading a value from
itself raises too, as does a cycle between two derives.
:::

## ready

```lua
ready(Callback: (self: Instance) -> ()) -> Marker
```

Runs after the tree is built and the root is parented. Callbacks run
**deepest first**, climbing the tree, so a child is always live before its
parent's `ready` runs.

```lua
ready(function(self)
    print(self.Name, "is live", self.AbsoluteSize)
end)
```

## cleanup

```lua
cleanup(Callback: (self: Instance) -> ()) -> Marker?
```

Runs when the Vision is cleaned up, before anything is disconnected or
destroyed, so the instance is still live.

It works two ways. In a declaration:

```lua
cleanup(function(self)
    print("releasing", self.Name)
end),
```

Or called **inside a `ready` callback**, where it registers against the node
currently running. This is the useful form - it puts a connection and its
disconnect next to each other:

```lua
ready(function(self)
    local Connection = SomeSignal:Connect(Handler)

    cleanup(function()
        Connection:Disconnect()
    end)
end),
```

Callbacks run deepest first across nodes, and **last registered first**
within a node, so a connection made in `ready` is released before the
declared `cleanup` runs.

## mount

```lua
mount(Target: Instance | string) -> Marker
```

Sets where this node is parented. An `Instance` parents there directly; a
`string` resolves to the node in the same tree with that declared `Name`.

```lua
mount(PlayerGui)
mount("Panel")
```

Without a `mount`, a child parents to the declaration containing it, and a
root parents to nothing - it is created but left unparented.
