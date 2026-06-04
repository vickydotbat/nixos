{
  config,
  repository,
  ...
}:
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

        projects = {
          "${config.home.homeDirectory}/Projects" = {
            trust_level = "trusted";
          };
          "${config.home.homeDirectory}/Repositories" = {
            trust_level = "trusted";
          };
        };
      };

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
