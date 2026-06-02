{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.shell.ghostty;
in
{
  options.theorem.home.shell.ghostty.enable = lib.mkEnableOption "Ghostty terminal";

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      enableBashIntegration = true;
      installBatSyntax = true;

      settings = {
        font-size = 11;
        window-padding-x = 8;
        window-padding-y = 8;
        copy-on-select = "clipboard";
        shell-integration = "detect";

        # Keep a fallback for plain shells. In Zellij sessions, the multiplexer
        # owns pane scrollback and these overlapping shortcuts are passed through.
        scrollback-limit = 100000;

        # Keep terminal behavior simple.
        confirm-close-surface = false;

        # Keep clipboard usable from terminal apps.
        clipboard-read = "allow";
        clipboard-write = "allow";

        # Good when terminal programs set titles.
        window-title-font-family = "inherit";

        # Zellij owns terminal tabs, panes, pane focus, and scrollback navigation.
        keybind = [
          "shift+page_up=unbind"
          "shift+page_down=unbind"
          "shift+home=unbind"
          "shift+end=unbind"
          "ctrl+tab=unbind"
          "ctrl+shift+tab=unbind"
          "ctrl+shift+t=unbind"
          "ctrl+shift+w=unbind"
          "ctrl+shift+o=unbind"
          "ctrl+shift+e=unbind"
          "ctrl+shift+d=unbind"
          "ctrl+shift+enter=unbind"
          "ctrl+shift+f=unbind"
          "ctrl+page_up=unbind"
          "ctrl+page_down=unbind"
          "ctrl+shift+arrow_left=unbind"
          "ctrl+shift+arrow_right=unbind"
          "ctrl+alt+arrow_left=unbind"
          "ctrl+alt+arrow_right=unbind"
          "ctrl+alt+arrow_up=unbind"
          "ctrl+alt+arrow_down=unbind"
          "alt+1=unbind"
          "alt+digit_1=unbind"
          "alt+2=unbind"
          "alt+digit_2=unbind"
          "alt+3=unbind"
          "alt+digit_3=unbind"
          "alt+4=unbind"
          "alt+digit_4=unbind"
          "alt+5=unbind"
          "alt+digit_5=unbind"
          "alt+6=unbind"
          "alt+digit_6=unbind"
          "alt+7=unbind"
          "alt+digit_7=unbind"
          "alt+8=unbind"
          "alt+digit_8=unbind"
          "alt+9=unbind"
          "alt+digit_9=unbind"
        ];
      };
    };
  };
}
