
{ inputs, pkgs, ... }:

{
  imports = [
    inputs.nix-index-database.homeModules.nix-index
  ];

  # nix-index allows searching for packages containing specific files
  programs.nix-index = {
    enable = true;
    # disable command-not-found (checking package sources on unknown command)
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;
  };
  programs.nix-index-database.comma.enable = true;

  home.persistence."/nix/persist" = {
    directories = [
      ".cache/nix-index"
    ];
  };
}
