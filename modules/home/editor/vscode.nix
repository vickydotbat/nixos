{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.editor.vscode;
in
{
  options.theorem.home.editor.vscode = {
    enable = lib.mkEnableOption "Visual Studio Code";

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        mkhl.direnv
        editorconfig.editorconfig
        tamasfe.even-better-toml
        redhat.vscode-yaml
      ];
      description = ''
        VS Code extensions installed by the reusable editor theorem. Keep this
        to repair-useful language and repository support; personal languages,
        assistants, and workflow extensions belong in user modules.
      '';
    };

    userSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {
        # Let Home Manager own the installation state.
        "extensions.autoCheckUpdates" = false;
        "extensions.autoUpdate" = false;
        "update.mode" = "none";

        # Keep telemetry and experiments quiet by default.
        "telemetry.telemetryLevel" = "off";
        "workbench.enableExperiments" = false;

        # Nix support for this repository's primary language.
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.formatterPath" = "nixfmt";
        "nix.serverSettings".nixd.formatting.command = [ "nixfmt" ];
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.formatOnSave" = true;
          "editor.insertSpaces" = true;
          "editor.tabSize" = 2;
        };

        # Keep common generated trees out of search and file watching.
        "search.exclude" = {
          "**/.direnv" = true;
          "**/result" = true;
          "**/result-*" = true;
        };
        "files.watcherExclude" = {
          "**/.direnv/**" = true;
          "**/result/**" = true;
          "**/result-*/**" = true;
        };

        "direnv.restart.automatic" = true;
        "yaml.format.enable" = true;
        "yaml.validate" = true;
        "evenBetterToml.formatter.allowedBlankLines" = 2;
      };
      description = ''
        VS Code user settings installed by the reusable editor theorem. The
        shared layer should stay small and repair-minded; user modules carry
        UI posture, key habits, language stacks, and personal workflow.
      '';
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        nixd
        nixfmt
      ];
      description = "Packages installed alongside VS Code for the shared editor defaults.";
    };

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = config.theorem.home.base.persistence.enable;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = "Persist VS Code global and workspace state when Home persistence is active.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;

      profiles.default = {
        enableExtensionUpdateCheck = false;
        enableUpdateCheck = false;
        extensions = cfg.extensions;
        userSettings = cfg.userSettings;
      };
    };

    home.packages = cfg.extraPackages;

    home.persistence."/nix/persist" = lib.mkIf cfg.persistState {
      directories = [
        ".config/Code/User/globalStorage"
        ".config/Code/User/workspaceStorage"
      ];
    };
  };
}
