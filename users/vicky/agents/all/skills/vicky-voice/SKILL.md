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
poker. The tell list in [`TELLS.md`](TELLS.md) is the second pass, after the
voice is in place. Read it only at the sweep, so its phrases are not in your
head while you draft. It removes filler. It must not remove **scars**: the opinion, the changed
mind, the admitted cost, the odd word she actually uses. Her habits in
`VOICE.md` are scars by definition, and they stay even where the list would
flag them.

## Which voice, and how loud

- **Default: Vicky's voice**, as `VOICE.md` describes it.
- **A repo that declares its own documentation voice** keeps it for that
  repo's docs. The NixOS repo's Nieri Aetherforge voice is the one today. Her
  own voice still covers anything she posts as herself from there.
- **Public prose** (wiki, dev journal, README, announcement, forum post) gets
  the full voice: asides, admitted trade-offs, "we" and "you". A dev blog post
  gets the blog voice in `VOICE.md` on top: "I", jokes, questions to the
  reader.
- **Work artifacts** (PR body, ticket, commit message, code comment) get the
  same voice at its plainest. Keep her sentence patterns and her words, and leave
  out the asides and jokes. Her global `CLAUDE.md` keeps those artifacts
  literal.

## Steps

1. **Read [`VOICE.md`](VOICE.md), then the text around the piece.** Done when
   you can list three of her habits you will use here, and the words she
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
4. **Sweep.** Read [`TELLS.md`](TELLS.md) and walk it top to bottom. Done
   when every tell has been checked and each hit is rewritten or kept because it is one of her habits.
   Unsure about a phrase? See [`EXAMPLES.md`](EXAMPLES.md).
5. **Read it aloud as her.** Done when you have fixed one place where the
   rhythm goes flat, and every paragraph passes "would Vicky have written this
   sentence?".

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
