{
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

      # Let Zellij handle scrollback/history.
      scrollback-limit = 0;

      # Keep terminal behavior simple.
      confirm-close-surface = false;

      # Keep clipboard usable from terminal apps.
      clipboard-read = "allow";
      clipboard-write = "allow";

      # Optional: good if you use terminal programs that set titles.
      window-title-font-family = "inherit";

      # Avoid Ghostty tab/split keybind overlap if you mostly use Zellij.
      keybind = [
        "ctrl+shift+t=unbind"
        "ctrl+shift+w=unbind"
        "ctrl+shift+enter=unbind"
        "ctrl+shift+d=unbind"
      ];
    };
  };
}
