# Tools

Two plain functions on the module. Neither needs a scope.

## lint

```lua
Vision.lint(Declaration: Declaration) -> { string }
```

Reads a declaration and reports things that are legal but probably not what
you meant. It returns the list of notes and also writes each one through
`warn`, so calling it and ignoring the result is fine.

```lua
Vision.lint({
    ClassName = "Frame",
    Name = "Row",

    event("Count", 0, function() end),

    { ClassName = "Frame", Name = "Row" },
})
```

```
[vision lint] two nodes are both named "Row" (Frame(Row) and Frame(Row) > Frame(Row)),
              mount by name reaches only the last one
```

It checks for:

| note | why it matters |
| --- | --- |
| two nodes sharing a `Name` | `mount("Name")` resolves to the last one declared |
| a node with no `ClassName` | capturing it errors |
| the same value declared by `event` twice | the later initial value silently wins |
| an `event` whose initial value is a table | every `Clone` shares that one table |
| the same value `derive`d twice | capturing it errors |
| a value named `Mount`, `Open`, `Cleanup`, `MountAsync` or `Clone` | collides with a method, capturing errors |
| a `merge` on a value nothing declares | the value stays `nil` forever |
| a `mount` to a name not in the tree | the node is never parented |
| an `inject` with no hosts | the node is never parented |

An empty list means nothing looked wrong. It is a linter, not a validator -
passing it is not a promise that mounting will work.

## create

```lua
Vision.create(Declaration: Declaration) -> Instance
```

Builds one instance tree from a declaration and returns the root, immediately.
No scope, no Vision, no staging, no values - just the instances.

```lua
local Panel = Vision.create({
    ClassName = "Frame",
    Name = "Panel",
    Size = UDim2.fromOffset(200, 80),

    attributes = { Mood = "calm" },
    tags = { "Panel" },

    Activated = function(self)
        print(self.Name)
    end,

    { ClassName = "UICorner", CornerRadius = UDim.new(0, 8) },
})
```

It honours properties, `attributes`, `tags`, `AttributeChanged`, signal
properties (the instance is still the first argument), children, and a
`mount` marker holding an `Instance`.

Everything else is ignored - `event`, `merge`, `derive`, `ready`, `cleanup`,
`drawcall` and `receive` need a Vision to mean anything. A `style` token
errors, because styles live on a scope.

Reach for it when you want a static tree written in the same shape as the rest
of your interface, without paying for a Vision you will never write to.
