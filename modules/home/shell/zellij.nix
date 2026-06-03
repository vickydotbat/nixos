{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.theorem.home.shell.zellij;
in
{
  options.theorem.home.shell.zellij = {
    enable = lib.mkEnableOption "Zellij terminal multiplexer";

    bashIntegration.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.theorem.home.shell.shell.enable or true;
      defaultText = lib.literalExpression "theorem.home.shell.shell.enable";
      description = "Enable Zellij integration for the repository's Bash shell theorem.";
    };

    scrollbackEditor = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.helix}/bin/hx";
      description = "Editor command used by Zellij for scrollback inspection.";
    };

    ghosttyKeybindings.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.theorem.home.shell.ghostty.enable or false;
      defaultText = lib.literalExpression "theorem.home.shell.ghostty.enable";
      description = ''
        Install Ghostty-style Zellij keybindings. Disable this when another
        terminal should keep ownership of those chords.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      # Home Manager's generated hook starts Zellij in every interactive Bash.
      # The guarded hook below keeps editor-embedded terminals usable.
      enableBashIntegration = false;
      attachExistingSession = false;
      exitShellOnExit = false;

      settings = {
        # Start as an explicit workspace. Hidden controls make the mechanism
        # harder to repair when Ghostty and Zellij disagree about ownership.
        show_startup_tips = false;
        show_release_notes = false;
        default_mode = "normal";
        default_layout = "default";
        simplified_ui = false;
        pane_frames = true;
        auto_layout = true;

        # Mouse and clipboard.
        mouse_mode = true;
        copy_clipboard = "system";
        copy_command = "${pkgs.wl-clipboard}/bin/wl-copy";
        copy_on_select = true;

        # Scrollback.
        scroll_buffer_size = 50000;
        scrollback_editor = cfg.scrollbackEditor;

        # Sessions.
        session_serialization = true;
        serialize_pane_viewport = true;
        scrollback_lines_to_serialize = 10000;
      };

      extraConfig = lib.mkIf cfg.ghosttyKeybindings.enable ''
        keybinds {
            normal {
                // Ghostty-like chords, owned by Zellij once Ghostty passes them through.
                bind "Ctrl Shift t" { NewTab; }
                bind "Ctrl Shift w" { CloseTab; }
                bind "Ctrl Shift o" { NewPane "Right"; }
                bind "Ctrl Shift e" "Ctrl Shift d" { NewPane "Down"; }
                bind "Ctrl Shift Enter" { ToggleFocusFullscreen; }

                bind "Ctrl Tab" "Ctrl PageDown" { GoToNextTab; }
                bind "Ctrl Shift Tab" "Ctrl PageUp" { GoToPreviousTab; }
                bind "Alt 1" { GoToTab 1; }
                bind "Alt 2" { GoToTab 2; }
                bind "Alt 3" { GoToTab 3; }
                bind "Alt 4" { GoToTab 4; }
                bind "Alt 5" { GoToTab 5; }
                bind "Alt 6" { GoToTab 6; }
                bind "Alt 7" { GoToTab 7; }
                bind "Alt 8" { GoToTab 8; }
                bind "Alt 9" { GoToTab 9; }

                bind "Ctrl Alt Left" { MoveFocus "Left"; }
                bind "Ctrl Alt Right" { MoveFocus "Right"; }
                bind "Ctrl Alt Up" { MoveFocus "Up"; }
                bind "Ctrl Alt Down" { MoveFocus "Down"; }

                bind "Shift PageUp" { SwitchToMode "Scroll"; PageScrollUp; }
                bind "Shift PageDown" { SwitchToMode "Scroll"; PageScrollDown; }
                bind "Shift Home" { SwitchToMode "Scroll"; ScrollToTop; }
                bind "Shift End" { ScrollToBottom; }
                bind "Ctrl Shift f" { SwitchToMode "EnterSearch"; SearchInput 0; }
            }
        }
      '';
    };

    home.sessionVariables = {
      ZELLIJ_AUTO_ATTACH = "true";
      ZELLIJ_AUTO_EXIT = "false";
    };

    programs.bash.initExtra = lib.mkIf cfg.bashIntegration.enable ''
      _theorem_zellij_should_start() {
        case "$-" in
          *i*) ;;
          *) return 1 ;;
        esac

        [ -t 0 ] && [ -t 1 ] || return 1
        [ -z "''${ZELLIJ:-}" ] || return 1
        [ "''${TERM:-}" != "dumb" ] || return 1

        case "''${TERM_PROGRAM:-}" in
          vscode|vscode-insiders) return 1 ;;
        esac

        [ -z "''${VSCODE_INJECTION:-}" ] || return 1
        [ -z "''${VSCODE_IPC_HOOK_CLI:-}" ] || return 1
        [ -z "''${INSIDE_EMACS:-}" ] || return 1
      }

      if _theorem_zellij_should_start; then
        eval "$(${lib.getExe config.programs.zellij.package} setup --generate-auto-start bash)"
      fi
    '';

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        ".cache/zellij"
        ".local/share/zellij"
      ];
    };
  };
}
