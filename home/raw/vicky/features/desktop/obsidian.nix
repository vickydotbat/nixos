{ ... }:

{
  programs.obsidian.enable = true;

  home.persistence."/nix/persist" = {
    directories = [
      "Obsidian"
    ];
  };
}
