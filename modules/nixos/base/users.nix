{ config, lib, ... }:
let
  cfg = config.theorem.nixos.base.users;
  accountType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Create this user account.";
        };

        description = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Human-readable account description.";
        };

        uid = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
          description = "Numeric uid for this account.";
        };

        home = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Home directory for this account.";
        };

        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Supplementary groups for this account.";
        };

        passwordHashFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to a file containing this account's hashed password.";
        };
      };
    }
  );

  mkUser =
    name: account:
    {
      isNormalUser = true;
      description = account.description;
      extraGroups = account.extraGroups;
    }
    // lib.optionalAttrs (account.uid != null) {
      uid = account.uid;
    }
    // lib.optionalAttrs (account.home != null) {
      home = account.home;
    }
    // lib.optionalAttrs (account.passwordHashFile != null) {
      hashedPasswordFile = account.passwordHashFile;
    };
in
{
  options.theorem.nixos.base.users = {
    enable = lib.mkEnableOption "base user accounts";

    rootPasswordHashFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a file containing root's hashed password.";
    };

    accounts = lib.mkOption {
      type = lib.types.attrsOf accountType;
      default = { };
      description = ''
        User accounts accepted by this host. Hosts select from the repository
        user doctrine, then this module performs the account creation rite.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.mutableUsers = false;

    users.users =
      lib.optionalAttrs (cfg.rootPasswordHashFile != null) {
        root.hashedPasswordFile = cfg.rootPasswordHashFile;
      }
      // lib.mapAttrs mkUser (lib.filterAttrs (_: account: account.enable) cfg.accounts);
  };
}
