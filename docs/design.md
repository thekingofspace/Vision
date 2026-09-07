# Design

One principle explains most of Vision's behaviour, and in particular explains
the thing people hit first:

> **Instances are weak. Visions are strong.**

An instance is a disposable rendering of a declaration. A vision, and the
values on it, are the thing that actually persists. Everything below follows
from that.

## Two lifetimes

<svg viewBox="-6 -18 912 382" width="100%" style="max-width: 900px; display: block; margin: 1.5rem auto;" role="img" aria-labelledby="lifetimes-title lifetimes-desc" xmlns="http://www.w3.org/2000/svg">
<title id="lifetimes-title">The declaration, the vision and the instances</title>
<desc id="lifetimes-desc">A declaration is captured into a vision, which mounts into instances. Cleanup destroys the instances; Mount builds new ones. The vision and its values survive both.</desc>
<defs>
<marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
<path d="M 0 0 L 10 5 L 0 10 z" fill="var(--accent, #4a54d6)" />
</marker>
<marker id="arrowmuted" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
<path d="M 0 0 L 10 5 L 0 10 z" fill="var(--muted, #61656f)" />
</marker>
</defs>
<rect x="-5" y="-17" width="910" height="380" rx="14" fill="var(--panel, #f7f8fa)" stroke="var(--line, #e3e5ea)" stroke-width="1.5" />
<g font-family="-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica, Arial, sans-serif">
<text x="145" y="24" text-anchor="middle" font-size="15" font-weight="600" fill="var(--text, #24262d)">The declaration</text>
<text x="145" y="43" text-anchor="middle" font-size="12" fill="var(--muted, #61656f)">yours, immutable</text>
<text x="450" y="24" text-anchor="middle" font-size="15" font-weight="600" fill="var(--text, #24262d)">The vision</text>
<text x="450" y="43" text-anchor="middle" font-size="12" fill="var(--muted, #61656f)">state, persistent</text>
<text x="755" y="24" text-anchor="middle" font-size="15" font-weight="600" fill="var(--text, #24262d)">The instances</text>
<text x="755" y="43" text-anchor="middle" font-size="12" fill="var(--muted, #61656f)">disposable</text>
<rect x="20" y="58" width="250" height="146" rx="10" fill="var(--code-bg, #f4f5f8)" stroke="var(--line, #e3e5ea)" stroke-width="1.5" />
<rect x="335" y="58" width="230" height="146" rx="10" fill="var(--code-bg, #f4f5f8)" stroke="var(--accent, #4a54d6)" stroke-width="2" />
<rect x="630" y="58" width="250" height="146" rx="10" fill="none" stroke="var(--muted, #61656f)" stroke-width="1.5" stroke-dasharray="5 4" />
<g font-family="ui-monospace, SFMono-Regular, Menlo, Consolas, monospace" font-size="12.5" fill="var(--text, #24262d)">
<text x="40" y="88">{ ClassName = "Frame",</text>
<text x="40" y="112">&#160;&#160;Text = "Hello",</text>
<text x="40" y="136">&#160;&#160;event("Word", ...) }</text>
<text x="355" y="88">Interface</text>
<text x="355" y="112">&#160;&#160;.Word = "written"</text>
<text x="355" y="136">&#160;&#160;.Count = 3</text>
<text x="650" y="88">Frame</text>
<text x="650" y="112">&#160;&#160;TextLabel</text>
<text x="650" y="136">&#160;&#160;UICorner</text>
</g>
<text x="145" y="182" text-anchor="middle" font-size="11.5" fill="var(--muted, #61656f)">the source of truth</text>
<text x="450" y="182" text-anchor="middle" font-size="11.5" font-weight="600" fill="var(--accent, #4a54d6)">strong &#183; survives</text>
<text x="755" y="182" text-anchor="middle" font-size="11.5" fill="var(--muted, #61656f)">weak &#183; thrown away and remade</text>
<line x1="276" y1="131" x2="329" y2="131" stroke="var(--accent, #4a54d6)" stroke-width="2" marker-end="url(#arrow)" />
<text x="302" y="120" text-anchor="middle" font-size="11.5" fill="var(--accent, #4a54d6)">Capture</text>
<line x1="571" y1="131" x2="624" y2="131" stroke="var(--accent, #4a54d6)" stroke-width="2" marker-end="url(#arrow)" />
<text x="597" y="120" text-anchor="middle" font-size="11.5" fill="var(--accent, #4a54d6)">Mount</text>
<path d="M 862 210 C 886 292, 700 330, 652 274 L 652 212" fill="none" stroke="var(--muted, #61656f)" stroke-width="1.75" stroke-dasharray="5 4" marker-end="url(#arrowmuted)" />
<text x="757" y="322" text-anchor="middle" font-size="12.5" fill="var(--muted, #61656f)">Cleanup destroys them, Mount builds them again</text>
<text x="450" y="238" text-anchor="middle" font-size="12.5" font-weight="600" fill="var(--accent, #4a54d6)">untouched by both</text>
<text x="450" y="258" text-anchor="middle" font-size="11.5" fill="var(--muted, #61656f)">the values are still there</text>
</g>
</svg>

`Cleanup` destroys the instances and keeps the vision. `Mount` builds a new
set from the same declaration and the same values. The instances after a
remount are **not the same objects** - they are a fresh rendering that happens
to look the same.

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

The order on the left is worth reading once. Instances all exist before any
handler runs, every value fires exactly once rather than once per write, and
signals are connected last, after `ready` - which is why staging a property
never triggers your own `PropertyChanged` callback.

## What survives a Cleanup

Measured, not asserted. A `Frame` declared with `BackgroundTransparency = 0.25`
and an attribute `Role = "Panel"`, then poked at by hand while mounted:

| | before `Cleanup` | after `Mount` again |
| --- | --- | --- |
| the instance itself | `Frame` | a **different** `Frame` |
| a declared property you overwrote by hand | `0.9` | `0.25`, back to the declaration |
| a property you set that the declaration never mentions | `false` | `true`, the class default |
| a declared attribute you overwrote by hand | `"Touched"` | `"Panel"`, back to the declaration |
| an attribute you added by hand | `"added at runtime"` | gone |
| a child you parented in by hand | there | gone |
| a **value** on the vision | `"written"` | `"written"` |
| a property driven by that value | follows it | follows it |

The pattern: anything the declaration says comes back exactly as the
declaration says it. Anything you wrote onto the instance is gone. Anything
held as a value on the vision is still there.

## Why properties do not save

Because saving them would mean the instance, not the declaration, was the
source of truth. Vision refuses that on purpose, for three reasons.

**A declaration has to stay honest.** If a remount restored the last runtime
value instead of the declared one, reading the declaration would no longer
tell you what the tree looks like. You would have to know its whole history.
The declaration is the only place you have to look.

**Reading state back off an instance is lossy.** Roblox properties are typed
and clamped. Write `1.5` to a `Transparency` and read back `1`. Write a
`Color3` and get a quantised one. State that round-trips through a property is
state you have quietly corrupted. Values on a vision are plain Lua and hold
exactly what you put in them.

**Cleanup would have to guess.** To save properties, Vision would have to
decide which of the hundreds on an instance count as state. Every answer is
wrong for somebody. Naming the state yourself is one line and it is never
ambiguous.

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

Compare with writing the property directly, which does not survive:

```lua
Card:Open().Text = "written"    -- a property on a disposable object

Card:Cleanup()
Card:Mount()                    -- Text is "hello" again
```

Both lines look like they do the same thing. Only one of them is state.

::: tip The rule of thumb
If losing it on a remount would be a bug, it is a value. If it is presentation
that the declaration already describes, leave it a property.
:::

## Ownership decides destruction

`Cleanup` destroys what Vision **made**, and nothing else. That is what
"weak" means in practice: Vision assumes it may throw away anything it built,
because it can always build it again.

| how the node got its instance | owned | `Cleanup` does |
| --- | --- | --- |
| `ClassName = "Frame"` | yes | destroys it |
| `fromClone(Template)` | yes | destroys the copy, never the template |
| `fromInstance(Existing)` | no | disconnects and leaves it alone |
| `FromParent = "Child"` | no | disconnects and leaves it alone, but still destroys anything owned that you declared inside it |

Ownership is decided **per node**, not inherited. An unowned node does not
protect its children. A `ClassName` or `fromClone` child declared inside a
`FromParent` or `fromInstance` node is still something Vision made, so
`Cleanup` still destroys it, at any depth:

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

That is the line the rule draws: not "did Vision touch this" but "did Vision
make this".

An adopted instance is the exception that proves the principle. Vision did not
make it, so Vision will not destroy it, so its properties **do** survive a
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

## The same principle, elsewhere

Once you have the idea, several other behaviours stop being surprising.

**Nothing is created until `Mount`.** If instances are disposable there is no
reason to make them early. `Capture` builds nothing, and writes made before
mounting only store. See [staging](/tut/crash-course/3-mounting).

**Values fire once with the last value.** Five writes before `Mount` cost one
property assignment, because the four intermediate instances never existed.

**A vision can be cloned, an instance cannot meaningfully be.** `Clone` copies
the declaration and the values, which is the real content. See
[sleeping and cloning](/tut/crash-course/6-sleeping).

**References run child to parent, never parent to child.** A parent holds
nothing that would keep a cleaned child alive. Cleaning a parent cleans its
children, but remounting a parent does not remount them.

**Connections belong to the mount, not the vision.** Everything Vision
connected is disconnected by `Cleanup` and wired again on the next `Mount`,
against the new instances. Your `ready` callbacks run again too, which is why
`ready` hands you a teardown registrar rather than expecting you to track one.
