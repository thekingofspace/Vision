# Classes

A custom class is a name you can put in `ClassName` that Vision resolves to a
real instance plus a tree of its own.

```lua
Vision.class("Chip", {
    Base = "Frame",

    Properties = { Image = "", Text = "" },

    Construct = function(Made)
        return {
            { ClassName = "ImageLabel", Name = "Icon", Image = Made.Image },
            { ClassName = "TextLabel", Name = "Label", Text = Made.Text },
        }
    end,

    Changed = {
        Text = function(self, _, Value)
            self:FindFirstChild("Label").Text = Value
        end,
    },
})
```

```lua
Scope:Capture({
    ClassName = "Chip",
    Size = UDim2.fromOffset(200, 32),

    Image = "rbxassetid://100",
    Text = "hello",
})
```

Every creation checks the registry first. A `ClassName` that is registered
builds through the class; anything else goes straight to `Instance.new` as
before, so nothing changes for declarations that do not use one.

## The definition

```lua
Vision.class(Name: string, Definition) -> string
```

| field | what it is |
| --- | --- |
| `Base` | required, the real `ClassName` the class is built on |
| `Construct` | required, a function taking the resolved properties and returning a declaration |
| `Properties` | a map of custom property names to **default values** |
| `Changed` | a map of property names to callbacks, run when a bound value moves |

`Construct` may return one declaration, or a table whose array part is a list
of them. Both of these are fine:

```lua
Construct = function(Made)
    return { ClassName = "UICorner", CornerRadius = UDim.new(0, 4) }
end
```

```lua
Construct = function(Made)
    return {
        { ClassName = "UIListLayout" },
        { ClassName = "TextLabel", Text = Made.Text },
    }
end
```

What it returns becomes children of the instance, built before any children
you declared yourself.

## Custom properties

A key that matches one of the class's `Properties` is **not** written to the
instance. It is collected, defaulted, and handed to `Construct` as `Made`.

```lua
{
    ClassName = "Chip",

    Size = UDim2.fromOffset(200, 32),   -- a real Frame property, assigned
    Text = "hello",                     -- a custom property, given to Construct
}
```

They are not properties and they are not attributes. Nothing about the class
is written onto the instance, so `Body.Text` and `Body:GetAttribute("Text")`
are both nil. The class's own tree is where the value ended up.

Every property needs a default. Leave one out of a declaration and the
default is what `Construct` sees.

## Changing one afterwards

Bind it to a value with [fromEvent](/api/keywords#fromevent). The class's
`Changed` callback for that property runs on every write, with the usual
`(instance, vision, value)`:

```lua
Scope:Capture({
    ClassName = "Frame",

    event("Word", "one", function() end),

    { ClassName = "Chip", Text = fromEvent("Word") },
})
```

`Interface.Word("two")` runs `Chip`'s `Changed.Text` against that node. Any
number of nodes can follow the same value, and one write moves all of them.

The constructor sees the value too. `Construct` is handed the value's current
setting rather than the property default, so the first build is already
correct rather than being corrected a moment later.

Binding a property the class does not watch is an error, because nothing
would happen:

```
class "Chip" cannot follow a value on "TextSize", it does not watch that property
```

## Rules

- A name can only be registered once.
- A class cannot extend another class. `Base` has to be a real Roblox
  `ClassName`.
- Every entry in `Changed` has to name one of the class's `Properties`.
- `Construct` has to build something. Returning an empty table is an error.
- The rest of Vision is unchanged: `Cleanup` destroys the whole tree the class
  built, a remount rebuilds it, and `Clone` gives the copy its own.

## Adding one to your own game

Register before you capture anything that uses it. Anywhere that runs once is
fine - the top of a module, or a small file that only registers:

```lua
local Vision = require(ReplicatedStorage.Packages.Vision)

Vision.class("Chip", { ... })

return true
```

```lua
require(script.Parent.Classes.Chip)

local Card = Scope:Capture({ ClassName = "Chip", Text = "hello" })
```

The registry is global to the Vision module, so a class registered on the
client is not registered on the server. Register on both if both build it.

## Adding one to Vision itself

The same call, from inside the library. Put the class in its own module under
`src/shared/Vision/`, require it from `init.luau` so registration happens when
Vision is first required, and add it to the module list in
`scripts/build.luau`'s harness so it ships.

Vision does not ship any classes of its own. Every class is one you or your
game registered, which keeps the library's surface to the primitives and
leaves naming to you.
