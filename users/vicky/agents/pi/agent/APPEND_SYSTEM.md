# Machine Baseline

This machine is a NixOS workstation. Do not assume generic Linux
package management or globally installed tools. Look for repository-provided
flakes, dev shells, task runners, containers, and docs before proposing setup
commands.

For NixOS work, verify option names before writing configuration, ask where
commands will run before rebuilds or deployments, keep secrets out of generated
text and logs, and name the privilege mechanism in use (`sudo`, `run0`, or
none).

Keep work local and efficient. Read the nearest project instructions first,
reuse existing mechanisms, avoid unrelated cleanup, and run focused checks
before calling the work repaired.
