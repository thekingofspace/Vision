# From Roact

Roact renders a virtual tree and reconciles it. Vision builds a real tree
once and writes properties into it. That is the whole difference; everything
below follows from it.

## The table

| Roact | Vision |
| --- | --- |
| `Roact.createElement("Frame", props, children)` | `{ ClassName = "Frame", ...props, ...children }` |
| a function component | a function returning a declaration table |
| a class component | a function returning a declaration table, plus `event` for its state |
| `self.state` / `self:setState` | `event("Name", Initial, Callback)` and `Interface.Name(Value)` |
| `Roact.Event.Activated = fn` | `Activated = fn` |
| `Roact.Change.Text = fn` | `PropertyChanged = { Text = fn }` |
| `Roact.Ref` | `Interface:Open()` or `ready(function(self) end)` |
| `didMount` | `ready(function(self, vision) end)` |
| `willUnmount` | `cleanup(function(self, vision) end)` |
| `Roact.mount(element, parent, name)` | `Scope:Capture(Declaration)` then `Interface:Mount()` |
| `Roact.unmount(handle)` | `Interface:Cleanup()` |
| `Roact.createFragment` | the array part of a declaration |
| `Roact.createBinding` | `event` plus `merge` |
| `Roact.None` | not needed, nothing merges props |

## A counter

Roact:

```lua
local Counter = Roact.Component:extend("Counter")

function Counter:init()
    self:setState({ Count = 0 })
end

function Counter:render()
    return Roact.createElement("TextButton", {
        Text = `Clicks: {self.state.Count}`,
        [Roact.Event.Activated] = function()
            self:setState({ Count = self.state.Count + 1 })
        end,
    })
end

local Handle = Roact.mount(Roact.createElement(Counter), PlayerGui)
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

There is no `render`. The callback bound to `Count` runs when `Count` changes
and assigns one property. Nothing else in the tree is touched.

## Things that will trip you

**Props do not flow down.** A Roact component takes props and passes them to
children. A Vision function takes plain Lua arguments and bakes them into the
table it returns, once. If a child needs to react to something later, give
the value a name and `merge` onto it from the child.

**State does not live in a component.** It lives on the vision. Any node in
the same declaration can `merge` onto the same name and get its own callback,
so one write can drive twenty instances without a re-render.

**`setState` was batched, value writes are not.** `Interface.Count(1)` runs
its callbacks immediately. Writing the same value twice in a row is skipped,
but two different writes fire twice.

**Reconciliation is gone.** Roact let you return a different tree and worked
out the difference. In Vision the tree is fixed at `Capture`. For a list that
changes, keep a handle per row and mount or clean them yourself.

**Portals are just `mount`.** Any node can carry `mount(SomeInstance)` and
land somewhere other than its parent, including a node named elsewhere in the
same declaration.
