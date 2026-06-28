---
description: Convert a design or larger plan into exactly one bounded implementation packet
agent: context-scout
subtask: true
---

Load `context-discovery`, then choose only the skills needed for this packet.

Do not edit files.
Do not produce a multi-packet implementation plan.
Do not seek perfect certainty before writing a bounded plan.

Convert the requested design, task, or plan into exactly one implementation
packet:

- one packet of work only
- maximum 8 to 10 implementation steps
- smallest practical set of files
- clear verification command or manual verification note
- old workflows that must still be verified
- open questions that would change scope or safety

If the work cannot fit into one packet, split it conceptually and output only
the first packet plus the names of later packets. Stop after the packet plan.

Output:

1. `Packet`: one-sentence scope boundary.
2. `Files likely to change`: shortest practical list.
3. `Steps`: 8 to 10 steps maximum.
4. `Preserve`: old workflows or behavior to verify.
5. `Checks`: exact verification command or manual check.
6. `Stop point`: where the executor must stop.
7. `Open questions`: only questions that block this packet.
