# Migrating

Moving a tree over from another library. Pick the one you came from:

- [From Roact](/mig/from-roact)
- [From React](/mig/from-react)
- [From Fusion](/mig/from-fusion)
- [From Vide](/mig/from-vide)

The per-library pages are lookup tables. This page is the part that is the
same whichever one you are leaving.

## Three shifts

**Nothing exists until you mount.** `Capture` reads your table and returns a
handle without creating a single instance. Writes made before `Mount` only
store, so the tree appears already correct instead of appearing wrong and
being corrected. Every other library on this list builds as it evaluates.

**Nothing re-renders.** There is no virtual tree, no diff, and no reconciler.
A value write calls the callbacks bound to that value, and those callbacks
assign properties. A component function runs once, when you build the
declaration, not again on every change.

**A scope owns the instances.** `Scope:Release()` destroys what the scope
created. This is closer to Fusion's scopes than to Roact or Vide, both of
which leave the instances to you.

## The shared translation

| you had | Vision |
| --- | --- |
| a component | a function returning a declaration table |
| state | `event("Name", Initial, Callback)` |
| derived state | `derive("Name", Compute)` |
| reading state | `Interface.Name()` |
| writing state | `Interface.Name(Value)` |
| an event handler prop | a plain key, `Activated = function(self, vision) end` |
| a property listener | `PropertyChanged = { Text = function(self, vision, Value) end }` |
| an attribute listener | `AttributeChanged = { Role = function(self, vision, Value) end }` |
| render or mount | `Scope:Capture(Declaration)` then `Interface:Mount()` |
| unmount | `Interface:Cleanup()`, or `Scope:Release()` for the lot |
| a ref | `Interface:Open()`, or `ready(function(self) end)` |
| an on-mount effect | `ready` |
| that effect's teardown | the third argument `ready` hands you |
| a per-node teardown | `cleanup(function(self, vision) end)` |
| a portal | `mount(Target)` on the node, pointing anywhere |

Every callback is called as `(instance, vision, ...)`. The instance comes
first, the vision that built it second, and whatever the callback carries
after that. See [declarations](/api/declarations).

## What Vision does not have

Worth knowing before you start, because there is no drop-in for these.

- **No reconciliation.** Nothing compares an old tree to a new one. If a list
  changes you build, mount and clean up the rows yourself.
- **No list helpers.** No `ForValues`, no `indexes`, no keyed children. The
  pattern is `Row:Clone()`, write its values, `:Open()` it and parent it, and
  keep the handle so you can `:Cleanup()` it later.
- **No context.** [inject and receive](/api/keywords#inject) let one vision
  ask another where to put itself, which covers slots and portals, but it is
  not a value channel down a tree.
- **No conditional rendering primitive.** No `show`, no `switch`. Bind a
  value to `Visible`, or mount and clean whole visions.

## What Vision has that you may not have had

- **Sleep and revive.** `Cleanup` destroys the instances and keeps the
  values. `Mount` again rebuilds from the same declaration with the same
  state. See [sleeping](/tut/crash-course/6-sleeping).
- **Two-way derives.** `derive` gets a `Mode` of `"get"` or `"set"`, so a
  computed value can be written to and push back to its sources.
- **Taking instances you did not make.** `fromClone`, `fromInstance` and
  `FromParent` wire a declaration onto an existing instance or a Studio-built
  tree. See [keywords](/api/keywords).
- **Keyframe timelines.** `Scope:Animate` runs a keyframe list against an
  instance or against a vision's values. See [timeline](/api/timeline).
