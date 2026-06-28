{
  theorem.home.shell = {
    bat.enable = true;

    # ghostty.enable = true;
    kitty.enable = true;
    git.enable = true;
    nix-index = {
      enable = true;
      commandNotFound.enable = true;
    };
    ripgrep = {
      enable = true;
      arguments = [
        "--hidden"
        "--smart-case"
        "--max-columns=200"
        "--max-columns-preview"

        "--glob=!.git/"
        "--glob=!result"
        "--glob=!result-*"
        "--glob=!.direnv/"
        "--glob=!.devenv/"

        "--colors=line:style:bold"
      ];
    };
    shell.enable = true;
    starship.enable = true;
    zellij.enable = false;
  };
}
