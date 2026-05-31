{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    impermanence.url = "github:nix-community/impermanence";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      impermanence,
      home-manager,
      spicetify-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      formatter.${system} = pkgs.writeShellApplication {
        name = "format-nix";
        runtimeInputs = [ pkgs.nixfmt ];
        text = ''
          git ls-files '*.nix' | xargs nixfmt
        '';
      };

      packages.${system} = import ./pkgs { inherit pkgs; };

      overlays.default = final: prev: import ./pkgs { pkgs = final; };

      nixosConfigurations.solanine = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          stable = import nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
        };

        modules = [
          ./hosts/solanine
          impermanence.nixosModules.impermanence
          { nixpkgs.overlays = [ self.overlays.default ]; }

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = {
              inherit stable spicetify-nix;
            };

            home-manager.users.vicky = import ./home/users/vicky;
          }
        ];
      };
    };
}
