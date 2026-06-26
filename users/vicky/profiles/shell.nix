{
  config,
  repository,
  lib,
  ...
}:
let
  home = config.home.homeDirectory;
  trustedProjects = [
    "${home}/Obsidian/Echo-Reliquary"
    "${home}/Projects/westgate/repositories"
    "${home}/Projects/westgate/repositories/migration"
    "${home}/Projects/westgate/repositories/migration/sow-assets-manifest"
    "${home}/Projects/westgate/repositories/migration/sow-codebase"
    "${home}/Projects/westgate/repositories/migration/sow-depot"
    "${home}/Projects/westgate/repositories/migration/sow-depot-proxy"
    "${home}/Projects/westgate/repositories/migration/sow-docs"
    "${home}/Projects/westgate/repositories/migration/sow-module"
    "${home}/Projects/westgate/repositories/migration/sow-nodebb"
    "${home}/Projects/westgate/repositories/migration/sow-nodebb-plugin-wiki"
    "${home}/Projects/westgate/repositories/migration/sow-nodebb-theme"
    "${home}/Projects/westgate/repositories/migration/sow-platform"
    "${home}/Projects/westgate/repositories/migration/sow-tools"
    "${home}/Projects/westgate/repositories/migration/sow-topdata"
  ];
in
{
  theorem.home.shell = {
    bat.enable = true;

    codex = {
      enable = true;
      superpowers.enable = true;
      ponytail = {
        enable = true;
        level = "ultra";
      };
      settings = {
        model = "gpt-5.5";
        model_reasoning_effort = "high";
        model_reasoning_summary = "concise";
        model_verbosity = "medium";

        approval_policy = "never";
        sandbox_mode = "danger-full-access";

        web_search = "cached";
        file_opener = "vscode";
        hide_agent_reasoning = true;

        history.persistence = "none";

        sandbox_workspace_write = {
          network_access = true;
          exclude_slash_tmp = false;
          exclude_tmpdir_env_var = false;
          writable_roots = [
            repository.path
            "/nix/var/nix/daemon-socket"
          ];
        };

        shell_environment_policy."inherit" = "core";

        projects = lib.genAttrs trustedProjects (_: {
          trust_level = "trusted";
        });
      };

      context = ''
        # Environment

        NixOS machine:

        - Avoid generic Linux/FHS assumptions.
        - Use dev shells or flakes for missing dependencies.
        - Create dev shells or flakes for repositories that lack them.

        # Hard Rules

        - Ask before making decisions that affect scope, safety, data, or architecture.
        - Prefer the simplest working solution.
        - Do not touch unrelated code.
        - Flag uncertainty instead of guessing.
        - Do not run destructive commands unless explicitly asked.
        - Do not touch secrets, credentials, keys, tokens, or `.sops` data.
        - Never commit to `main`.
        - Never force-push.

        # Branching Rules

        - Reuse the current feature branch unless asked to create a new one.
        - Before creating a new branch, check the current branch.
        - New branches must start from up-to-date `main`, not from another feature branch.
        - Never create stacked branches unless explicitly asked.
        - Never re-use a branch that was merged to the remote and then deleted.

        # Testing Rules

        - Test behavior and public contracts, not implementation details.
        - Tests must catch real regressions, not freeze harmless constants, wording, ordering, or refactors.
        - Do not assert hardcoded internal values unless they are part of the intended public behavior.
        - Avoid snapshots/golden outputs unless the exact output is a stable user-facing contract.
        - Do not write tests merely to increase coverage.

        # Minimalism Rule

        - Use Ponytail-style restraint: try no-code, config-only, deletion-only, or minimal edits before adding new code.
        - Prefer the smallest complete fix; do not add abstractions, helpers, dependencies, or files unless necessary.
        - If expanding scope, explain why the smaller solution is insufficient.

        # Tools

        For Shadows Over Westgate Gitea repositories:

        - `tea` is available in the CLI.
        - Gitea API token path: `/home/vicky/Projects/westgate/repositories/migration/gitea-token`.
        - The token is secret: use it only as an input to authenticated commands.
        - Never print, cat, echo, copy, commit, or expose the token.
        - Use `tea` for authenticated Gitea work such as pushing, committing, creating issues, and opening pull requests.
      '';
    };

    claude = {
      enable = true;
      # unrestricted = true;

      # settings = {
      #   model = "sonnet";
      #   viewMode = "focus";
      # };

      # context = ''
      #   Be extremely succinct. Sacrifice grammar for concision.
      #   Keep README.md and documentation human readable.
      # '';
    };

    # ghostty.enable = true;
    kitty.enable = true;
    git.enable = true;
    nix-index = {
      enable = true;
      commandNotFound.enable = true;
    };
    ripgrep = {
      enable = true;
      arguments = [
        "--hidden"
        "--smart-case"
        "--max-columns=200"
        "--max-columns-preview"

        "--glob=!.git/"
        "--glob=!result"
        "--glob=!result-*"
        "--glob=!.direnv/"
        "--glob=!.devenv/"

        "--colors=line:style:bold"
      ];
    };
    shell.enable = true;
    starship.enable = true;
    zellij.enable = false;
  };
}
