{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.shell.codex;
  persistenceEnabled = config.theorem.home.base.persistence.enable;
  system = pkgs.stdenv.hostPlatform.system;
  codexConfig = ''
    model = "gpt-5.5"
    model_reasoning_effort = "high"
    model_reasoning_summary = "concise"
    model_verbosity = "medium"

    approval_policy = "never"
    sandbox_mode = "workspace-write"

    web_search = "cached"
    file_opener = "vscode"
    hide_agent_reasoning = true

    [history]
    persistence = "none"

    [sandbox_workspace_write]
    network_access = false
    exclude_slash_tmp = true
    exclude_tmpdir_env_var = true

    [shell_environment_policy]
    inherit = "core"
  '';
in
{
  options.theorem.home.shell.codex.enable = lib.mkEnableOption "Codex CLI";

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.codex-cli-nix.packages.${system}.default
    ];

    home.persistence."/nix/persist" = lib.mkIf persistenceEnabled {
      directories = [
        ".codex"
      ];
    };

    home.file.".codex/config.toml".text = codexConfig;
  };
}
