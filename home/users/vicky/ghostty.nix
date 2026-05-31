{
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    installBatSyntax = true;
    
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;
      theme = "catppuccin-mocha";
      window-padding-x = 8;
      window-padding-y = 8;
      copy-on-select = "clipboard";
      shell-integration = "detect";
    };
  };
}