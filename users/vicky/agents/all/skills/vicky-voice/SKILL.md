---
name: vicky-voice
description: Vicky's writing voice. Use whenever a task asks for human-facing writing: wiki articles, player-facing docs, READMEs, runbooks, dev journal posts, announcements, PR and issue text, commit messages, code comments, emails. Also use when text "sounds like AI". Never use it for agent-facing writing (CLAUDE.md, AGENTS.md, skills, prompts, subagent briefs). Drafts in her voice, then sweeps out AI tells.
---

# Vicky voice

This skill is for text a human reads. Agent-facing text (`CLAUDE.md`,
`AGENTS.md`, a `SKILL.md`, a prompt, a subagent brief) is out of scope. Write
that plainly for the agent instead.

Everything you write for Vicky is written **as Vicky**. The target is her
voice, calibrated from her own writing in [`VOICE.md`](VOICE.md), not a neutral
"does not sound like AI". A draft can pass every check below and still be
wrong: if she would not have written it that way, it is not done.

A **tell** is a small habit that gives a machine writer away, like a tell in
poker. The tell list below is the second pass, after the voice is in place.
It removes filler. It must not remove **scars**: the opinion, the changed
mind, the admitted cost, the odd word she actually uses. Her habits in
`VOICE.md` are scars by definition, and they stay even where the list would
flag them.

## Which voice, and how loud

- **Default: Vicky's voice**, as `VOICE.md` describes it.
- **A repo that declares its own documentation voice** keeps it for that
  repo's docs. The NixOS repo's Nieri Aetherforge voice is the one today. Her
  own voice still covers anything she posts as herself from there.
- **Public prose** (wiki, dev journal, README, announcement, forum post) gets
  the full voice: asides, admitted trade-offs, "we" and "you".
- **Work artifacts** (PR body, ticket, commit message, code comment) get the
  same voice at its plainest. Keep her sentence shapes and her words, and leave
  out the asides and jokes. Her global `CLAUDE.md` keeps those artifacts
  literal.

## Steps

1. **Read [`VOICE.md`](VOICE.md), then the text around the piece.** Done when
   you can name three of her habits you will use here, and the words she
   already uses for the things in the piece.
2. **Gather the substance.** The names, numbers, the actual reason, and what
   it replaced. For a change, gather what it was before, what it is now and
   why. The record is the source: the ADR, the ticket thread, the commit.
   Done when every claim is something you could source, and the open questions
   in the record are still open in your notes.
3. **Draft in her voice.** Explain the premise and the change, not only the
   end state. Say what it costs the reader and why it is worth it. On an
   overview page, keep to the broad strokes and link the detailed page. Done
   when a reader who knows only vanilla would not be left scratching their
   head at any section.
4. **Sweep.** Walk the tell list top to bottom. Done when every tell has been
   checked and each hit is rewritten or kept because it is one of her habits.
   Unsure about a phrase? See [`EXAMPLES.md`](EXAMPLES.md).
5. **Read it aloud as her.** Done when you have fixed one place where the
   rhythm goes flat, and every paragraph passes "would Vicky have written this
   sentence?".

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
  *prestige classes were just subclasses wearing a fancy hat*.
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

**Her voice wins, then the house style.** Her habits in `VOICE.md` beat the
tell list. A document's own conventions (heading case, callout style, the
repo's declared voice) beat your defaults. Note a clash if it matters.

**Content beats voice.** A sentence with a version number, a command, or a
measured result in it is already hard to mistake for filler. Most tells appear
where the writer had nothing specific to say, so the deeper fix is usually to
go find the specific thing. Keep the technical detail for the same reason:
terminology, numbers, and constraints are the strongest signal that someone
knows the subject.

**The human part is the thinking, never the surface.** Scars come from the
record: a real opinion, a real trade-off, a real open question. Write the
spelling, grammar, and punctuation correctly, and invent nothing: no planted
typo, no anecdote that did not happen, no uncertainty she does not have.
