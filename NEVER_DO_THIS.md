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
