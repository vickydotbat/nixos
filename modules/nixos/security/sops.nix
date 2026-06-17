{
  config,
  lib,
  pkgs,
  ...
}:
# SOPS is the repository's runtime secret substrate. This module wires the age
# identity, default encrypted file, operator environment, and repair tooling
# without ever placing plaintext secret material in the Nix store.
let
  cfg = config.theorem.nixos.security.sops;
in
{
  options.theorem.nixos.security.sops = {
    enable = lib.mkEnableOption "SOPS secret management";

    ageKeyFile = lib.mkOption {
      type = lib.types.path;
      default = "/nix/persist/secrets/sops/age/keys.txt";
      description = "Age identity file used by sops-nix.";
    };

    defaultSopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Default SOPS file for host secrets.";
    };

    keepAgeKeyInSudoEnvironment = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Preserve SOPS_AGE_KEY_FILE through sudo for maintenance commands.";
    };

    ageKeyOwner = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "Owner for the persisted age identity file.";
    };

    ageKeyGroup = lib.mkOption {
      type = lib.types.str;
      default = "nixcfg";
      description = "Group allowed to read the persisted age identity file.";
    };

    ageKeyMode = lib.mkOption {
      type = lib.types.str;
      default = "0640";
      description = "Mode for the persisted age identity file.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.age.keyFile = cfg.ageKeyFile;
    sops.defaultSopsFormat = "yaml";
    sops.defaultSopsFile = lib.mkIf (cfg.defaultSopsFile != null) cfg.defaultSopsFile;

    environment.sessionVariables.SOPS_AGE_KEY_FILE = cfg.ageKeyFile;
    environment.systemPackages = [
      pkgs.sops
      pkgs.age
      pkgs.mkpasswd
    ];

    security.sudo.extraConfig = lib.mkIf cfg.keepAgeKeyInSudoEnvironment ''
      Defaults env_keep += "SOPS_AGE_KEY_FILE"
    '';

    systemd.tmpfiles.rules = [
      "d ${dirOf (dirOf cfg.ageKeyFile)} 0750 ${cfg.ageKeyOwner} ${cfg.ageKeyGroup} - -"
      "d ${dirOf cfg.ageKeyFile} 0750 ${cfg.ageKeyOwner} ${cfg.ageKeyGroup} - -"
      "z ${cfg.ageKeyFile} ${cfg.ageKeyMode} ${cfg.ageKeyOwner} ${cfg.ageKeyGroup} - -"
    ];
  };
}
