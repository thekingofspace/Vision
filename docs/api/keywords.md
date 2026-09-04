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
derive(Name: string, Compute: (Mode, Read, Write, Value) -> any) -> Marker
```

Declares a value computed from other values. One callback handles both
directions, and `Mode` says which one you are in.

| argument | meaning |
| --- | --- |
| `Mode` | `"get"` when computing, `"set"` when someone writes |
| `Read` | `Read(Name)` returns another value |
| `Write` | `Write(Name, Value)` writes another value, only in `"set"` |
| `Value` | the incoming value, only in `"set"` |

### Reading

Return the computed value from `"get"`. The `Read` you are handed records
what you touched, so the graph is discovered as the function runs.

```lua
event("Price", 10, function() end),
event("Quantity", 2, function() end),

derive("Total", function(Mode, Read)
    return Read("Price") * Read("Quantity")
end),
```

`Total` behaves like any other value: `merge` onto it, read it with
`Interface.Total()`, animate it. It recomputes whenever a value it read
changes, and derives chain.

### Writing

Handle `"set"` and the value becomes writable in both directions. You do not
assign the derived value; you push into the values it is computed from, and
it recomputes from them.

```lua
event("Fahrenheit", 212, function() end),

derive("Celsius", function(Mode, Read, Write, Value)
    if Mode == "set" then
        Write("Fahrenheit", Value * 1.8 + 32)
        return
    end

    return (Read("Fahrenheit") - 32) / 1.8
end),
```

```lua
Interface.Celsius()      --> 100
Interface.Celsius(0)     -- writes 32 into Fahrenheit
Interface.Fahrenheit()   --> 32
```

That keeps the invariant that a derived value always equals what its sources
compute to. There is no way for the two to disagree.

A derive that never handles `"set"` is simply read only: writing to it does
nothing and the value stays derived.

### Tracking is per run

Dependencies are re-recorded on every `"get"`, so a branch you did not take
is not a dependency:

```lua
derive("Shown", function(Mode, Read)
    if Read("UseFallback") then
        return Read("Fallback")
    end

    return Read("Primary")
end),
```

While `UseFallback` is false, writing `Fallback` recomputes nothing. Flip it
and `Fallback` becomes live while `Primary` goes quiet.

::: warning Getting must be pure
A `"get"` may run more than once for a single change, and only re-runs when
something it read through `Read` changes. So it must have no side effects,
and it must read every input through `Read`.

A derive that reads an ordinary upvalue silently goes stale, because Vision
has no way to know that value moved:

```lua
local Bonus = 10

