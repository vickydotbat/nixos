## NixOS Environment

This machine runs NixOS. Do not assume generic Linux/FHS behavior.

Prefer repository-native commands and existing Nix entry points:

- `flake.nix`
- `shell.nix`
- `devenv.nix`
- `nix develop`
- `nix shell`
- `nix run`
- documented `just`, `make`, package-manager, or test commands

Do not use `apt`, `dnf`, `pacman`, Homebrew, global `pip install`, global `npm install`, or curl-pipe installers unless explicitly asked.

Do not use `sudo`. If privileged access is explicitly required and approved, use `run0`.

Do not start long-running services, containers, model pulls, network waits, or user systemd units from Home Manager activation hooks.

If a repo lacks `flake.nix`, `shell.nix`, or `devenv.nix`, first prefer transient `nix shell` / `nix develop` usage. Create a minimal dev shell or flake only when the task requires reproducible repo-local tooling or the user asks for it.
