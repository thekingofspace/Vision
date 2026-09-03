# Style

A style is a named bag of values that declarations bind to. Change a field
and every instance bound to it updates, everywhere, immediately.

It exists because the same handful of properties end up copied across every
button, every card, every label. A style names them once.

```lua
Scope:LoadStyle({
    name = "Dark",
    Surface = Color3.fromRGB(20, 20, 26),
    Ink = Color3.fromRGB(240, 240, 250),
    Accent = Color3.fromRGB(88, 101, 242),
    Title = Enum.Font.GothamBold,
    Radius = 12,
})
```

```lua
Scope:Capture({
    ClassName = "Frame",
    BackgroundColor3 = style("Dark")["Surface"],

    {
        ClassName = "TextLabel",
        TextColor3 = style("Dark")["Ink"],
        Font = style("Dark")["Title"],
    },
})
```

A field is just a value, so a style is not limited to colours. Fonts, sizes,
numbers, `UDim2`, `EnumItem` - anything you would assign to a property.

## Scope:LoadStyle

```lua
Scope:LoadStyle(Declaration: { name: string, [string]: any }) -> Style
```

Creates the style if it does not exist, updates it if it does, and returns
the sheet. `name` identifies it and is not itself a field.

```lua
const Dark = Scope:LoadStyle({ name = "Dark", Surface = Ink, Radius = 12 })
```

Calling it again with the same name updates in bulk. **Fields you do not
mention are left alone**, so you can nudge two values without restating the
whole style.

```lua
Scope:LoadStyle({ name = "Dark", Surface = Accent, Radius = 20 })
```

A declaration without a string `name` raises.

## style

```lua
style(Name: string)[Field: string]
```

The declaration keyword. Reads as `style("Dark")["Surface"]`, or
`style("Dark").Surface` if you prefer - they are the same thing.

It produces a binding, not a value. The property is filled in at **mount**,
which means a tree can be declared before its style exists:

```lua
const Interface = Scope:Capture({
    ClassName = "Frame",
    BackgroundColor3 = style("Dark")["Surface"],
})

Scope:LoadStyle({ name = "Dark", Surface = Ink })   -- still fine

Interface:Mount()
```

Naming a style that was never loaded raises at mount and tells you which one.

::: warning Properties only
Bindings work on properties. `attributes` and `tags` take literal values.
:::

## The sheet

`LoadStyle` returns a `Style`.

### Get

```lua
Dark:Get("Radius")   --> 12
```

### Set

```lua
Dark:Set("Surface", Accent)
```

Writes one field and updates every bound instance. Writing the value it
already holds does nothing, so setting a style in a loop or re-loading it on
a heartbeat is cheap and will not churn `Changed`.

### Name

```lua
Dark.Name   --> "Dark"
```

## Fields cannot be tables

```lua
Scope:LoadStyle({ name = "Bad", Layout = { 1, 2, 3 } })
--> style "Bad" field "Layout" cannot be a table
```

A field has to be a single assignable value. Roblox datatypes are fine -
`Color3`, `UDim2`, `Vector2` and friends are not Lua tables, so they pass.

## Lifecycle

Bindings follow the same rules as every other connection in Vision.

| when | what happens |
| --- | --- |
| `Mount` | fields are read and the instances subscribe |
| field changes | every bound instance is written |
| `Cleanup` | the tree unsubscribes; a destroyed instance is never written again |
| `Mount` again | rebinds, and wakes with whatever the field holds **now** |
| `Clone` | the copy inherits the bindings |
| `Scope:Release` | every sheet drops its users |

A sleeping Vision costs a style nothing. It is not subscribed, it is not
written to, and it picks up the current values when it wakes - not the ones
that were current when it went to sleep.

::: tip Nothing is pinned
A style holds its bound instances weakly and unsubscribes on cleanup, so it
can never keep a discarded or sleeping Vision alive.
:::

## Swapping themes

Because a field updates in place, a theme swap is a handful of writes rather
than a rebuild.

```lua
const Themes = {
    Dark = { Surface = Color3.fromRGB(20, 20, 26), Ink = Color3.fromRGB(240, 240, 250) },
    Light = { Surface = Color3.fromRGB(246, 246, 250), Ink = Color3.fromRGB(24, 24, 30) },
}

const function Wear(Which: string)
    const Skin = Themes[Which]

    Scope:LoadStyle({
        name = "Dark",
        Surface = Skin.Surface,
        Ink = Skin.Ink,
    })
end
```

Nothing rebuilds, nothing remounts, and any tree that is asleep picks up the
new values the next time it mounts.

To fade between themes rather than snap, animate the fields.

## Animating a style

```lua
Scope:SpringStyle(Info: TweenInfo, Target, Fields: { [string]: any }) -> Linker
Scope:PhysicsStyle(Period: number, Damping: number, Target, Fields) -> Linker
```

Animates the fields themselves, so every instance bound to them moves at
once. `Target` is a sheet, a style name, or a list of either.

```lua
Scope:SpringStyle(TweenInfo.new(0.4), Dark, {
    Surface = Color3.fromRGB(246, 246, 250),
    Ink = Color3.fromRGB(24, 24, 30),
})
```

That is a whole theme crossfading, in one call, however many trees are using
it. The solver form carries velocity through an interruption:

```lua
Scope:PhysicsStyle(0.5, 0.7, "Dark", { Radius = 20 })
```

Both return a [Linker](/api/animation#linker) you can `Await` or `Cancel`,
and both claim `(sheet, field)`, so starting a new animation on a field
cancels whatever was driving it. That is the same claim system the instance
and value animations use, so a style animation and a `SpringInstance` on the
same property still resolve sanely.

A field with no current value cannot be animated from, and raises saying so.
`PhysicsStyle` also raises on a field whose type has no numeric components,
such as an `EnumItem` - use `SpringStyle` for those, which switches at the
halfway point.

Sleeping trees are not written to during a style animation and pick up the
finished value when they wake.
