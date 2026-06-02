# GIMP Plugins

This directory is the local GIMP plugin chamber.

## What It Controls

- plugin directories under `plug-ins/`
- Script-Fu files under `scripts/`
- the files made visible to the flake during evaluation

## How To Add A Plugin

Drop GIMP plugin directories into `plug-ins/` and Script-Fu files into `scripts/`.

Add new files to Git before rebuilding. Flakes only see tracked files, and the forge is literal in that exhausting but merciful way.

## Failure Modes

- Untracked plugins will not appear in the flake input.
- A plugin with missing executable bits or runtime dependencies may be present but still fail when GIMP tries to load it.
- Script-Fu files with syntax errors can make GIMP refuse the script rather than forgiving the mistake.

## Maintenance Reminders

Keep plugins grouped by upstream source when possible. Future repair is easier when the origin of a mechanism is visible.
