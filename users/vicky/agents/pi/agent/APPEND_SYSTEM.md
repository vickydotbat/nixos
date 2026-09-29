## NixOS Environment

This machine runs NixOS, not FHS Linux.

- Use repo-native entry points: `flake.nix`, `shell.nix`, `devenv.nix`,
  `nix develop/shell/run`, documented `just`/`make`/package-manager commands.
- Missing deps → transient `nix shell`/`nix develop`. Add a dev shell or flake
  only if the task needs reproducible tooling or the user asks. No `apt`,
  `dnf`, `pacman`, Homebrew, global `pip`/`npm`, or curl-pipe installers.
- Never use `sudo`. Privileged access, once approved, goes through `run0`.
- Home Manager activation hooks must not start long-running services,
  containers, model pulls, network waits, or user systemd units. Declarative
  config creates or enables services.
- Containers run on podman, with no Docker daemon. A `docker` command goes to
  `/run/current-system/sw/bin/docker`, podman's Docker shim. A `docker` from a
  dev shell or `nix shell` wins on PATH and has no daemon behind it. A tool
  that wants a Docker socket takes
  `DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock`.
