# Vision

> Existence Begins With Perception.

A declarative instance library for Luau. Describe a tree as a table, stage
data into it, and create it when you are ready.

```lua
local Vision = require(ReplicatedStorage.Shared.Vision)

local Scope = Vision.Scope()

local Interface = Scope:Capture({
    ClassName = "TextLabel",
    Vision.mount(PlayerGui),

    Vision.event("Count", 0, function(self, Value)
        self.Text = `Clicks: {Value}`
    end),
})

Interface.Count(12)
Interface:Mount()
```

Documentation lives in [docs/](docs).

## Toolchain

Tools are managed with [Rokit](https://github.com/rojo-rbx/rokit).

```bash
rokit install
```

## Building

```bash
lune run scripts/build
```

Writes three files:

| file | what it is |
| --- | --- |
| `Vision.rbxm` | the library on its own, upload this to a release |
| `Vision.rbxmx` | the same thing as xml, readable in diffs |
| `Vision.rbxl` | a place with the library and the showcases, open it and press play |

The two model files contain only the library. The place is built from
`default.project.json` and is the quickest way to try the showcases without
running Rojo.

## Developing

```bash
rojo serve
```

Live syncs the same place, for working on the showcases.

On play you get a menu, itself built with Vision, offering three showcases:

- **Interface** - thirteen screens covering values, derives, styles, both spring
  families, cloning, injection, particles and keyframe timelines. `K` moves
  between them, `T` swaps the theme.
- **Blast door** - one heavy slab driven by keyframe timelines, with three
  buttons on the wall for its three animations.
- **Entities** - `fromInstance` and `fromClone` side by side. Click one to clean
  it up and watch which parts survive, `R` brings them back.