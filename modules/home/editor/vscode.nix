{
  config,
  lib,
  options,
  pkgs,
  ...
}:
# Shared VS Code support for repairing and editing this theorem. The reusable
# layer keeps Nix language support, declarative extension ownership, and quiet
# telemetry defaults; personal workflows belong in user profiles.
let
  cfg = config.theorem.home.editor.vscode;
  hasHomePersistence = options.home ? persistence;
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
        pkief.material-icon-theme
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

        # Use a more useful icon theme
        "workbench.iconTheme" = "material-icon-theme";

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

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
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

      # The upstream VS Code desktop file from nixpkgs omits mimeType, so
      # Dolphin and other XDG-compliant file managers never list VS Code in
      # "Open With". Override it with a complete desktop entry that declares
      # the text and code MIME types VS Code can handle. The user-scoped file
      # in ~/.local/share/applications/ takes precedence over the package
      # desktop file in the Home Manager profile path.
      xdg.desktopEntries.code = {
        name = "Visual Studio Code";
        genericName = "Text Editor";
        comment = "Code Editing. Redefined.";
        exec = "code %F";
        icon = "vscode";
        categories = [
          "Utility"
          "TextEditor"
          "Development"
          "IDE"
        ];
        startupNotify = true;
        type = "Application";

        # Recognized keys not exposed as dedicated options by Home Manager
        # are written via settings (mapped to makeDesktopItem extraConfig).
        # See: https://specifications.freedesktop.org/desktop-entry/latest/recognized-keys.html
        settings = {
          StartupWMClass = "Code";
          Keywords = "vscode;";
        };
        mimeType = [
          "text/plain"
          "text/css"
          "text/html"
          "text/javascript"
          "text/markdown"
          "text/x-c"
          "text/x-c++"
          "text/x-csrc"
          "text/x-chdr"
          "text/x-c++src"
          "text/x-c++hdr"
          "text/x-java"
          "text/x-python"
          "text/x-ruby"
          "text/x-rust"
          "text/x-shellscript"
          "text/x-makefile"
          "text/x-nix"
          "text/xml"
          "application/json"
          "application/javascript"
          "application/x-yaml"
          "application/yaml"
          "application/xml"
          "application/x-shellscript"
        ];
        actions.new-empty-window = {
          name = "New Empty Window";
          exec = "code --new-window %F";
          icon = "vscode";
        };
      };
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persistState) {
        directories = [
          ".config/Code/User/globalStorage"
          ".config/Code/User/workspaceStorage"
        ];
      };
    })
  ];
}
