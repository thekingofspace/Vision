# From React

For React Lua, `@jsdotlua/react`, or React through roblox-ts. The mapping is
close to [Roact](/mig/from-roact) with hooks in place of class methods, so
read that page too if you used both.

The shift is the same one: React re-runs your component and diffs the result.
Vision runs your function once, then writes properties from callbacks.

## The table

| React | Vision |
| --- | --- |
| `createElement("Frame", props, ...children)` | `{ ClassName = "Frame", ...props, ...children }` |
| a function component | a function returning a declaration table |
| `useState` | `event("Name", Initial, Callback)` |
| the setter from `useState` | `Interface.Name(Value)` |
| `useMemo` over state | `derive("Name", Compute)` |
| `useEffect(fn, {})` | `ready(function(self, vision, later) end)` |
| the function `useEffect` returns | `later(function(self, vision) end)` inside `ready` |
| `useEffect(fn, { value })` | `merge("Value", fn)` |
| `useRef` on a host node | `Interface:Open()` |
| `useCallback` | nothing, functions are not recreated |
| `useContext` | no equivalent, see below |
| `createRoot(target)` and `root:render(el)` | `Scope:Capture(Declaration)` then `Interface:Mount()` |
| `root:unmount()` | `Interface:Cleanup()` |
| `createPortal(el, target)` | `mount(Target)` on the node |
| `Fragment` | the array part of a declaration |
| `key` | no equivalent, you hold the handle |

## A counter

React:

```lua
local function Counter()
    local Count, SetCount = React.useState(0)

    return React.createElement("TextButton", {
        Text = `Clicks: {Count}`,
        [React.Event.Activated] = function()
            SetCount(Count + 1)
        end,
    })
end

local Root = ReactRoblox.createRoot(PlayerGui)
Root:render(React.createElement(Counter))
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

## Effects

`ready` runs once the tree is built and the root is parented, so measurements
like `AbsoluteSize` are real by then. It hands you a registrar as its third
argument for the teardown half:

```lua
ready(function(self, _, later)
    local Connection = Workspace.ChildAdded:Connect(Handle)

    later(function()
        Connection:Disconnect()
    end)
end)
```

That is `useEffect` with an empty dependency array. For the version with
dependencies, bind to the value instead - `merge("Name", fn)` runs `fn` every
time `Name` changes, and only then.

## Things that will trip you

**Your component body is not a render function.** It runs once, when you
build the table. Anything that has to happen again belongs in a callback
bound to a value.

**There are no stale closures.** The classic bug where a callback captures an
old `Count` cannot happen here. Callbacks are handed the current value as an
argument and the vision as the second, so `Panel.Count()` always reads what
is there now.

**Hooks rules do not apply.** No ordering constraints, no dependency arrays,
no exhaustive-deps lint. `event` and `merge` are markers in a table.

**No context.** The usual answers are to pass the vision into the functions
that build your child declarations, or to use
[inject and receive](/api/keywords) when a child needs to find a parent it
was not declared inside.

**Lists are manual.** There is no `key` and nothing diffs. Build a row
vision, `:Clone()` it per item, write its values, parent `:Open()`, and keep
the handles so you can `:Cleanup()` the ones that leave.
