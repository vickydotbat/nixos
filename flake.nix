{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://devenv.cachix.org"
      "https://codex-cli.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

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

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
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

      devShells.${system} =
        let
          codex = pkgs.mkShell {
            packages = [
              inputs.codex-cli-nix.packages.${system}.default
            ];
          };
        in
        {
          default = codex;
          codex = codex;
        };

      overlays.default = final: prev: import ./pkgs/packages.nix { pkgs = final; };

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
          inherit (userRegistry) admin vicky;
        };
      };
    };
}
