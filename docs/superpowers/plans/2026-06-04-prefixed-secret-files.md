# Prefixed Secret Files Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the repository toward prefixed host and user SOPS files without editing encrypted secret payloads.

**Architecture:** Use prefixed secret-file boundaries directly. Root remains host-local in `secrets/hosts-<host>.yaml`; normal-user password hashes and outbound SSH keys share `secrets/users-<name>.yaml`.

**Tech Stack:** NixOS modules, sops-nix, Bash, SOPS YAML creation rules, flake checks.

---

## File Structure

- Modify `.sops.yaml`: add creation rules for prefixed user and host secret files.
- Modify `users/admin/default.nix`, `users/vicky/default.nix`, and `users/mattia/default.nix`: define prefixed account secret files.
- Modify `hosts/solanine/secrets.nix` and `hosts/firelink/secrets.nix`: use prefixed host files and per-user files directly.
- Modify `scripts/update-password-hash`: make normal users default to `secrets/users-<account>.yaml`; require an explicit host file for `root`.
- Modify `scripts/README.md` and `secrets/README.md`: document the new command shape, file classes, manual migration barrier, and failure modes.
- Create `checks/secret-file-boundary.nix`: assert that evaluated host configurations choose the correct secret names and that the repository carries only the expected prefixed creation rules.
- Modify `flake.nix`: include `secret-file-boundary` in `checks.${system}`.

## Task 1: Add Failing Boundary Check

**Files:**
- Create: `checks/secret-file-boundary.nix`
- Modify: `flake.nix`

- [ ] **Step 1: Write the failing check**

Create `checks/secret-file-boundary.nix`:

```nix
{
  inputs,
  pkgs,
}:

let
  inherit (pkgs) lib;
  solanine = inputs.self.nixosConfigurations.solanine.config;
  firelink = inputs.self.nixosConfigurations.firelink.config;
  sopsRules = builtins.readFile ../.sops.yaml;

  hasRule = pattern: lib.hasInfix pattern sopsRules;
  solanineSecretNames = builtins.attrNames solanine.sops.secrets;
  firelinkSecretNames = builtins.attrNames firelink.sops.secrets;
in
assert hasRule "secrets/users-admin\\.yaml$";
assert hasRule "secrets/users-vicky\\.yaml$";
assert hasRule "secrets/users-mattia\\.yaml$";
assert hasRule "secrets/hosts-solanine\\.yaml$";
assert hasRule "secrets/hosts-firelink\\.yaml$";
assert lib.elem "users/admin/password-hash" solanineSecretNames;
assert lib.elem "users/vicky/password-hash" solanineSecretNames;
assert lib.elem "users/admin/password-hash" firelinkSecretNames;
assert lib.elem "users/mattia/password-hash" firelinkSecretNames;
pkgs.runCommand "secret-file-boundary" { } ''
  touch "$out"
''
```

Add it to `checks.${system}` in `flake.nix`:

```nix
secret-file-boundary = import ./checks/secret-file-boundary.nix {
  inherit inputs pkgs;
};
```

- [ ] **Step 2: Run the check and verify it fails**

Run:

```bash
nix build .#checks.x86_64-linux.secret-file-boundary
```

Expected: FAIL because `.sops.yaml` does not yet contain `users-*` or `hosts-*` creation rules.

## Task 2: Add Prefix Rules and Transitional User Metadata

**Files:**
- Modify: `.sops.yaml`
- Modify: `users/admin/default.nix`
- Modify: `users/vicky/default.nix`
- Modify: `users/mattia/default.nix`

- [ ] **Step 1: Update `.sops.yaml` creation rules**

Replace the old unprefixed and `ssh-<user>` rules with prefixed rules:

```yaml
  - path_regex: secrets/hosts-solanine\.yaml$
    key_groups:
      - age:
          - *solanine
  - path_regex: secrets/hosts-firelink\.yaml$
    key_groups:
      - age:
          - *firelink
  - path_regex: secrets/users-admin\.yaml$
    key_groups:
      - age:
          - *solanine
          - *firelink
  - path_regex: secrets/users-vicky\.yaml$
    key_groups:
      - age:
          - *solanine
  - path_regex: secrets/users-mattia\.yaml$
    key_groups:
      - age:
          - *firelink
```

- [ ] **Step 2: Update normal user defaults**

In each normal user file, add these bindings to the `let` block:

```nix
  accountSecretsFile = ../../secrets/users-${thisUser}.yaml;
```

Add this top-level attribute. This is plain registry data, so keep it as a
concrete value instead of using module combinators such as `lib.mkIf`:

```nix
  secrets = {
    sopsFile = accountSecretsFile;
  };
```

