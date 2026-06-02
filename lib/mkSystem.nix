{
  inputs,
  self,
  system,
  stable,
  hostPath,
  userName,
  userPath,
}:

inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs stable;
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
        inherit inputs stable;
      };

      home-manager.users.${userName} = {
        imports = [
          (inputs.import-tree ../modules/home)
          userPath
        ];
      };

      home-manager.sharedModules = [
        inputs.plasma-manager.homeModules.plasma-manager
      ];
    }
  ];
}
