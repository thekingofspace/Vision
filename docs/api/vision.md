# Vision

What `Scope:Capture` returns. It holds a staged tree and one CapFunc per
declared value.

```lua
export type Vision = {
    Mount: (self: Vision) -> (),
    Open: (self: Vision) -> Instance,
    Cleanup: (self: Vision) -> (),
    Clone: (self: Vision) -> Vision,
} & { [string]: CapFunc<any> }
```

## Mount

```lua
Interface:Mount()
```

Creates the tree. In order:

1. every instance is created, with properties, attributes, tags and
   connections applied
2. children are parented, resolving any `mount("Name")` targets
3. every value fires **once**, with the value it holds
4. the root is parented to its mount target
5. `ready` callbacks run, deepest first

Calling `Mount` on a Vision that is already mounted does nothing. Mounting a
Vision that was cleaned up rebuilds it - see [Cleanup](#cleanup).

Mount also re-registers the Vision with its scope, so `Scope:Release` covers
it again.

## MountAsync

```lua
Interface:MountAsync(Budget: number?)
```

Builds the tree across frames instead of in one go, yielding whenever the
frame budget is spent. `Budget` is seconds per frame, defaulting to `0.002`.
It yields, so call it from a thread.

```lua
task.spawn(function()
    Interface:MountAsync()
end)
```

**Nothing appears until the whole tree is ready.** The root is parented last,
exactly as in `Mount`, so a partially built tree is never on screen. You get
the hitch spread out, not a half drawn interface.

Use it when a tree is big enough to drop a frame. A hundred rows costs a few
milliseconds and is fine synchronously; a thousand is not.

Calling it on a Vision that is already mounted does nothing, and `Cleanup`
during the build aborts it cleanly, destroying anything already created.

## Open

```lua
local Object = Interface:Open()
```

Mounts if needed and returns the root instance. Idempotent - calling it twice
returns the same instance and does not rebuild anything.

::: warning
`Open` mounts synchronously. During a `MountAsync` that has not finished, the
root instance does not exist yet and `Open` returns `nil`.
:::

## Cleanup

```lua
Interface:Cleanup()
```

Runs `cleanup` callbacks deepest first, cancels any links driving this Vision
or its instances, disconnects every connection, and destroys the root.
Cleaning up twice does nothing.

**Cleanup does not destroy the Vision.** It puts it to sleep. The declaration
and every value survive, and mounting again rebuilds the tree as it was:

```lua
Interface.Count(7)
Interface:Mount()

Interface:Cleanup()
print(Interface.Count())   --> 7

Interface:Mount()          -- rebuilt, callbacks fire once with 7
```

A sleeping Vision behaves exactly like one that has never been mounted -
writes store and nothing runs, so it can keep receiving updates while its
instances are gone, and comes back correct rather than stale.

The scope forgets a sleeping Vision, so `Scope:Release` will not touch it.
Mounting adopts it again.

### Declared cleanups repeat

A `cleanup` declared in the table runs on **every** teardown. A `cleanup`
registered from inside `ready` belongs to that mount only, and is registered
again the next time `ready` runs.

## Clone

```lua
Interface:Clone() -> Vision
```

Copies a Vision without building anything. The copy is captured into the same
scope from the same declaration, so it mounts to the same place, and starts
with the values the original holds right now.

```lua
local Row = Card:Clone()

Row.Title("Second")
Row:Mount()
```

The two share nothing after that - separate instances, separate values.
`Scope:Release` cleans up clones along with everything else.

## CapFunc

Every name passed to `event` becomes a field on the Vision:

```lua
export type CapFunc<v> = (i: v?) -> v
```

Call it with nothing to read, or with a value to write. **A write returns the
new value**, so it reads naturally in an expression.

```lua
Interface.Count()        -- read
Interface.Count(5)       -- write, returns 5
```

### Writes before mount

While staged, a write only stores. Nothing runs. At `Mount` the callback
fires once with whatever the value holds by then.

```lua
Interface.Count(1)
Interface.Count(2)
Interface.Count(3)
-- no callbacks yet

Interface:Mount()
-- callback runs once, with 3
```

### Writes after mount

Every bound callback runs immediately, each with its own instance.

### Unchanged writes are skipped

Writing the value it already holds does nothing - no callbacks, no property
assignments.

```lua
Interface.Mode("active")   -- callbacks run
Interface.Mode("active")   -- skipped entirely
```

Tables are compared by identity, and a table that is not frozen is always
treated as changed, so mutating a table in place and writing it back still
fires.

::: warning
This makes writes idempotent. If you were relying on writing the same value
to re-trigger a callback, it will no longer fire.
:::

## Notes

An event name that collides with `Mount`, `Open` or `Cleanup` raises at
capture time rather than silently shadowing the method.
