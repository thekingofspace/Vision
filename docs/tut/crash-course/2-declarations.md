# Declarations

A declaration is a table. The only required key is `ClassName`.

```lua
{
    ClassName = "TextLabel",
    Text = "Hello",
    Size = UDim2.fromOffset(200, 40),
}
```

Every other string key is set on the instance. Nothing special so far.

## Children

Tables in the array part are children.

```lua
{
    ClassName = "Frame",
    Size = UDim2.fromOffset(300, 200),

    { ClassName = "UICorner", CornerRadius = UDim.new(0, 8) },

    {
        ClassName = "TextLabel",
        Text = "Nested",
    },
}
```

A child parents to the declaration containing it, so the shape of the table
is the shape of the tree.

## Events are just keys

If a key names a signal instead of a property, the value is connected rather
than assigned:

```lua
{
    ClassName = "TextButton",
    Text = "Click me",

    Activated = function(self)
        print("clicked", self.Name)
    end,
}
```

`Text` is assigned, `Activated` is connected, and you did not have to say
which is which - Vision checks what the member actually is.

Notice the callback receives `self`. **Every** callback in Vision gets the
instance first and the vision that built it second, so you can edit the
instance and reach the vision's values without closing over either.

```lua
Activated = function(self, Panel)
    Panel.Count(Panel.Count() + 1)
end,
```

That second argument matters more than it looks: while you are writing a
declaration, the vision it produces does not exist yet, so there is nothing to
close over. This is how you get at it.

## Attributes and tags

```lua
{
    ClassName = "Frame",

    attributes = { Role = "Panel" },
    tags = { "Managed" },

    AttributeChanged = {
        Role = function(self, _, Role)
            print("role is now", Role)
        end,
    },
}
```

`AttributeChanged` connects after the declared attributes are applied, so
setting up initial state does not fire your handler. The new value arrives as
the third argument, so you rarely need `GetAttribute` inside the handler.

## Mounting somewhere else

`mount` says where a node goes. Given an `Instance`, it parents there:

```lua
mount(PlayerGui)
```

Given a string, it finds the node in the same tree with that `Name`:

```lua
{
    ClassName = "ScreenGui",
    mount(PlayerGui),

    { ClassName = "Frame", Name = "Panel" },

    {
        ClassName = "TextLabel",
        mount("Panel"),     -- lands inside Panel
    },
}
```

That is useful when a piece of UI is easier to *write* at the top level than
where it belongs.

## Next

[Staging and mounting](/tut/crash-course/3-mounting) - the part that makes
this different.
