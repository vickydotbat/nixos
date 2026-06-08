{
  config,
  repository,
  lib,
  ...
}:
let
  home = config.home.homeDirectory;
  trustedProjects = [
    "${home}/Projects/westgate"
    "${home}/Projects/westgate/module"
    "${home}/Projects/westgate/toolkit"
    "${home}/Projects/westgate/assets"
    "${home}/Projects/westgate/devkit"
    "${home}/Obsidian/Echo-Reliquary"
  ];
in
{
  theorem.home.shell = {
    bat.enable = true;

    codex = {
      enable = true;
      superpowers.enable = true;
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
        Be extremely concise. Sacrifice grammar for concision.
      '';
    };

    claude = {
      enable = true;
      unrestricted = true;
      superpowers.enable = true;

      settings = {
        model = "sonnet";
        effortLevel = "high";

        # Optional: use latest Opus for planning, Sonnet for execution.
        # model = "opusplan";

        autoMemoryEnabled = false;
        viewMode = "focus";

        env = {
          CLAUDE_CODE_SKIP_PROMPT_HISTORY = "1";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          CLAUDE_CODE_DISABLE_AUTO_MEMORY = "1";
          CLAUDE_CODE_SUBPROCESS_ENV_SCRUB = "1";
        };
      };

      context = ''
        Be extremely succinct. Sacrifice grammar for concision.
        Keep README.md and documentation human readable.
      '';
    };

    ghostty.enable = true;
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
    zellij.enable = true;
  };
}
