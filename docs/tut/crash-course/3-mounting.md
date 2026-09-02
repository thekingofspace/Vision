# Staging and mounting

`Capture` creates nothing. This is the whole point, so it is worth being
concrete about what happens when.

```lua
local Interface = Scope:Capture({
    ClassName = "ScreenGui",
    mount(PlayerGui),
    { ClassName = "Frame", Name = "Panel" },
})

print(PlayerGui:FindFirstChild("ScreenGui"))  --> nil

Interface:Mount()

print(PlayerGui:FindFirstChild("ScreenGui"))  --> ScreenGui
```

Between those two calls you have a tree you can configure, pass around, and
throw away without ever touching the DataModel.

## What Mount does

1. creates every instance, applying properties, attributes, tags and
   connections
2. parents the children, resolving `mount("Name")` targets
3. fires every value **once**
4. parents the root
5. runs `ready` callbacks, deepest first

Step 3 before step 4 is deliberate: the tree is fully configured before it
becomes visible, so nothing flashes a placeholder. Step 5 after step 4 is
also deliberate: by the time `ready` runs, the instance is in the DataModel,
so `AbsoluteSize` and friends are real.

## Open

If you want the instance back, use `Open`:

```lua
local Object = Interface:Open()
```

It mounts if needed and returns the root. Calling it again returns the same
instance - it does not rebuild.

## Cleanup

```lua
Interface:Cleanup()
```

Runs your `cleanup` callbacks, cancels any animation driving this tree,
disconnects everything and destroys the root.

Or tear down everything a scope owns at once:

```lua
Scope:Release()
```

## Next

[Values](/tut/crash-course/4-values) - one value, many instances.
