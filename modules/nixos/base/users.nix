{ config, lib, ... }:

let
  cfg = config.theorem.nixos.base.users;
in
{
  options.theorem.nixos.base.users = {
    enable = lib.mkEnableOption "base user accounts";

    primaryUser = lib.mkOption {
      type = lib.types.str;
      default = "vicky";
      description = "Primary normal user account.";
    };

    rootPasswordHashFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a file containing root's hashed password.";
    };

    primaryUserPasswordHashFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a file containing the primary user's hashed password.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.mutableUsers = false;

    users.users.root = lib.mkIf (cfg.rootPasswordHashFile != null) {
      hashedPasswordFile = cfg.rootPasswordHashFile;
    };

    users.users.${cfg.primaryUser} = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
    }
    // lib.optionalAttrs (cfg.primaryUserPasswordHashFile != null) {
      hashedPasswordFile = cfg.primaryUserPasswordHashFile;
    };
  };
}
