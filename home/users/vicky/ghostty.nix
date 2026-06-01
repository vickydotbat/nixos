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
    };
  };
}
