# Values

`event` declares a named value and binds a callback to it.

```lua
local Interface = Scope:Capture({
    ClassName = "TextLabel",
    mount(PlayerGui),

    event("Count", 0, function(self, Value)
        self.Text = `Clicks: {Value}`
    end),
})

Interface:Mount()

Interface.Count(5)   -- label now reads "Clicks: 5"
```

The name becomes a field on the Vision. Call it with nothing to read, with a
value to write. A write returns the value, so it composes:

```lua
local Next = Interface.Count(Interface.Count() + 1)
```

## Staged writes coalesce

Before mounting, a write only stores:

```lua
Interface.Count(1)
Interface.Count(2)
Interface.Count(3)
-- nothing has run

Interface:Mount()
-- the callback runs once, with 3
```

## Unchanged writes are skipped

After mounting, writing the value it already holds does nothing at all:

```lua
Interface.Mode("active")   -- callbacks run
Interface.Mode("active")   -- skipped
```

Which means you can write freely from a loop or a network handler without
checking first.

::: warning
This makes writes idempotent. If you were relying on re-writing the same
value to re-run a callback, it will not fire.
:::

## One value, many instances

This is where it gets useful. `merge` binds another callback to a value
declared elsewhere:

```lua
{
    ClassName = "Frame",
    mount(PlayerGui),

    {
        ClassName = "TextLabel",
        Name = "Percent",

        event("Fill", 0.2, function(self, Value)
            self.Text = string.format("%.0f%%", Value * 100)
        end),
    },

    {
        ClassName = "Frame",
        Name = "Bar",

        merge("Fill", function(self, Value)
            self.Size = UDim2.fromScale(Value, 1)
        end),
    },
}
```

One write updates both, and each callback gets its own `self`:

```lua
Interface.Fill(0.75)
```

Declaring the same name with `event` twice does the same thing as `merge` —
the second declaration adds a binding rather than replacing the value. The
first `InitialValue` wins.

## Next

[Lifecycle](/tut/crash-course/5-lifecycle) — running code at the right time.
