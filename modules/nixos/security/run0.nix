{
  config,
  lib,
  ...
}:
# TODO: Run0 should in theory replace sudo on hardened systems. It is also a much better default, but analyze first. Let there be a choice between sudo and run0.
let
  cfg = config.theorem.nixos.security.run0-sudo;
in
{
  options.theorem.nixos.security.run0-sudo.enable = lib.mkEnableOption "Run0 instead of sudo";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      config.systemd.package
    ];

    security = {
      sudo.enable = false;

      polkit.enable = true;
      run0 = {
        enableSudoAlias = true;
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
      # TODO: Populate this on a per-user basis.
      polkit.extraConfig =
        let
          username = "fill this in"; # TODO: Per user.
        in
        ''
          polkit.addRule(function(action, subject) {
            if (subject.user == "${username}") {
              if (action.id.indexOf("org.nixos") == 0) {
                polkit.log("Caching admin authentication for single NixOS operation");
                return polkit.Result.AUTH_ADMIN_KEEP;
              }
            }
          });
        '';

    };
  };
}
