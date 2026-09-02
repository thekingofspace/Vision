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

## Building a release model

```bash
lune run scripts/build
```

Writes `Vision.rbxm` for upload and `Vision.rbxmx` for diffs, containing only
the library.

## Developing

```bash
rojo serve
```

Builds the full test place from `default.project.json`, including the
benchmark in `src/client`.

The benchmark compares Vision against [Vide](https://github.com/centau/vide),
which is gitignored. To run it, clone Vide into `src/shared/vide`; without it
the comparison is skipped.

## Docs site

```bash
cd docs
npm install
npm run dev
```
