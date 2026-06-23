{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://codex-cli.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
    ];
  };

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-unstable&shallow=1";
    nixpkgs-stable.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-26.05&shallow=1";

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };

    ponytail = {
      url = "github:DietrichGebert/ponytail";
      flake = false;
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      mkSystem = import ./lib/mkSystem.nix;
      userRegistry = import ./users;

      stable = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = false; # Use predicates
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

      apps.${system}.vulnerability-scan =
        let
          scanSystemVulnerabilities = pkgs.writeShellApplication {
            name = "scan-system-vulnerabilities";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.grype
              pkgs.sbomnix
            ];
            text = ''
              usage() {
                printf '%s\n' \
                  'Usage: scan-system-vulnerabilities [TARGET] [OUTPUT_DIR]' \
                  "" \
                  'Generate a CycloneDX SBOM with sbomnix, then scan it with grype.' \
                  "" \
                  'TARGET defaults to /run/current-system.' \
                  'OUTPUT_DIR defaults to ./vulnerability-scan.' \
                  "" \
                  'Example:' \
                  '  nix run .#vulnerability-scan -- /run/current-system ./reports/solanine'
              }

              case "''${1:-}" in
                -h|--help)
                  usage
                  exit 0
                  ;;
              esac

              target="''${1:-/run/current-system}"
              output_dir="''${2:-./vulnerability-scan}"
              sbom="$output_dir/sbom.cdx.json"
              report="$output_dir/grype.txt"

              mkdir -p "$output_dir"

              sbomnix --cdx "$sbom" "$target"
              grype "sbom:$sbom" --output table --file "$report"

              echo "SBOM written to $sbom"
              echo "Vulnerability report written to $report"
            '';
          };
        in
        {
          type = "app";
          program = "${scanSystemVulnerabilities}/bin/scan-system-vulnerabilities";
          meta.description = "Generate a system SBOM with sbomnix and scan it with grype.";
        };

      packages.${system} = import ./pkgs/packages.nix { inherit pkgs; };

      homeModules =
        let
          shared = {
            _module.args = {
              inherit
                inputs
                stable
                userRegistry
                ;
              selectedUsers = { };
              repository = {
                path = "$NIXOS_CONFIG_FLAKE";
                group = "nixcfg";
              };
            };

            imports = [
              inputs.nix-index-database.homeModules.nix-index
              inputs.spicetify-nix.homeManagerModules.spicetify
              (inputs.import-tree ./modules/home)
            ];
          };
        in
        {
          default = shared;
          shared = shared;
        };

      checks.${system} = {
        home-shared-boundary = import ./checks/home-shared-boundary.nix {
          inherit inputs pkgs;
        };

        firelink-disko-boundary = import ./checks/firelink-disko-boundary.nix {
          inherit inputs pkgs;
        };

        firelink-discord-boundary = import ./checks/firelink-discord-boundary.nix {
          inherit inputs pkgs;
        };

        saturnine-disko-boundary = import ./checks/saturnine-disko-boundary.nix {
          inherit inputs pkgs;
        };

        solanine-libvirt-boundary = import ./checks/solanine-libvirt-boundary.nix {
          inherit inputs pkgs;
        };

        solanine-podman-boundary = import ./checks/solanine-podman-boundary.nix {
          inherit inputs pkgs;
        };

        nwtoolset-wine-boundary = import ./checks/nwtoolset-wine-boundary.nix {
          inherit pkgs;
          nwtoolset = inputs.self.packages.${system}.nwtoolset;
        };

        nwtoolset-plasma-boundary = import ./checks/nwtoolset-plasma-boundary.nix {
          inherit inputs pkgs;
        };

        btrfs-rollback-boundary = import ./checks/btrfs-rollback-boundary.nix {
          inherit inputs pkgs;
        };

        plasma-browser-boundary = import ./checks/plasma-browser-boundary.nix {
          inherit inputs pkgs;
        };

        plasma-file-tools-boundary = import ./checks/plasma-file-tools-boundary.nix {
          inherit inputs pkgs;
        };

        vicky-vscode-renamer-boundary = import ./checks/vicky-vscode-renamer-boundary.nix {
          inherit inputs pkgs;
        };

        vicky-vscode-format-boundary = import ./checks/vicky-vscode-format-boundary.nix {
          inherit inputs pkgs;
        };

        vicky-vscode-theme-boundary = import ./checks/vicky-vscode-theme-boundary.nix {
          inherit inputs pkgs;
        };

        secret-file-boundary = import ./checks/secret-file-boundary.nix {
          inherit inputs pkgs;
        };

        ssh-approved-hosts-boundary = import ./checks/ssh-approved-hosts-boundary.nix {
          inherit inputs pkgs;
        };

        git-safety-boundary = import ./checks/git-safety-boundary.nix {
          inherit inputs pkgs;
        };

        module-default-boundary = import ./checks/module-default-boundary.nix {
          inherit inputs pkgs;
        };

        gimp-custom-wrapper-boundary = import ./checks/gimp-custom-wrapper-boundary.nix {
          inherit pkgs;
          gimp3-custom = inputs.self.packages.${system}.gimp3-custom;
        };
      };

      devShells.${system} =
        let
          codex = pkgs.mkShell {
            packages = [
              pkgs.codex
            ];
          };
          claude = pkgs.mkShell {
            packages = [
              pkgs.claude-code
            ];
          };
        in
        {
          default = claude;
          codex = codex;
          claude = claude;
        };

      overlays.default =
        final: prev:
        (import ./pkgs/packages.nix { pkgs = final; })
        // {
          vscode-extensions = prev.vscode-extensions // {
            evertjunior = (prev.vscode-extensions.evertjunior or { }) // {
              mass-renamer = final.callPackage ./pkgs/vscode-extensions/evertjunior/mass-renamer.nix { };
            };
          };
        };

      nixosConfigurations.solanine = mkSystem {
        inherit
          inputs
          system
          stable
          userRegistry
          ;
        self = inputs.self;
        hostPath = ./hosts/solanine;
        selectedUsers = {
          # Add `guest` here when this host should expose the low-access guest
          # account: `inherit (userRegistry) admin guest vicky;`.
          inherit (userRegistry) admin vicky;
        };
      };

      nixosConfigurations.firelink = mkSystem {
        inherit
          inputs
          system
          stable
          userRegistry
          ;
        self = inputs.self;
        hostPath = ./hosts/firelink;
        selectedUsers = {
          inherit (userRegistry) admin mattia;
        };
      };

      nixosConfigurations.saturnine = mkSystem {
        inherit
          inputs
          system
          stable
          userRegistry
          ;
        self = inputs.self;
        hostPath = ./hosts/saturnine;
        selectedUsers = {
          inherit (userRegistry) admin vicky;
        };
      };
    };
}
