# Design

One principle explains most of Vision's behaviour, and in particular explains
the thing people hit first:

> **Instances are weak. Visions are strong.**

An instance is a disposable rendering of a declaration. A vision, and the
values on it, are the thing that actually persists. Everything below follows
from that.

## Two lifetimes

<svg viewBox="-6 -18 912 400" width="100%" style="max-width: 900px; display: block; margin: 1.5rem auto;" role="img" aria-labelledby="lifetimes-title lifetimes-desc" xmlns="http://www.w3.org/2000/svg">
<title id="lifetimes-title">The declaration, the vision and the instances</title>
<desc id="lifetimes-desc">A declaration is captured into a vision, which mounts into instances. Cleanup destroys the instances Vision made; Mount builds new ones. The vision and its values survive both.</desc>
<defs>
<marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="var(--accent, #4a54d6)" /></marker>
<marker id="arrowmuted" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="var(--muted, #61656f)" /></marker>
</defs>
<rect x="-5" y="-17" width="910" height="398" rx="14" fill="var(--panel, #f7f8fa)" stroke="var(--line, #e3e5ea)" stroke-width="1.5" />
<g font-family="-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica, Arial, sans-serif">
<text x="157" y="24" text-anchor="middle" font-size="15" font-weight="600" fill="var(--text, #24262d)">The declaration</text>
<text x="157" y="43" text-anchor="middle" font-size="12" fill="var(--muted, #61656f)">yours, read at Capture</text>
<text x="451" y="24" text-anchor="middle" font-size="15" font-weight="600" fill="var(--text, #24262d)">The vision</text>
<text x="451" y="43" text-anchor="middle" font-size="12" fill="var(--muted, #61656f)">state, persistent</text>
<text x="747" y="24" text-anchor="middle" font-size="15" font-weight="600" fill="var(--text, #24262d)">The instances</text>
<text x="747" y="43" text-anchor="middle" font-size="12" fill="var(--muted, #61656f)">disposable</text>
<rect x="16" y="58" width="282" height="160" rx="10" fill="var(--code-bg, #f4f5f8)" stroke="var(--line, #e3e5ea)" stroke-width="1.5" />
<rect x="340" y="58" width="222" height="160" rx="10" fill="var(--code-bg, #f4f5f8)" stroke="var(--accent, #4a54d6)" stroke-width="2" />
<rect x="606" y="58" width="282" height="160" rx="10" fill="none" stroke="var(--muted, #61656f)" stroke-width="1.5" stroke-dasharray="5 4" />
<g font-family="ui-monospace, SFMono-Regular, Menlo, Consolas, monospace" font-size="12.5" fill="var(--text, #24262d)">
<text x="32" y="88">{ ClassName = "Frame",</text>
<text x="32" y="110">&#160;&#160;event("Word", ...),</text>
<text x="32" y="132">&#160;&#160;{ ClassName = "TextLabel",</text>
<text x="32" y="154">&#160;&#160;&#160;&#160;Text = fromEvent("Word") } }</text>
<text x="356" y="88">Interface</text>
<text x="356" y="110">&#160;&#160;Word()&#160;&#160;-&gt;&#160;&#160;"written"</text>
<text x="622" y="88">Frame</text>
<text x="622" y="110">&#160;&#160;TextLabel</text>
</g>
<text x="157" y="196" text-anchor="middle" font-size="11.5" fill="var(--muted, #61656f)">what the tree is made of</text>
<text x="451" y="196" text-anchor="middle" font-size="11.5" font-weight="600" fill="var(--accent, #4a54d6)">strong &#183; survives</text>
<text x="747" y="188" text-anchor="middle" font-size="11.5" fill="var(--muted, #61656f)">weak &#183; thrown away and remade,</text>
<text x="747" y="204" text-anchor="middle" font-size="11.5" fill="var(--muted, #61656f)">if Vision made them</text>
<line x1="304" y1="138" x2="334" y2="138" stroke="var(--accent, #4a54d6)" stroke-width="2" marker-end="url(#arrow)" />
<text x="319" y="127" text-anchor="middle" font-size="11.5" fill="var(--accent, #4a54d6)">Capture</text>
<line x1="568" y1="138" x2="600" y2="138" stroke="var(--accent, #4a54d6)" stroke-width="2" marker-end="url(#arrow)" />
<text x="584" y="127" text-anchor="middle" font-size="11.5" fill="var(--accent, #4a54d6)">Mount</text>
<path d="M 870 224 C 894 306, 700 344, 630 288 L 630 226" fill="none" stroke="var(--muted, #61656f)" stroke-width="1.75" stroke-dasharray="5 4" marker-end="url(#arrowmuted)" />
<text x="750" y="338" text-anchor="middle" font-size="12.5" fill="var(--muted, #61656f)">Cleanup destroys them, Mount builds them again</text>
<text x="451" y="252" text-anchor="middle" font-size="12.5" font-weight="600" fill="var(--accent, #4a54d6)">untouched by both</text>
<text x="451" y="272" text-anchor="middle" font-size="11.5" fill="var(--muted, #61656f)">the values are still there</text>
</g>
</svg>

`Cleanup` destroys the instances and keeps the vision. `Mount` builds a new
set from the same declaration and the same values.

The instances Vision **made** are not the same objects after a remount - they
are a fresh rendering that happens to look the same. An instance Vision only
adopted is the same object every time. See
[ownership](#ownership-decides-destruction).

## The creation loop

<svg viewBox="-6 -18 912 566" width="100%" style="max-width: 900px; display: block; margin: 1.5rem auto;" role="img" aria-labelledby="loop-title loop-desc" xmlns="http://www.w3.org/2000/svg">
<title id="loop-title">The creation loop</title>
<desc id="loop-desc">A vision alternates between staged and live. Mount builds the instances in ten ordered steps; Cleanup tears them down in six. The values survive every trip round.</desc>
<defs>
<marker id="loopdown" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="var(--accent, #4a54d6)" /></marker>
<marker id="loopup" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="var(--muted, #61656f)" /></marker>
</defs>
<rect x="-5" y="-17" width="910" height="564" rx="14" fill="var(--panel, #f7f8fa)" stroke="var(--line, #e3e5ea)" stroke-width="1.5" />
<g font-family="-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica, Arial, sans-serif">
<rect x="300" y="8" width="300" height="66" rx="10" fill="var(--code-bg, #f4f5f8)" stroke="var(--accent, #4a54d6)" stroke-width="2" />
<text x="450" y="35" text-anchor="middle" font-size="15" font-weight="600" fill="var(--text, #24262d)">Staged</text>
<text x="450" y="56" text-anchor="middle" font-size="12" fill="var(--muted, #61656f)">the values exist, no instances do</text>
<rect x="300" y="452" width="300" height="66" rx="10" fill="var(--code-bg, #f4f5f8)" stroke="var(--accent, #4a54d6)" stroke-width="2" />
<text x="450" y="479" text-anchor="middle" font-size="15" font-weight="600" fill="var(--text, #24262d)">Live</text>
<text x="450" y="500" text-anchor="middle" font-size="12" fill="var(--muted, #61656f)">instances built and wired</text>
<text x="450" y="-1" text-anchor="middle" font-size="12" fill="var(--muted, #61656f)">Capture puts you here, building nothing</text>
<line x1="392" y1="80" x2="392" y2="446" stroke="var(--accent, #4a54d6)" stroke-width="2" marker-end="url(#loopdown)" />
<text x="404" y="100" font-size="14" font-weight="600" fill="var(--accent, #4a54d6)">Mount</text>
<line x1="508" y1="446" x2="508" y2="80" stroke="var(--muted, #61656f)" stroke-width="2" marker-end="url(#loopup)" />
<text x="520" y="438" font-size="14" font-weight="600" fill="var(--muted, #61656f)">Cleanup</text>
<g font-family="ui-monospace, SFMono-Regular, Menlo, Consolas, monospace" font-size="12" fill="var(--text, #24262d)" text-anchor="end">
<text x="376" y="128">1. Build - make each node's instance</text>
<text x="376" y="159">2. apply fields, styles, attributes, tags</text>
<text x="376" y="190">3. parent every child</text>
<text x="376" y="221">4. Activate - bind handlers to the instances</text>
<text x="376" y="252">5. Settle - resolve the derives</text>
<text x="376" y="283">6. fire every value once, with its current value</text>
<text x="376" y="314">7. Paint - drawcalls, with the viewport size</text>
<text x="376" y="345">8. parent the root</text>
<text x="376" y="376">9. Ready - ready callbacks, deepest first</text>
<text x="376" y="407">10. Attach and Observe - connect everything</text>
</g>
<g font-family="ui-monospace, SFMono-Regular, Menlo, Consolas, monospace" font-size="12" fill="var(--muted, #61656f)">
<text x="524" y="152">1. Forget - the scope stops holding it</text>
<text x="524" y="183">2. Teardown - ready teardowns, then cleanup</text>
<text x="524" y="214">3. cancel the animations it owns</text>
<text x="524" y="245">4. disconnect every connection</text>
<text x="524" y="276">5. destroy the instances it owns</text>
<text x="524" y="307">6. Deactivate - unbind the handlers</text>
</g>
<text x="524" y="368" font-size="12" font-weight="600" fill="var(--accent, #4a54d6)">the values are never touched</text>
</g>
</svg>

`Capture` leaves you at the top with nothing built. Every trip down the left
side makes a complete set of instances; every trip up the right side throws
them away again. The vision and its values sit outside the loop entirely,
which is why a `Cleanup` followed by a `Mount` is a rebuild rather than a
restart.

The order on the left is worth reading once. Every instance exists before any
handler runs, and signals are connected last, after `ready` - which is why
staging a property never triggers your own `PropertyChanged` callback.

It also explains a number people expect to be wrong. Five writes before
`Mount` cost **no** property assignments at all, because nothing is connected
yet. The mount then applies the last value once per binding, exactly as it
would have with no writes.

## What survives a Cleanup

Measured, not asserted. A `Frame` Vision made, declared with
`BackgroundTransparency = 0.25` and an attribute `Role = "Panel"`, poked at by
hand while mounted:

| | before `Cleanup` | after `Mount` again |
| --- | --- | --- |
| the instance itself | `Frame` | a **different** `Frame` |
| a declared property you overwrote by hand | `0.9` | `0.25`, back to the declaration |
| a property you set that the declaration never mentions | `false` | whatever a fresh source gives you |
| a declared attribute you overwrote by hand | `"Touched"` | `"Panel"`, back to the declaration |
| an attribute you added by hand | `"added at runtime"` | gone |
| a declared tag | there | there, re-applied |
| a tag you added by hand | there | gone |
| a child you parented in by hand | there | destroyed with its parent |
| everything Vision connected | wired to this instance | re-wired to the new one |
| a **value** on the vision | `"written"` | `"written"` |
| a property driven by that value | follows it | follows it |

Two rows deserve their footnotes.

"Whatever a fresh source gives you" is the class default for `ClassName`, but
the template's value for `fromClone`. Vision does not reset the property; the
instance is simply new.

And a declared property that a **value** also drives comes back at the value's
setting, not the literal beside it. `Raise` writes the declared fields, then
`Finish` re-fires every value on top. So:

```lua
{ ClassName = "Frame", BackgroundTransparency = 0.25,
  event("Fade", 0.25, function(self, _, Value)
      self.BackgroundTransparency = Value
  end) }
```

after `Fade(0.75)`, a `Cleanup` and a `Mount`, reads `0.75`. The declaration
is re-applied, and then the values are re-applied over it.

## Why properties do not save

Because saving them would mean the instance, not the declaration, was the
source of truth. Vision refuses that on purpose.

**There should be two places to look, not three.** The declaration says what
the tree is made of; the values say what state it is in. Between them they are
a complete account. If a remount also restored arbitrary properties nobody
named, you would need the whole history of the instance as well.

**Reading state back off an instance is lossy.** Roblox properties are typed,
and several coerce what you give them: integer properties truncate a float,
`number` properties are float32 rather than Lua's float64, and some clamp to a
range. State that round-trips through a property is state you may have quietly
changed. A value is plain Lua and holds what you put in it.

**Saving would fight the declaration.** Vision knows exactly which keys the
declaration names, so it could save those. But on the next mount it would have
to choose between the saved value and the declared one, and there is no answer
that is right for both a tweak you want to keep and a default you want back.
Naming the state yourself removes the question.

::: warning A value cannot hold nil
Writing `nil` is how you **read** a value - `Interface.Word()` and
`Interface.Word(nil)` are the same call. So there is no way to clear a value
once it is set. Use `false` or a sentinel of your own for absence.
:::

## So put state in a value

If a property should survive, it is state, and state lives on the vision:

```lua
local Card = Scope:Capture({
    ClassName = "TextLabel",
    Text = fromEvent("Word", "hello"),

    mount(PlayerGui),
})

Card:Mount()
Card.Word("written")     -- state, on the vision

Card:Cleanup()           -- instances destroyed
Card:Mount()             -- Text is "written" again
```

Writing the property directly does not survive:

```lua
local Plain = Scope:Capture({
    ClassName = "TextLabel",
    Text = "hello",

    mount(PlayerGui),
})

Plain:Mount()
Plain:Open().Text = "written"    -- a property on a disposable object

Plain:Cleanup()
Plain:Mount()                    -- Text is "hello" again
```

Both look like they do the same thing. Only one of them is state.

::: tip The rule of thumb
If losing it on a remount would be a bug, it is a value. If it is presentation
that the declaration already describes, leave it a property.
:::

## Ownership decides destruction

`Cleanup` destroys the instances Vision **owns**, and because `Destroy` is
recursive, everything inside them. Ownership is a property of a subtree root,
not of each instance: anything sitting under an owned instance goes with it,
whether Vision made it or not.

| how the node got its instance | owned | `Cleanup` does |
| --- | --- | --- |
| `ClassName = "Frame"` | yes | destroys it, and everything under it |
| `fromClone(Template)` | yes | destroys the copy, never the template |
| `fromInstance(Existing)` | no | disconnects, and leaves the instance standing |
| `FromParent = "Child"` | no | never destroys it directly, but it dies with its host if the host is owned |

Ownership is decided **per node**, and is not inherited downward either. A
`ClassName` or `fromClone` child declared inside a `FromParent` or
`fromInstance` node is still something Vision made, so `Cleanup` destroys it,
at any depth:

```lua
Scope:Capture({
    fromInstance(Shell),             -- kept

    {
        FromParent = "Slot",         -- kept, it was already there

        { ClassName = "UICorner" },  -- destroyed, Vision made it
        { fromClone(Template) },     -- destroyed, Vision made the copy
    },
})
```

The line the rule draws is not "did Vision touch this" but "did Vision make
this" - with the caveat that a `Destroy` arriving from above takes everything
underneath it regardless.

### Adoption is not restoration

An adopted instance is the exception that proves the principle. Vision did not
make it, so this vision will not destroy it, and its properties survive a
`Cleanup`:

```lua
local Kept = Scope:Capture({
    fromInstance(Guest),
    BackgroundTransparency = 0.5,
})

Kept:Mount()
Guest.BackgroundTransparency = 0.8

Kept:Cleanup()          -- Guest still exists, still 0.8
Kept:Mount()            -- 0.5 again, the declaration reapplies
```

Note the last line. Adoption saves the instance from destruction; it does not
make the declaration stop being the source of truth. Mounting reapplies every
declared property over whatever was there.

Two things `Cleanup` does **not** do for an adopted instance:

- It does not undo what Vision wrote. Declared properties, `attributes` and
  `tags` stay exactly as the last mount left them.
- It does not put it back. If the declaration carried a `mount`, the instance
  was moved once and is left where it was moved to.

It is also still an ordinary instance. If it lives inside something another
vision owns, that vision's `Cleanup` destroys it, and the vision that adopted
it will not notice.

## The same principle, elsewhere

**Nothing is created until `Mount`.** `Capture` creates no instances, though it
does parse and validate the declaration, so mistakes surface there.

**A vision can be cloned; the copy is a second rendering, not a second
object.** `Clone` re-reads the same declaration table and copies the values
across. It shares that table with the original rather than snapshotting it, so
mutating the table between two clones changes what the second one builds. A
vision that adopts with `fromInstance` refuses to clone at all - there is only
one of that instance, which is what `fromClone` is for. See
[sleeping and cloning](/tut/crash-course/6-sleeping).

**A guest holds its host, never the reverse.** Under
[inject and receive](/api/keywords), a host keeps no list of what was grafted
into it, so cleaning a host cascades to its guests, but remounting a host
brings back only the host. Declared children are different: they are part of
one declaration, and a remount rebuilds the whole subtree.

**Connections belong to the mount, not the vision.** Everything Vision
connected is disconnected by `Cleanup` and wired again on the next `Mount`,
against the new instances. Your `ready` callbacks run again too, which is why
`ready` hands you a teardown registrar rather than expecting you to track one.

**A cleaned vision leaves its scope.** `Cleanup` calls `Scope:Forget` and
`Mount` calls `Scope:Adopt`, so while a vision is asleep a `Scope:Update` will
not reach it. Writing to the value directly still works, and the write lands
on the next mount.
