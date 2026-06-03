{
  config,
  lib,
  pkgs,
  repository,
  ...
}:
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

        avatar = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            PNG avatar installed for display managers through AccountsService.
            Keep the image beside the user registry entry so the account's face
            is restored with the same declarative rite that creates the account.
          '';
        };
      };
    }
  );
  # FIXME: Does this check if the system uses impermanence at all? It may only need to update it once otherwise, except when the avatar changes.
  accountsWithAvatars = lib.filterAttrs (
    _: account: account.enable && account.avatar != null
  ) cfg.accounts;
  hasAvatars = accountsWithAvatars != { };

  mkAvatarActivation =
    name: account:
    let
      accountFile = "/var/lib/AccountsService/users/${name}";
      iconFile = "/var/lib/AccountsService/icons/${name}";
    in
    ''
      account_file=${lib.escapeShellArg accountFile}
      icon_file=${lib.escapeShellArg iconFile}

      ${pkgs.coreutils}/bin/install -d -m 0755 /var/lib/AccountsService/icons /var/lib/AccountsService/users
      ${pkgs.coreutils}/bin/install -m 0644 ${lib.escapeShellArg account.avatar} "$icon_file"

      if [[ -f "$account_file" ]]; then
        if ${pkgs.gnugrep}/bin/grep -q '^Icon=' "$account_file"; then
          ${pkgs.gnused}/bin/sed -i "s|^Icon=.*|Icon=$icon_file|" "$account_file"
        elif ${pkgs.gnugrep}/bin/grep -q '^\[User\]$' "$account_file"; then
          ${pkgs.gnused}/bin/sed -i "/^\[User\]$/a Icon=$icon_file" "$account_file"
        else
          ${pkgs.coreutils}/bin/printf '\n[User]\nIcon=%s\n' "$icon_file" >> "$account_file"
        fi
      else
        ${pkgs.coreutils}/bin/printf '[User]\nIcon=%s\n' "$icon_file" > "$account_file"
      fi

      ${pkgs.coreutils}/bin/chown root:root "$account_file" "$icon_file"
      ${pkgs.coreutils}/bin/chmod 0600 "$account_file"
      ${pkgs.coreutils}/bin/chmod 0644 "$icon_file"
    '';

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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable declarative user account management. Defaults on so a host does
        not drift back to mutable account state by accident.
      '';
    };

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

    users.groups.${repository.group} = { };

    services.accounts-daemon.enable = lib.mkDefault hasAvatars;

    systemd.tmpfiles.rules = [
      "d ${repository.path} 2775 root ${repository.group} - -"
    ];

    system.activationScripts.userAvatars.text = lib.concatStringsSep "\n" (
      lib.mapAttrsToList mkAvatarActivation accountsWithAvatars
    );

    users.users =
      lib.optionalAttrs (cfg.rootPasswordHashFile != null) {
        root.hashedPasswordFile = cfg.rootPasswordHashFile;
      }
      // lib.mapAttrs mkUser (lib.filterAttrs (_: account: account.enable) cfg.accounts);
  };
}
