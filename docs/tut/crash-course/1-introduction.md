# Introduction

Vision is a declarative instance library. You describe a tree as a table, and
Vision builds it when you say so.

The idea it is built around: **nothing is created until you mount**.

```lua
local Vision = require(ReplicatedStorage.Shared.Vision)

local Scope = Vision.Scope()

local Interface = Scope:Capture({
    ClassName = "Frame",
    Name = "Panel",
    Size = UDim2.fromOffset(300, 200),
})

-- PlayerGui is still empty here. Nothing has been made.

Interface:Mount()

-- now the Frame exists
```

`Capture` reads your table and hands back a handle. It creates nothing. That
gap between describing and building is where the library earns its keep: you
can stage data into a tree that does not exist yet, and when it finally
appears it appears already correct.

## Why staging matters

The usual shape of UI code is: create the instances, then correct them as
data arrives. That means the first frame shows placeholder text, and every
update between then and now costs a property write.

With Vision, writes made before `Mount` only store:

```lua
Interface.Count(1)
Interface.Count(2)
Interface.Count(3)

Interface:Mount()   -- the callback runs once, with 3
```

Three writes, one callback, and the label never displayed a stale value.

## The three pieces

**Scope** — owns your Visions and the animation runtime.

**Declaration** — a plain table describing one instance and its children.

**Vision** — what `Capture` returns. It has `Mount`, `Open` and `Cleanup`,
plus one callable value per name you declared.

```lua
local Scope = Vision.Scope()          -- 1
local Interface = Scope:Capture({ }) -- 2 in, 3 out
```

## Next

[Declarations](/tut/crash-course/2-declarations) — how to describe a tree.
