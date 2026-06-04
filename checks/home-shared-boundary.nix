{
  inputs,
  pkgs,
  repository,
  stable,
  userRegistry,
}:

# Synthetic Home Manager profile used as a boundary proof. It imports the
# reusable Home module tree without a NixOS `osConfig` and without any
# `users/vicky` profile, so `nix flake check` can catch shared-module drift into
# one operator's working surface.
let
  selectedUsers = { };
in
(inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;

  extraSpecialArgs = {
    inherit
      inputs
      repository
      selectedUsers
      stable
      userRegistry
      ;
  };

  modules = [
    (inputs.impermanence + "/home-manager.nix")
    inputs.plasma-manager.homeModules.plasma-manager
    (inputs.import-tree ../modules/home)
    {
      home = {
        username = "boundary";
        homeDirectory = "/tmp/home-boundary";
        stateVersion = "25.11";
        enableNixpkgsReleaseCheck = false;
        _nixosModuleImported = true;
      };

      programs.home-manager.enable = false;

      theorem.home = {
        base = {
          persistence.enable = false;
          ssh.enable = false;
        };

        shell = {
          git.enable = false;
          ripgrep.enable = true;
          shell = {
            enable = true;
            nixosAliases.enable = false;
            elevationAlias.enable = false;
          };
        };
      };
    }
  ];
}).activationPackage
