{
  theorem.home.shell = {
    enable = true;
    bat.enable = true;
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
    starship.enable = true;

    extraAliases = {
      pi-update = "nix-shell -p nodejs 'python3.withPackages (ps: [ ps.pyyaml ])' --run 'pi update --extensions'";
    };
  };
}
