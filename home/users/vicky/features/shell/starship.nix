{

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
      directory = {
        truncation_length = 4;
        truncate_to_repo = false;
      };
      git_status = {
        ahead = "ahead ";
        behind = "behind ";
        conflicted = "conflicts ";
        deleted = "deleted ";
        diverged = "diverged ";
        modified = "modified ";
        renamed = "renamed ";
        staged = "staged ";
        stashed = "stashed ";
        untracked = "untracked ";
      };
      nix_shell = {
        format = "via [$symbol$state( \\($name\\))]($style) ";
        symbol = "nix ";
      };
    };
  };

  home.persistence."/nix/persist" = {
    directories = [
      ".cache/starship"
    ];
  };
}
