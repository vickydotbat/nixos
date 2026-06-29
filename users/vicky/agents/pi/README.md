# Pi Agent Guardrails for NixOS Development

This directory carries Pi-specific agent files for Vicky's Home profile. Shared
skills and commands live in `../all`; this tree is for Pi's local working
surface and should not become a shared theorem module.

## Contents

- `agent/AGENTS.md` - global Pi agent instructions
- `agent/APPEND_SYSTEM.md` - Pi system prompt append for this machine
- `extensions/README.md` - notes for future Pi extension seeds

## Usage

`users/vicky/profiles/agents.nix` installs this tree into the paths Pi reads:

- `agent/*` -> `~/.pi/agent/`
- `extensions/*` -> `~/.pi/agent/extensions/`

Pi's mutable state, credentials, sessions, settings, and generated model files
stay outside this directory.
