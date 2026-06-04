{
  inputs,
  self,
  system,
  stable,
  userRegistry,
  hostPath,
  selectedUsers,
  repository ? {
    path = "/nix/nixos";
    group = "nixcfg";
  },
}:

# Shared host constructor for this flake. It wires the reusable system module
# tree, host facts, overlays, and Home Manager together around the selected user
# set. Keep trust boundaries visible here: `selectedUsers` decides which account
# doctrines a host receives, while `homeUsers` filters that set down to accounts
# allowed to import Home Manager code into the system evaluation.
let
  lib = inputs.nixpkgs.lib;
  homeUsers = lib.filterAttrs (_: user: user.home.enable or false) selectedUsers;
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit
      inputs
      stable
      userRegistry
      selectedUsers
      repository
      ;
  };

  modules = [
    (inputs.import-tree ../modules/nixos)
    hostPath
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        self.overlays.default
        inputs.nur.overlays.default
      ];
    }

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      home-manager.extraSpecialArgs = {
        inherit
          inputs
          stable
          userRegistry
          selectedUsers
          repository
          ;
      };

      home-manager.users = lib.mapAttrs (_: user: {
        imports = [
          self.homeModules.shared
          user.home.module
        ];
      }) homeUsers;

      home-manager.sharedModules = [
        inputs.plasma-manager.homeModules.plasma-manager
      ];
    }
  ];
}