derive("Total", function(Mode, Read)
    return Read("Base") + Bonus   -- wrong, Bonus is untracked
end),
```

`Write` is refused during a `"get"` for the same reason. Reading a value from
itself raises, as does a cycle between two derives.
:::

## ready

```lua
ready(Callback: (self: Instance, cleanup: (Callback: (self: Instance) -> ()) -> ()) -> ()) -> Marker
```

Runs after the tree is built and the root is parented. Callbacks run
**deepest first**, climbing the tree, so a child is always live before its
parent's `ready` runs.

```lua
ready(function(self)
    print(self.Name, "is live", self.AbsoluteSize)
end),
```

### Releasing what you set up

`ready` hands you a second argument: a function that registers cleanup work
for **this node**, for **this mount**. Use it to keep a connection and its
disconnect in one place.

```lua
ready(function(self, cleanup)
    const Connection = Workspace.ChildAdded:Connect(Handler)

    cleanup(function()
        Connection:Disconnect()
    end)
end),
```

The callback you pass runs on teardown, before anything is disconnected or
destroyed, and receives the instance.

Because it is an argument rather than an ambient lookup, it is bound to the
node you are already inside. There is nothing to get wrong, and it works the
same whether you call it directly, from a nested helper, or pass it along.

::: warning Register it while ready is running
The registration itself must happen during the `ready` call. Handing the
function to something deferred registers nothing useful, because by the time
it runs the mount is over:

```lua
ready(function(self, cleanup)
    task.delay(1, function()
        cleanup(function() end)   -- too late, the tree is already live
    end)
end),
```
:::

## cleanup

```lua
cleanup(Callback: (self: Instance) -> ()) -> Marker
```

A declaration keyword. Runs when the tree is torn down, before anything is
disconnected or destroyed, so the instance is still usable.

```lua
{
    ClassName = "Frame",

    cleanup(function(self)
        print("releasing", self.Name)
    end),
}
```

This is for teardown work you know about up front. For anything you set up
inside `ready`, use the function `ready` gives you instead.

Callbacks run deepest first across nodes, and **last registered first** within
a node, so anything registered from `ready` is released before the `cleanup`
you declared in the table.

A declared `cleanup` persists for the life of the Vision and runs on every
teardown. One registered from `ready` belongs to that mount only, and is
registered again the next time `ready` runs.

## drawcall

```lua
drawcall(Callback: (self: Instance, Viewport: Vector2) -> ()) -> Marker
```

Runs when the viewport size changes, and once at mount so the first frame is
already correct. This is how you respond to a phone rotating, a window
resizing, or a device that simply is not the size you designed for.

```lua
{
    ClassName = "Frame",
    Name = "Panel",

    drawcall(function(self, Viewport)
        if Viewport.X < 700 then
            self.Size = UDim2.fromScale(1, 1)
            self.Position = UDim2.fromScale(0, 0)
        else
            self.Size = UDim2.fromOffset(620, 420)
            self.Position = UDim2.fromScale(0.5, 0.5)
        end
    end),
}
```

The initial call happens **before the tree is parented**, alongside the value
fire, so the UI is laid out for the current screen before it appears. There
is no resize flash.

Vision keeps one connection to the camera no matter how many `drawcall`s you
declare, and a resize to the same size does not re-run anything. The hook is
released on `Cleanup` and re-established on the next mount, and it follows the
camera being swapped out.

::: tip
On the server there is no camera, so the viewport reads as `Vector2.zero` and
the callback runs once at mount and never again.
:::

## style

```lua
style(Name: string)[Field: string]
```

Binds a property to a field of a loaded style. The property takes the field's
value at mount and follows it afterwards, so changing the field updates every
instance using it.

```lua
{
    ClassName = "Frame",
    BackgroundColor3 = style("Dark")["Surface"],
    ...
}
```

See [Style](/api/style) for loading, updating and the lifecycle rules.

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

## inject

```lua
inject(...: Vision) -> Graft
```

Used as a `mount` target. Instead of naming a place, it asks other Visions
where to put this one.

```lua
mount(inject(Panel))
mount(inject(Panel, Fallback))
```

On mount, each host is tried in order. A host that is **not currently mounted
is skipped**, and the next one is tried. The first host that accepts wins.

If no host accepts - none are mounted, or every [receive](#receive) declines -
the Vision is still built, it is simply **left unparented**. Nothing errors.
Mounting it again retries the placement, so this is the normal pattern:

```lua
Guest:Mount()   -- host is down, nothing is parented
Panel:Mount()
Guest:Mount()   -- retries, and lands
```

## receive

```lua
receive(Callback: (self: Instance, Target: Instance, Source: Vision) -> Instance?) -> Marker
```

Marks a node as a landing site for [inject](#inject). The callback gets the
node's own instance, the instance asking to be parented, and the Vision it
belongs to.

Return an `Instance` to accept - that instance becomes the parent. Return
anything falsy to decline and let the next `receive` try.

```lua
Scope:Capture({
    ClassName = "Frame",
    Name = "Panel",

    receive(function(self, Target, Source)
        return Source.Kind() == "tool" and self
    end),

    {
        ClassName = "Frame",
        Name = "Tray",

        receive(function(self)
            return self
        end),
    },
})
```

A host may hold as many `receive` markers as it likes; they are offered the
instance in declaration order, outermost first. A host with no `receive` never
accepts anything.

Because the callback is handed the incoming Vision, one host can sort many
different guests into different places inside itself.

### Chaining

A guest can host guests of its own, as deep as you like.

```lua
Shell:Mount()
Panel:Mount()   -- lands in Shell
Widget:Mount()  -- lands in Panel
```

### Who holds who

The link runs **one way**. A guest holds its hosts, because the `inject` marker
lives in the guest's own declaration and has to survive a `Cleanup` so the guest
can be mounted again.

A host holds **nothing**. It keeps no list of its guests, weak or otherwise. A
guest instead watches its own instance, and cleans itself up if that instance is
ever destroyed - which is what happens when the host tears its tree down.

```lua
Shell:Cleanup()   -- Panel and Widget clean themselves up too
```

That gives four properties worth relying on:

- Cleaning a host **cascades** to everything grafted into it, and down the
  chain from there.
- The cascade runs **outermost first**: the host's own `cleanup` callbacks run,
  then each guest's as its instance is destroyed.
- Remounting a host brings back **only the host**. It has no idea what used to
  live inside it, so nothing is dragged along.
- A cleaned guest can be dropped on its own, and holding a guest keeps its hosts
  reachable but never the reverse.

So a whole chain of linked Visions, once cleaned and let go of, collects
together - including one that links back on itself.

A cascaded guest is only asleep, not gone. Mount it again and it relinks:

```lua
Shell:Cleanup()
Shell:Mount()   -- empty
Panel:Mount()   -- back inside Shell
```

Because the cascade rides on `Destroying`, destroying a grafted instance from
outside Vision cleans its guest up too.
