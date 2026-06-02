{ ... }:

{
  programs.ripgrep = {
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
}
