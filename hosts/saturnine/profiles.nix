{
  lib,
  pkgs,
  selectedUsers,
  ...
}:
let
  sshAuthorizedKeyFiles =
    user:
    map (authorizedUser: "/run/secrets/ssh-${authorizedUser}-id_ed25519.pub") (
      user.ssh.authorizedUsers or [ user.username ]
    );

  mkAccount =
    _: user:
    {
      description = user.description;
      uid = user.uid;
      home = user.homeDirectory;
      extraGroups = user.extraGroups;
      sshAuthorizedKeyFiles = sshAuthorizedKeyFiles user;
    }
    // lib.optionalAttrs ((user.avatar or null) != null) {
      avatar = user.avatar;
    }
    // lib.optionalAttrs (user.passwordHashSecret != null) {
      passwordHashFile = "/run/secrets-for-users/${user.passwordHashSecret}";
    };
in
{
  theorem.nixos = {
    base = {
      boot = {
        enable = true;
        loader = "systemd-boot";
      };
      locale = {
        enable = true;
        timeZone = "Europe/Rome";
        defaultLocale = "en_GB.UTF-8";
        supportedLocales = [
          "en_GB.UTF-8/UTF-8"
          "en_US.UTF-8/UTF-8"
          "it_IT.UTF-8/UTF-8"
        ];
        extraLocaleSettings = {
          LC_MONETARY = "it_IT.UTF-8";
          LC_PAPER = "it_IT.UTF-8";
          LC_MEASUREMENT = "it_IT.UTF-8";
        };
      };
      networking = {
        enable = true;
        homeWifi.ssid = "iliadbox-228BDF";
      };
      nix = {
        enable = true;
        unfreePackageNames = [
          "corefonts"
          "vista-fonts"
          "discord"
          "discord-unwrapped"
          "obsidian"
          "nvidia-kernel-modules"
          "nvidia-x11"
          "nvidia-settings"
          "spotify"
          "vscode"
          "vscode-extension-MS-python-vscode-pylance"
          "vscode-extension-ms-python-python"
          "vscode-extension-ms-vscode-cpptools"
          "vscode-extension-mhutchie-git-graph"
          "vscode-extension-ms-dotnettools-csharp"
          "vscode-extension-ms-vscode-remote-remote-ssh"
          "claude-code"
          "unrar"
          "nwtoolset"
        ];
        accessTokensSopsFile = ../../secrets/nix-access-tokens.yaml;
      };

      packages.enable = true;
      persistence.enable = true;
      ssh.enable = true;
      # Reached over the tailnet like solanine, so the game host can be
      # administered from away without a second inbound port on the router.
      tailscale = {
        enable = true;
        authKey = {
          sopsFile = ../../secrets/tailscale.yaml;
          tags = [ "tag:server" ];
        };
      };
      users = {
        enable = true;
        accounts = lib.mapAttrs mkAccount selectedUsers;
      };
      zram.enable = true;
      oom.enable = true;
      # Second copy of the SoW restic repositories (sow-platform ADR-0041, #105).
      sowSecondCopy.enable = true;
    };

    desktop = {
      audio.enable = true;
      bluetooth = {
        enable = true;
        hardenService = true;
      };
      plasma.enable = true;
      appimage.enable = true;
      graphics.enable = true;
      flatpak.enable = true;
      jailmole.enable = false;
    };

    gaming = {
      core.enable = true;
      steam = {
        enable = true;
        # This host now owns the V Rising world and lists it publicly, so
        # Steam's server-browser query ports (27015-27030) must be reachable.
        dedicatedServerOpenFirewall = true;
      };
    };

    # Podman carries the V Rising dedicated server, whose Home Manager module
    # refuses to start without it. Nothing else on this host needs containers
    # yet, so `dockerCompat` and `composeDns` stay off.
    virtualisation.podman.enable = true;

    security = {
      firejail.enable = false;
      hardening.enable = true;
      polkit.enable = true;
      run0-sudo.enable = true;
      diagnostics.enable = true;
    };
  };

  # This laptop hosts the V Rising server, which takes a systemd sleep and
  # lid-switch inhibitor while it runs. logind ignores inhibitors for the lid
  # unless told otherwise, so closing the lid would still suspend the machine
  # and drop every connected player.
  services.logind.settings.Login.LidSwitchIgnoreInhibited = false;

  # `sshd` listens for the tailnet only, as on solanine. The V Rising and Steam
  # query ports are a separate matter and stay open to the world; this closes
  # administrative access on the local network, not the game the host serves.
  #
  # If the tailnet is ever unreachable, this host is reached by sitting at it.
  services.openssh.openFirewall = false;

  environment.systemPackages = with pkgs; [
    btrfs-progs
    cryptsetup
    nvme-cli
    unrar
    p7zip
    smartmontools
  ];
}