Change each `ssh.sopsFile` to:

```nix
    sopsFile = accountSecretsFile;
```

- [ ] **Step 3: Run the boundary check and verify the current failure moves**

Run:

```bash
nix build .#checks.x86_64-linux.secret-file-boundary
```

Expected: still FAIL if host secret wiring has not been updated yet, but the `.sops.yaml` rule assertions should no longer be the failing point.

## Task 3: Update Host Secret Wiring

**Files:**
- Modify: `hosts/solanine/secrets.nix`
- Modify: `hosts/firelink/secrets.nix`

- [ ] **Step 1: Use prefixed host files directly**

In `hosts/solanine/secrets.nix`, replace the host secret binding with:

```nix
  hostSecretsFile = ../../secrets/hosts-solanine.yaml;
```

In `hosts/firelink/secrets.nix`, use:

```nix
  hostSecretsFile = ../../secrets/hosts-firelink.yaml;
```

- [ ] **Step 2: Teach password hash secrets about per-user files**

Replace `mkPasswordSecret` with:

```nix
  mkPasswordSecret = _: user: {
    name = user.passwordHashSecret;
    value = {
      neededForUsers = true;
      sopsFile = user.secrets.sopsFile;
    };
  };
```

This makes normal-user password hashes come from the same prefixed user file as
outbound SSH material.

- [ ] **Step 3: Run the boundary check and verify it passes**

Run:

```bash
nix build .#checks.x86_64-linux.secret-file-boundary
```

Expected: PASS.

## Task 4: Update Password Hash Script and Docs

**Files:**
- Modify: `scripts/update-password-hash`
- Modify: `scripts/README.md`
- Modify: `secrets/README.md`

- [ ] **Step 1: Change script defaults**

Replace `scripts/update-password-hash` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

account="${1:?usage: scripts/update-password-hash <account> [secrets-file]}"
secrets_file="${2:-}"

if [[ -z "$secrets_file" ]]; then
  if [[ "$account" == "root" ]]; then
    printf 'root is host-local; pass the host secrets file explicitly, for example: scripts/update-password-hash root secrets/hosts-solanine.yaml\n' >&2
    exit 2
  fi

  secrets_file="secrets/users-${account}.yaml"
fi

password="$(
  sops --decrypt --extract "[\"users\"][\"${account}\"][\"password\"]" "$secrets_file"
)"

hash="$(mkpasswd -m yescrypt "$password")"

sops set "$secrets_file" "[\"users\"][\"${account}\"][\"password-hash\"]" "\"$hash\""
```

- [ ] **Step 2: Validate the script syntax**

Run:

```bash
bash -n scripts/update-password-hash
```

Expected: PASS with no output.

- [ ] **Step 3: Update documentation**

Update `scripts/README.md` examples to:

```bash
scripts/update-password-hash vicky
scripts/update-password-hash root secrets/hosts-solanine.yaml
```

Update `secrets/README.md` so it names:

```text
secrets/users-<name>.yaml
secrets/hosts-<host>.yaml
```

Document that Codex must not edit encrypted secret payloads directly and that the maintainer must create or migrate those files with `sops`.

## Task 5: Verification and Manual Secret Barrier

**Files:**
- No new files.

- [ ] **Step 1: Run non-secret verification**

Run:

```bash
bash -n scripts/update-password-hash
nix build .#checks.x86_64-linux.secret-file-boundary
nix eval --json .#nixosConfigurations.solanine.config.sops.secrets --apply builtins.attrNames
nix eval --json .#nixosConfigurations.firelink.config.sops.secrets --apply builtins.attrNames
```

Expected: the shell syntax check and source scan pass. Nix evaluation will fail
until the maintainer creates and adds the new encrypted files.

- [ ] **Step 2: Stop for maintainer SOPS migration**

Tell the maintainer to manually create or migrate these encrypted files:

```text
secrets/users-admin.yaml
secrets/users-vicky.yaml
secrets/users-mattia.yaml
secrets/hosts-solanine.yaml
secrets/hosts-firelink.yaml
```

Do not edit those encrypted files from Codex.

- [ ] **Step 3: Resume after manual migration**

After the maintainer confirms the encrypted files exist and are added to Git, run:

```bash
rg -n 'ssh-[a-z]+\.yaml|secrets/(users|hosts)-[a-z]+\.yaml|passwordHashSecret|sopsFile' \
  .sops.yaml hosts users scripts secrets/README.md
nix flake check
nixos-rebuild dry-build --flake .#solanine
nixos-rebuild dry-build --flake .#firelink
```

Expected: prefixed files are referenced, and legacy `ssh-<user>.yaml` and
unprefixed host files are no longer referenced by the source tree.
