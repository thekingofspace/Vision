# Declarations

A declaration is a plain table describing one instance and its subtree. It is
inert data - building one creates nothing.

```lua
{
    ClassName = "Frame",
    Name = "Panel",
    Size = UDim2.fromOffset(300, 200),

    attributes = { Role = "Panel" },
    tags = { "Managed" },

    AttributeChanged = {
        Role = function(self) print(self:GetAttribute("Role")) end,
    },

    Activated = function(self) print("clicked", self.Name) end,

    mount(PlayerGui),
    ready(function(self) print("live") end),

    { ClassName = "UICorner", CornerRadius = UDim.new(0, 8) },
}
```

## ClassName

The class passed to `Instance.new`. Required **unless** the node takes its
instance from somewhere else - with
[fromClone](/api/keywords#fromclone), [fromInstance](/api/keywords#frominstance)
or `FromParent` below. A declaration with none of those raises
`Declaration requires a ClassName` at capture time.

## FromParent

```lua
FromParent = "ChildName"
```

The third way a node can get its instance: instead of building one, find the
child of that name on the node **around** it.

```lua
Scope:Capture({
    fromClone(Template),
    mount(PlayerGui),

    {
        FromParent = "Label",

        TextSize = 21,

        event("Word", "ready", function(self, _, Value)
            self.Text = Value
        end),
    },

    {
        FromParent = "Icon",
        ImageTransparency = 0.2,
    },
})
```

That is how a tree built in Studio, or a template full of children, gets wired
up: take the root with [fromClone](/api/keywords#fromclone) or
[fromInstance](/api/keywords#frominstance), then reach into it by name. It
nests as deep as you like - a `FromParent` node can hold its own `FromParent`
children.

A taken child is not owned, so it survives a `Cleanup`. A child you declare
normally with a `ClassName` inside a taken node **is** owned, and is destroyed
on cleanup even though its parent is not.

Naming a child that is not there is an error, since the alternative is a node
silently driving nothing.

## Properties

Every other string key is a property or an event connection, decided by what
the member actually is on the created instance:

- if the member is an `RBXScriptSignal`, the value is **connected**
- otherwise the value is **assigned**

```lua
Text = "Hello",                          -- assigned
Activated = function(self) end,          -- connected
```

A property can also follow a value instead of taking a constant, with
[fromEvent](/api/keywords#fromevent):

```lua
Text = fromEvent("Word", "hello"),       -- follows the value "Word"
```

This is why `Text` and `Activated` can sit in the same table without
ceremony. It also means a typo'd property name errors on mount rather than
silently doing nothing.

::: tip Every callback gets the instance, then the vision
A connected callback is called as `Callback(Instance, Vision, ...)` - the
instance it is attached to, the vision that built it, then whatever the signal
passes. This holds for every callback in Vision, so you never have to close
over either one.

```lua
Activated = function(self, Panel)
    Panel.Count(Panel.Count() + 1)
end,
```

The vision is not in scope while you are writing its own declaration, which is
exactly when you want to reach its values. This is how you reach them.

`Vision.create` uses the same order and passes `nil` in the vision slot, so one
declaration works with either.
:::

## Custom classes

A `ClassName` that names a [registered class](/api/classes) resolves through
that class instead of `Instance.new`. The class supplies the real base class
and a tree of its own, and any key matching one of its properties is handed to
the class rather than assigned.

```lua
{
    ClassName = "Chip",
    Size = UDim2.fromOffset(200, 32),
    Text = "hello",
}
```

## attributes

A map of attribute names to values, applied with `SetAttribute` when the
instance is created. Both `attributes` and `Attributes` are accepted.

```lua
attributes = { Role = "Panel", Build = 1 },
```

## tags

Tags applied with `AddTag`. Accepts an array, a set, or a mix. Both `tags`
and `Tags` are accepted.

```lua
tags = { "Managed", "Panel" },
tags = { Managed = true },
```

## AttributeChanged

A map of attribute names to callbacks, connected with
`GetAttributeChangedSignal`. The callback receives the instance, the vision,
then the attribute's new value - no `GetAttribute` call needed.

```lua
AttributeChanged = {
    Role = function(self, Panel, Role)
        print(self.Name, "is now", Role)
    end,
},
```

Connections are made **after** the declared `attributes` are applied, so
setting up initial state does not fire these. They are disconnected by
`Cleanup` along with every other connection.

## PropertyChanged

A map of property names to callbacks, connected with
`GetPropertyChangedSignal`. The callback receives the instance, the vision,
then the property's new value.

```lua
PropertyChanged = {
    AbsoluteSize = function(self, Panel, Size)
        Panel.Wide(Size.X > 600)
    end,
},
```

Like `AttributeChanged`, connections are made **after** the declared
properties are written, so staging a value does not fire these, and `Cleanup`
disconnects them. A remount wires them again against the new instance.

## Children

Any table in the array part that is not a [keyword](/api/keywords) is a child
declaration. By default a child is parented to the declaration that contains
it.

```lua
{
    ClassName = "Frame",

    { ClassName = "UICorner" },
    { ClassName = "TextLabel", Text = "Hi" },
}
```

## Mounting by name

`mount` also accepts a string, which resolves to the node in the same tree
whose declared `Name` matches. This lets a declaration written anywhere land
anywhere.

```lua
{
    ClassName = "ScreenGui",

    { ClassName = "Frame", Name = "Panel" },

    {
        ClassName = "TextLabel",
        mount("Panel"),          -- parented into Panel, not the ScreenGui
    },
}
```

Names are collected during capture, so a `mount("Panel")` may appear before
the node it targets.

## Reserved keys

These keys are read by Vision and never assigned to the instance:

`ClassName`, `FromParent`, `attributes`, `Attributes`, `tags`, `Tags`,
`AttributeChanged`, `PropertyChanged`
