# Sprites

A sheet names the windows into one image. A flipbook steps through those names
on a clock.

## Sheet

```lua
Vision.Sheet(Declaration) -> Sheet
```

No scope needed - a sheet is plain data you can build once and share.

```lua
local Sprites = Vision.Sheet({
    Image = "rbxassetid://1234",
    Size = Vector2.new(64, 64),

    Idle = Vector2.new(0, 0),
    Walk = Vector2.new(64, 0),
    Tall = { Vector2.new(128, 0), Vector2.new(64, 128) },
})
```

`Image` and `Size` are the defaults for the whole sheet and are both optional.
Every other key is a sprite: a `Vector2` position, or a `{ Position, Size }`
pair when that sprite is a different shape to the rest.

If you would rather keep names and positions in order, the array form does the
same thing:

```lua
Vision.Sheet({
    Size = Vector2.new(32, 32),

    { "Idle", Vector2.new(0, 0) },
    { "Walk", Vector2.new(32, 0) },
    { "Tall", Vector2.new(64, 0), Vector2.new(32, 64) },
})
```

### Showing a sprite

The sheet is callable.

```lua
Sprites(Icon, "Walk")
```

That sets `ImageRectOffset` and `ImageRectSize`, and `Image` too if the sheet
declared one. `Sprites:Apply(Icon, "Walk")` is the same call written out.

A name the sheet does not know is an error rather than a silent blank frame,
because a typo is the usual cause.

| member | behaviour |
| --- | --- |
| `Sheet:Apply(Object, Name)` | show that sprite, returns the object |
| `Sheet:Has(Name)` | is that sprite declared |
| `Sheet:Frames()` | every sprite name, sorted |

A sheet needs a size for every sprite, either its own or the sheet's default,
and says so at build time if one is missing.

## FlipBook

```lua
Scope:FlipBook(Sheet, Object, Frames: { string }, Rate: number?) -> FlipBook
```

Steps one instance through a list of sprite names. `Rate` is frames per second
and defaults to `12`. Every name is checked against the sheet up front, so a
bad frame fails when you build the flipbook rather than part way through
playing it.

```lua
local Run = Scope:FlipBook(Sprites, Icon, { "Idle", "Walk", "Tall" }, 10)

Run.Looped = true
Run:Play()
```

Unlike an animation, a flipbook **does not start on its own** - it waits for
`Play`. Sprites snap from one frame to the next; nothing is interpolated.

| member | behaviour |
| --- | --- |
| `Run:Play()` | start again from the first frame, showing it at once |
| `Run:Stop()` | stop, leaving the current sprite showing |
| `Run:Await()` | yield until it ends or is stopped |
| `Run:Destroy()` | stop it and drop everything it holds |
| `Run.Looped` | wrap at the end instead of stopping |
| `Run.Speed` | multiplier on the rate, `0` pauses |
| `Run.Rate` | frames per second, changeable while playing |
| `Run.Frame` | the frame number currently showing |
| `Run.Finished` | true when it is not playing |

`Looped` can be turned off mid-run and it will finish at the end of the pass.
`Frame` keeps reporting the sprite on screen after it stops, since that is
still what you are looking at.

A flipbook claims `ImageRectOffset` on its instance, so starting a spring on
that property takes it over and stops the flipbook. Destroying the instance
stops it too.

After `Destroy` nothing holds the flipbook and it can fall out of scope.
