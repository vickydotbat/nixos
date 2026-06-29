# Pi Agent Extensions

This directory is reserved for Pi extension seeds that are safe to install as
plain files under `~/.pi/agent/extensions/`.

Do not add extension installers, network setup, model downloads, or other
activation-time work here. Home Manager may seed files, but the running agent
must own any expensive or stateful setup after activation has finished.

## Current State

- `workspace-tools.ts` adds read-only workspace mapping and verification
  suggestion tools.
- `secret-tripwire.ts` classifies secret-looking paths without opening file
  contents.

These extensions are advisory only. They may inspect repository metadata and
changed path names, but they must not install tools, mutate repositories, run
checks automatically, read secret values, or manage Pi runtime state.
