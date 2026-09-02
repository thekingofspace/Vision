# Sleeping and cloning

`Cleanup` does not kill a Vision. It puts it to sleep.

The instances are destroyed and the memory goes back, but the Vision keeps
its declaration and every value it held. Mount it again and the tree comes
back exactly as it was.

```lua
Interface.Count(7)
Interface:Mount()      -- built, label reads 7

Interface:Cleanup()    -- instances destroyed, memory freed
print(Interface.Count())  --> 7

Interface:Mount()      -- rebuilt, label reads 7 again
```

This is what makes it practical to close a menu properly instead of just
hiding it. A hidden `ScreenGui` still costs you every instance in it. A
sleeping Vision costs a table.

## Writing while asleep

A sleeping Vision behaves exactly like one that has never been mounted:
writes store, and nothing runs.

```lua
Interface:Cleanup()

Interface.Count(9)     -- stored, no callbacks

Interface:Mount()      -- callback runs once, with 9
```

Which means the world can keep updating while your UI is gone, and when it
comes back it is already correct - it never rebuilds into a stale state and
then catches up.

::: tip
Every `event` and `merge` callback runs once on every mount, with the value
current at that moment. That is true of the first mount and of every revival
after it.
:::

## Scope ownership

While a Vision is asleep, its scope forgets it, so `Scope:Release` will not
touch it. Mounting it again re-registers it. You keep a reference, you keep
control.

```lua
Interface:Cleanup()    -- scope drops it
Scope:Release()        -- does not touch Interface

Interface:Mount()      -- scope adopts it again
```

## Clone

`Clone` copies a Vision without building anything.

```lua
local Copy = Interface:Clone()
```

The copy shares nothing with the original - its own instances, its own
values - but it is built from the same declaration, so it mounts to the same
place.

```lua
local Card = Scope:Capture({
    ClassName = "Frame",
    mount(ListContainer),
    event("Title", "Untitled", function(self, Value)
        self.Name = Value
    end),
})

for _, Entry in Entries do
    local Row = Card:Clone()

    Row.Title(Entry.Name)
    Row:Mount()
end
```

A clone starts with the values the original holds right now, so you can set
up a template once and stamp it out.

Clones are captured into the same scope, so `Scope:Release` cleans up all of
them.

## Next

[Animation](/tut/crash-course/7-animation).
