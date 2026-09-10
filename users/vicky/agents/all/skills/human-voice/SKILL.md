---
name: human-voice
description: Use when writing or revising prose — documentation, READMEs, code comments, articles, blog posts, release notes, PR and issue text, emails — or when the user says text "sounds like AI", "sounds robotic", "sounds sterile", or asks for a plainer voice. Sweeps a draft for AI tells and replaces each with plain human phrasing, keeping the author's opinions and the history of how they got there.
---

# Human voice

A **tell** is a small habit that gives the writer away, like a tell in poker.
Machine-written prose has a known set of them, catalogued by Wikipedia editors
who read a lot of it. Readers spot the tells before they can name them, and the
text loses their trust.

The cure is a **sweep**: draft the piece, then walk the tell list below and
handle every hit. Each tell comes with the plain move that replaces it.

The sweep removes filler. It must not remove **scars** — the failed attempt,
the changed mind, the opinion, the odd word the author actually uses. Those are
the evidence a person did the thing. A draft with every scar sanded off reads
as machine-written even when no tell survives.

## Steps

1. **Sample the voice.** Read a few paragraphs of the surrounding text — the
   rest of the README, older posts, nearby comments. Note how long the
   sentences run, whether it says "we" or "you", how formal it is. Note the
   author's own words too: the recurring joke, the metaphor they reuse, the
   opinion they have already stated. Done when you can state the register in
   one line and name one phrase that is theirs. No surrounding text? Ask, or
   pick plain and say so.
2. **Draft.** Write the piece with real content in it: names, numbers,
   versions, commands, the actual reason. When there is no human author to
   speak for, experience means the record: `git log`, the issue thread, the
   commit that reverted the first attempt. Done when every claim is something
   you could source, and every opinion, dead end, and open question in that
   record still appears in the draft.
3. **Sweep.** Walk the tell list, top to bottom. Done when every tell on the
   list has been checked against the draft, and each hit is either rewritten or
   kept for a stated reason. Unsure whether a phrase counts? See
   [`EXAMPLES.md`](EXAMPLES.md) for before-and-after pairs.
4. **Read it aloud.** Done when you have found one place where the rhythm goes
   flat and fixed it, and every scar from step 2 is still there.

## The tell list

### Words and phrasing

- **Puffery** — *vibrant, rich tapestry, groundbreaking, seamless, robust,
  pivotal, crucial, delve, underscore, testament, landscape, realm, leverage,
  meticulous, comprehensive, paradigm shift, scalable*. Name the concrete thing
  instead: what it does, how fast, for whom.
- **Significance talk** — *marks a pivotal moment, plays a vital role in,
  stands as a key part of, this is where X really shines, the key takeaway is*.
  State the fact and let the reader judge its size.
- **Flattened judgment** — *this ultimately led to the conclusion that the two
  served similar purposes*. If the author has a view, write the view:
  *prestige classes were just subclasses wearing a fancy hat*. Never invent a
  view they have not stated.
- **Participle tails** — a clause hung on the end starting with *highlighting,
  underscoring, showcasing, reflecting, ensuring*. Cut it, or promote it to its
  own sentence with real content in it.
- **Negative parallelism** — *not just X, but Y*; *it isn't X — it's Y*. Say Y.
- **The rule of three** — *fast, simple, and reliable*. Keep the item that
  carries weight. Vary list lengths across the piece; two and four are allowed.
- **Dodging "is"** — *serves as, functions as, stands as, acts as*. Use *is*,
  *are*, *has*.
- **Elegant variation** — swapping in a synonym each time the same thing comes
  up (*constraint*, then *obstacle*, then *confine*). Repeat the one right word;
  repetition reads as precision in technical prose. The author's own odd word
  counts double: keep *crucible* if that is what they say, even where *test rig*
  would be tidier.
- **Vague sourcing** — *experts argue, studies show, it is widely regarded*.
  Name who, or cut the claim.
- **Hedge stacks** — *may potentially help in some cases*. Keep one qualifier,
  or commit. A named unknown is not a hedge: *I don't know yet why the second
  run is slower* says something and stays.
- **Sweep constructions** — *whether it's X or Y*, *from X to Y*. Give the two
  or three real examples that matter.

### Shape

- **Formula endings and joins** — *Despite its X, Y faces challenges*; *In
  conclusion*; *Overall*; *Furthermore*; *Moreover*; *That being said*; *It is
  important to note*. Stop on the last real point, and join with what actually
  happened: *but then*, *the problem was*, *so I tried something else*. Often no
  join is needed.
- **Talking about the writing** — *In this article we will explore*, *Let's
  dive in*, *I hope this helps*, notes about your training or cutoff date.
  Open with the content.
- **Tidy progression** — three attempts rewritten as one inevitable path. Keep
  the order it happened in: what was tried, what broke, what replaced it.
- **Even rhythm** — every paragraph three sentences, every sentence the same
  length. Break it up. A short one lands. Leave a deliberate fragment alone.
- **Symmetry** — every section the same size, both sides of an argument given
  equal room, a summary at the end of each. Let the part the author cares about
  run long and the rest stay short.
- **Quotable everything** — a metaphor or punchline in every paragraph. One
  good phrase beats five attempts at wit. Most sentences exist to get the
  reader from A to B, and that is their whole job.
- **Placeholders** — leftover *[citation needed]*, *[TODO]*, bracketed names.
  Fill them or drop the sentence.

### Formatting

- **Bold on key terms** — emphasis sprinkled over every important noun. Let the
  sentence carry the emphasis; keep bold for the rare word that must not be
  missed.
- **Title Case Headings** — use sentence case, unless the surrounding document
  does otherwise.
- **Inline-header bullets** — a wall of `- **Term**: one line of description`
  where the ideas connect. Write the paragraph; keep bullets for genuinely
  parallel, unconnected items.
- **Numbered everything** — sections numbered for the sake of it, *first /
  second / third* holding up a plain sequence. Structure supports the argument;
  it is not the personality of the piece.
- **Tables and emoji as decoration** — tables for prose, ⭐ and 🎯 as headings.
  Tables hold data with real columns; emoji stay out unless the house style
  uses them.
- **Em dash flood** and **horizontal rules before every heading** — commas,
  periods, and the heading alone do the job.
- **Curly quotes and stray Markdown** — straight quotes, and formatting that
  matches the target format (Markdown, wikitext, plain text, code comment).

## Three rules that outrank the list

**The surrounding text wins.** A house style that title-cases headings or loves
em dashes is the style; match it and note the clash if it matters.

**Content beats voice.** A sentence with a version number, a command, or a
measured result in it is already hard to mistake for filler. Most tells appear
where the writer had nothing specific to say — so the deeper fix is usually to
go find the specific thing. Keep the technical detail for the same reason:
terminology, numbers, and constraints are the strongest signal that someone
knows the subject.

**The human part is the thinking, never the surface.** Scars come from the
record: a real failed attempt, a real opinion, a real open question. Write the
spelling, grammar, and punctuation correctly, and invent nothing — no planted
typo, no anecdote that did not happen, no uncertainty the author does not have.
A draft trying to sound human by performing flaws reads worse than the polished
one it replaced.
