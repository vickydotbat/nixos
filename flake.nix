{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    impermanence.url = "github:nix-community/impermanence";

    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix.url = "github:sadjow/codex-cli-nix";
  };

  outputs =
    inputs:
    let
      inherit (inputs) self;
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};

      stable = import inputs.nixpkgs-stable {
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

      packages.${system} = import ./pkgs/packages.nix { inherit pkgs; };

      overlays.default = final: prev: import ./pkgs/packages.nix { pkgs = final; };

      nixosConfigurations.solanine = inputs.nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs stable;
        };

        modules = [
          (inputs.import-tree ./modules/nixos)
          (inputs.import-tree ./hosts/solanine)
          inputs.impermanence.nixosModules.impermanence
          { nixpkgs.overlays = [ self.overlays.default ]; }

          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = {
              inherit inputs stable;
            };

            home-manager.users.vicky = inputs.import-tree ./home/users/vicky;
          }
        ];
      };
    };
}
