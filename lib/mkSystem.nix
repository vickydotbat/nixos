{
  inputs,
  self,
  system,
  stable,
  userRegistry,
  hostPath,
  selectedUsers,
}:

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
          ;
      };

      home-manager.users = lib.mapAttrs (_: user: {
        imports = [
          (inputs.import-tree ../modules/home)
          user.home.module
        ];
      }) homeUsers;

      home-manager.sharedModules = [
        inputs.plasma-manager.homeModules.plasma-manager
      ];
    }
  ];
}
