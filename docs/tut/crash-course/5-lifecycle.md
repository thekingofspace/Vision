# Lifecycle

Two keywords run code at the edges of a tree's life.

## ready

`ready` runs after the instance exists and the root is parented.

```lua
{
    ClassName = "Frame",
    Size = UDim2.fromOffset(300, 200),

    ready(function(self)
        print(self.Name, self.AbsoluteSize)
    end),
}
```

Because the root is already parented, measurements like `AbsoluteSize` are
real by the time your callback runs.

Callbacks run **deepest first**, climbing the tree. A child is fully set up
before its parent's `ready` runs, so a parent can rely on its children.

```
Title -> Panel -> ScreenGui
```

## cleanup

`cleanup` runs when the tree is torn down, before anything is disconnected or
destroyed - so the instance is still usable.

```lua
cleanup(function(self)
    print("releasing", self.Name)
end),
```

## The useful form

`cleanup` can also be called **inside** a `ready` callback, where it attaches
to the node currently running. This is the form you will reach for most,
because it puts a connection and its disconnect in the same place:

```lua
ready(function(self)
    local Connection = Workspace.ChildAdded:Connect(Handler)

    cleanup(function()
        Connection:Disconnect()
    end)
end),
```

No bookkeeping table, no remembering to tidy up somewhere else.

## Ordering

Cleanups run deepest first across nodes, matching `ready`. Within a single
node they run **last registered first**, so anything you set up in `ready` is
released before the `cleanup` you declared in the table.

## What Cleanup does

```lua
Interface:Cleanup()
```

1. runs `cleanup` callbacks, deepest first
2. cancels any animation driving this tree
3. disconnects every connection
4. destroys the instances

What it does *not* do is throw away your values. That is the next page.

## Next

[Sleeping and cloning](/tut/crash-course/6-sleeping).
