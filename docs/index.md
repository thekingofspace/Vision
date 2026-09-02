---
layout: home

hero:
  name: Vision
  text: A declarative instance library for Luau
  tagline: Existence Begins With Perception.
  image:
    src: /logo.svg
    alt: Vision
  actions:
    - theme: brand
      text: Get started
      link: /tut/crash-course/1-introduction
    - theme: alt
      text: API
      link: /api/declarations
    - theme: alt
      text: Comparison
      link: /comparison

features:
  - title: Nothing exists until you mount
    details: Capture returns a handle, not a tree. Stage values, change your mind, throw it away — all before a single Instance is created.
  - title: Writes coalesce while staged
    details: Set a value five times before mounting and the callback runs once, with the last value. After mounting, an unchanged write does nothing at all.
  - title: Sleep it, wake it, keep the state
    details: Cleanup destroys the instances but keeps the values. Mount again and the tree comes back exactly as it was, so you can free memory without losing your place.
  - title: Animation that is really TweenService
    details: Springs take a TweenInfo and read their curve from TweenService:GetValue, matching real Tween behaviour frame for frame.
---

## At a glance

```lua
local Vision = require(ReplicatedStorage.Shared.Vision)

local event, ready, mount = Vision.event, Vision.ready, Vision.mount

local Scope = Vision.Scope()

local Interface = Scope:Capture({
    ClassName = "ScreenGui",
    Name = "Counter",

    mount(PlayerGui),

    {
        ClassName = "TextLabel",
        Name = "Readout",
        Size = UDim2.fromOffset(200, 40),

        event("Count", 0, function(self, Value)
            self.Text = `Clicks: {Value}`
        end),

        ready(function(self)
            print("live:", self.Name)
        end),
    },
})

Interface.Count(7)
Interface.Count(12)

Interface:Mount()
```

Nothing is created until `Mount`. The two writes above coalesce, so the
label's callback runs exactly once, with `12`.

## Installing

Vision is a folder of Luau modules with no dependencies. Drop
`src/shared/Vision` anywhere your code can require it.

```lua
local Vision = require(ReplicatedStorage.Shared.Vision)
```

## Credits

The structure and source concept of this documentation is adapted from
[Vide](https://github.com/centau/vide) by centau, a reactive UI library for
Luau. Vide is also the library Vision is measured against in the
[comparison](/comparison) — it is worth your time regardless of which you
end up using.
