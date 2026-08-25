## DO NOT: Start long-running user services from Home Manager activation

Do not start Podman containers, user systemd services, model pulls, network waits, or other long-running processes from `home.activation.*`.

Bad pattern:

```nix
home.activation.startThing = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  ${pkgs.systemd}/bin/systemctl --user start some-service.service
'';
```

This can block `home-manager` / `switch-to-configuration` activation, especially when the service waits for networking, pulls/builds containers, starts Podman, downloads models, or never reaches an active state. When activation hangs, later rebuilds may fail with `Could not acquire lock`, leaving stale `switch-to-configuration` and `home-manager-generation/activate` processes.

Declarative configuration should create/enable units, not synchronously start them during activation. Prefer one of these:

- `autoStart = true` in the relevant module, if it is known not to block activation.
- A normal systemd user service with `WantedBy = [ "default.target" ]`.
- A timer/socket/path unit.
- Manual start commands for heavyweight operations.
- `systemctl --user start --no-block ...` only if absolutely necessary and after verifying it does not poison activation.

Never put container startup, model pulling, repo cloning, network-online polling, or shell/container orchestration in Home Manager activation hooks.

## DO NOT: Ask the user to paste a secret into a command

Never hand the user a command with a credential inline, and never ask them to
run one in the Claude Code session (the `!` prefix). Anything typed there is
written to the session transcript in plain text, and the transcript is stored on
disk and sent to the model on every later turn. A password on a shell command
line also lands in the shell history and is visible to any process that can read
`/proc`.

Bad pattern:

```
! BUNNY_STORAGE_PASSWORD='<the real password>' scripts/gc.sh --dry-run
```

Do this instead, in order of preference:

- Let the tool prompt. Most of these scripts read the secret off `/dev/tty` with
  `read -rs`, so it is never echoed or logged. Tell the user to run it in their
  own terminal with no credential in the command.
- Read it from the secret store (`sops`, the agenix/sops-nix path for the host)
  inside the command, so the value never appears as text.
- Ask the user to export it in their own shell, outside the session, and then
  run the plain command.

If a secret does reach the transcript, say so plainly and tell the user to
rotate that credential and update anywhere it is stored (CI secrets, `.sops`
files). Do not carry on as if the value is still private.
