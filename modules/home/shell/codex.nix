{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.shell.codex;
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

    home.persistence."/nix/persist" = {
      # FIXME: Only persist if persistence is actually active.
      directories = [
        ".codex"
      ];
    };

    # FIXME This should allow declarative edits of the codex configuration. If this isn't the right way to do this, changeme.
    home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p "$HOME/.codex"
            cat > "$HOME/.codex/config.toml" <<'EOF'
      ${codexConfig}
      EOF
            chmod 600 "$HOME/.codex/config.toml"
    '';
  };
}
