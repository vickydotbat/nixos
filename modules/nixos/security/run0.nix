{
  config,
  lib,
  ...
}:
# Experimental run0 elevation profile. This module replaces the traditional
# sudo path with systemd-run plus Polkit, keeps a compatibility alias available
# while repair notes still say `sudo`, and force-disables the sudo theorem when
# selected. Test login, rebuild, and rollback before making it a host default.
let
  cfg = config.theorem.nixos.security.run0-sudo;
in
{
  options.theorem.nixos.security.run0-sudo = {
    enable = lib.mkEnableOption "Run0 instead of sudo";

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
    theorem.nixos.security.sudo.enable = lib.mkForce false;

    environment.systemPackages = [
      config.systemd.package
    ];

    security = {
      # Run0 is the elevation path for this profile. Force the traditional
      # sudo service off even when the profile inherits a host that enables it.
      sudo.enable = lib.mkForce false;
      run0.enable = lib.mkForce true;

      polkit.enable = true;
      run0 = {
        enableSudoAlias = cfg.sudoAlias.enable;
        # Keep run0 password-gated. The working frictionless path is
        # `wheelNeedsPassword = false`, which grants passwordless Polkit
        # approval for systemd unit management rather than a narrow NixOS
        # rebuild cache.
        wheelNeedsPassword = lib.mkDefault true;
      };

      # Force using run0 for admin commands.
      wrappers = {
        su.enable = lib.mkForce false;
        sudoedit.enable = lib.mkForce false;
        sg.enable = lib.mkForce false;
        # FUSE 2 stays off: nothing here still uses it, and its setuid helper
        # carries the older privilege-escalation history of the two.
        fusermount.enable = lib.mkForce false;
        # FUSE 3 stays on. It is not an elevation path, so forcing it off did
        # not route anything through run0; it only removed rootless FUSE from
        # the host, breaking sshfs, AppImage and fuse-overlayfs. Unprivileged
        # FUSE mounts are nosuid,nodev by kernel policy, and with
        # `programs.fuse.userAllowOther` left false no other account can be
        # lured into traversing one. What remains is a latency-controlled
        # filesystem, useful only to an attacker who already runs code as this
        # user - who has run0 and unprivileged user namespaces to hand anyway.
        pkexec.setuid = lib.mkForce false;
        newgrp.setuid = lib.mkForce false;
        # Rootless Podman needs these helpers. Do not force setuid/setgid here:
        # NixOS may provide them through file capabilities instead.
        newgidmap.enable = lib.mkForce config.theorem.nixos.virtualisation.podman.enable;
        newuidmap.enable = lib.mkForce config.theorem.nixos.virtualisation.podman.enable;
        # `mount` Needed for `fileSystems.options`
        # mount.enable = lib.mkForce false;
        # Optional: if you disable mount, disable umount as well
        # umount.enable = lib.mkForce false;
      };

    };
  };
}
