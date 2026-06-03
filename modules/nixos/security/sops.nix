{
  config,
  lib,
  pkgs,
  ...
}:

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
      default = "wheel";
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
      # TODO: Builtins. prefix can apparently be removed? Double-check correct syntax.
      "d ${builtins.dirOf (builtins.dirOf cfg.ageKeyFile)} 0750 ${cfg.ageKeyOwner} ${cfg.ageKeyGroup} - -"
      "d ${builtins.dirOf cfg.ageKeyFile} 0750 ${cfg.ageKeyOwner} ${cfg.ageKeyGroup} - -"
      "z ${cfg.ageKeyFile} ${cfg.ageKeyMode} ${cfg.ageKeyOwner} ${cfg.ageKeyGroup} - -"
    ];
  };
}
