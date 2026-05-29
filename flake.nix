{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    impermanence.url = "github:nix-community/impermanence";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-blender40.url = "github:NixOS/nixpkgs/ed4db9c6c75079ff3570a9e3eb6806c8f692dc26";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, impermanence, home-manager, spicetify-nix, nixpkgs-blender40, ... }:
  let
    system = "x86_64-linux";

    unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    
    blender40pkgs = import nixpkgs-blender40 {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.solanine = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      modules = [
        ./configuration.nix
        impermanence.nixosModules.impermanence

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = {
            inherit unstable blender40pkgs spicetify-nix;
          };

          home-manager.users.vicky =
            import ./home.nix;
        }
      ];
    };
  };
}
