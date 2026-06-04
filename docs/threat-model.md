# Threat Model

This note names the ordinary dangers this repository should handle before it
chases rarer threats. It is a calibration tool for hardening work: every sharp
security option should answer one of these risks, name what it can break, and
leave a repair path visible.

## Primary Risks

- Physical theft or casual local access to Solanine, especially access to
  decrypted home state, browser sessions, SSH identities, and persisted secrets.
- Hostile or careless networks that expose SSH, DNS, browser traffic, package
  downloads, or local discovery surfaces to interference.
- Browser, chat, editor, or game compromise that reaches more of the home
  directory, container engine, network controls, or elevation path than it
  needs.
- Leaked or mishandled secret material: SOPS age keys, user SSH keys, host SSH
  keys, password hashes, browser backup identities, and plaintext recovery
  notes.
- Broken rebuild paths: a hardening option, missing secret, bad flake input, or
  unusable elevation profile that prevents the operator from repairing the
  system.
- Accidental operator damage: destructive disk commands, broad group grants,
  mutable state drift, untracked flake files, or rollback assumptions that do
  not cover user data.

## Non-Goals For The Baseline

- Defending against a fully compromised firmware stack, malicious hardware, or
  an operator coerced into revealing credentials. Those require a separate boot
  chain and operational plan.
- Treating anonymity as the same project as workstation privacy. Browser
  fingerprinting, Tor-style isolation, and account behavior need their own
  profile before they become defaults.
- Importing broad external hardening profiles without translating each option
  into this repository's host signals, rollback path, and compatibility matrix.

## Hardening Gate

Before a new hardening mechanism becomes a default, record:

- the risk it answers
- the host signal that makes it safe to enable
- the workflow it may break
- the rollback or recovery path
- the command, boot test, or runtime check that proves it still serves the host

If the mechanism can lock out boot, login, networking, input devices, secrets,
or elevation, test it first in a specialization, VM, or disposable generation.
Repair remains the first doctrine.
