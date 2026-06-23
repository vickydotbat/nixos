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
      ponytail.enable = true;
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

        NixOS machine: avoid generic Linux/FHS assumptions; use dev shells or flakes for missing dependencies.

        # HARD RULES

        Use repo/docs/knowledge-base evidence over guesses. Ask before critical decisions. Never commit or push anything. Never run destructive commands without permission. Never touch secrets or `.sops` data. Never track generated files unless explicitly expected. Document everything you do clearly and concisely. Do not create noisy documentation.
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
