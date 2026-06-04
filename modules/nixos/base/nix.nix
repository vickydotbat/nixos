{
  config,
  lib,
  repository,
  ...
}:
# Base Nix daemon policy for the theorem. It keeps flakes enabled, signatures
# required, the shared repository trusted, and unfree packages behind exact
# package-name exceptions instead of a global audit bypass.
let
  cfg = config.theorem.nixos.base.nix;
in
{
  options.theorem.nixos.base.nix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the base Nix daemon configuration. This defaults on because the
        flake machinery is the repair surface for every host in this repository.
      '';
    };

    unfreePackageNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Exact package names allowed through the unfree predicate.
        Modules and hosts should add only packages they actually enable.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config = {
      allowUnfree = false;
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.unfreePackageNames;
    };

    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        # Keep build outputs reachable through live derivations, so useful
        # repair material is not collected immediately.
        keep-outputs = true;

        # Always require signatures
        require-sigs = lib.mkForce true;

        # Use substitutes for builders
        builders-use-substitutes = true;

        # Use prebuilt binaries
        substituters = [ "https://cache.nixos.org" ];
        trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gW5RANTTXz3qR3Q6Y3B2M0h4IrWH4=" ];

        connect-timeout = 10;
        fallback = true;
      };
    };

    programs.nh = lib.mkDefault {
      enable = true;
      flake = repository.path;
      clean = {
        enable = true;
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };

    # Reduces the suffering of the average user.
    programs.nix-ld.enable = lib.mkDefault true;
  };
}
