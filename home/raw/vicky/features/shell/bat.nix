{ pkgs, ... }:
{
  programs.bat = {
    enable = true;
    config = {
      italic-text = "always";
      pager = "less -FR";
      style = "numbers,changes,header";
      theme = "TwoDark";
    };
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batgrep
      batman
      batwatch
    ];
  };

  home.persistence."/nix/persist" = {
    directories = [
      ".cache/bat"
    ];
  };

  programs.bash = {
    sessionVariables = {
      BAT_PAGER = "less -FR";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };

    shellAliases = {
      cat = "bat --paging=never --style=plain";
      bat = "bat --paging=never";
    };
  };
}
