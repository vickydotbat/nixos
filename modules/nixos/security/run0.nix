{
  config,
  lib,
  ...
}:
let
  cfg = config.theorem.nixos.security.run0-sudo;
  quotedUsers = lib.concatMapStringsSep ", " (user: ''"${user}"'') cfg.authenticationCacheUsers;
  quotedGroups = lib.concatMapStringsSep ", " (group: ''"${group}"'') cfg.authenticationCacheGroups;
in
{
  options.theorem.nixos.security.run0-sudo = {
    enable = lib.mkEnableOption "Run0 instead of sudo";

    authenticationCacheUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        User names allowed to keep Polkit authentication for one NixOS
        administrative operation. Keep this narrow; every named account becomes
        part of the host's elevation path.
      '';
    };

    authenticationCacheGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "wheel" ];
      description = ''
        Group names allowed to keep Polkit authentication for one NixOS
        administrative operation. `wheel` mirrors the usual administrator
        boundary while keeping the rule declarative.
      '';
    };

    sudoAlias.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install a `sudo` compatibility alias that invokes `run0`. Keep enabled
        while operator habits and maintenance notes still reach for `sudo`;
        disable once the host's repair rites name `run0` directly.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.theorem.nixos.security.sudo.enable;
        message = ''
          Select only one elevation profile: `theorem.nixos.security.sudo.enable`
          and `theorem.nixos.security.run0-sudo.enable` cannot both be true.
        '';
      }
      {
        assertion = cfg.authenticationCacheUsers != [ ] || cfg.authenticationCacheGroups != [ ];
        message = ''
          `theorem.nixos.security.run0-sudo` needs at least one
          `authenticationCacheUsers` or `authenticationCacheGroups` entry so the
          Polkit cache rule has a declared administrative boundary.
        '';
      }
    ];

    environment.systemPackages = [
      config.systemd.package
    ];

    security = {
      sudo.enable = lib.mkForce false;

      polkit.enable = true;
      run0 = {
        enableSudoAlias = cfg.sudoAlias.enable;
      };

      # Force using run0 for admin commands.
      wrappers = {
        su.enable = lib.mkForce false;
        sudoedit.enable = lib.mkForce false;
        sg.enable = lib.mkForce false;
        fusermount.enable = lib.mkForce false;
        fusermount3.enable = lib.mkForce false;
        pkexec.setuid = lib.mkForce false;
        newgrp.setuid = lib.mkForce false;
        newgidmap.setuid = lib.mkForce false;
        newuidmap.setuid = lib.mkForce false;
        # `mount` Needed for `fileSystems.options`
        # mount.enable = lib.mkForce false;
        # Optional: if you disable mount, disable umount as well
        # umount.enable = lib.mkForce false;
      };

      # Reduce friction of password entries.
      polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          var users = [${quotedUsers}];
          var groups = [${quotedGroups}];
          var permittedUser = users.indexOf(subject.user) >= 0;
          var permittedGroup = groups.some(function(group) {
            return subject.isInGroup(group);
          });

          if ((permittedUser || permittedGroup) && action.id.indexOf("org.nixos") == 0) {
            polkit.log("Caching admin authentication for single NixOS operation");
            return polkit.Result.AUTH_ADMIN_KEEP;
          }
        });
      '';

    };
  };
}
