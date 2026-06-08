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
      networking.enable = true;
      nix.enable = true;
      nix.unfreePackageNames = [
        "corefonts"
        "discord"
        "obsidian"
        "spotify"
        "unrar"
        "vista-fonts"
        "vscode"
        "vscode-extension-MS-python-vscode-pylance"
        "vscode-extension-ms-python-python"
        "vscode-extension-ms-vscode-cpptools"
        "vscode-extension-mhutchie-git-graph"
        "vscode-extension-ms-dotnettools-csharp"
        "nwtoolset"
        "vscode-extension-ms-vscode-remote-remote-ssh"
        "claude-code"
      ];
      packages.enable = true;
      persistence.enable = true;
      ssh = {
        enable = true;
      };
      users = {
        enable = true;
        accounts = lib.mapAttrs mkAccount selectedUsers;
      };
    };

    desktop = {
      audio = {
        enable = true;
      };
      bluetooth = {
        enable = true;
        hardenService = true;
      };
      plasma.enable = true;
      appimage.enable = true;
      graphics.enable = true;
      flatpak.enable = false;
      jailwolf.enable = true;
    };

    gaming = {
      core.enable = true;
      steam.enable = true;
    };

    virtualisation = {
      libvirt = {
        enable = true;
        spiceUSBRedirection.enable = true;
      };
      podman = {
        enable = true;
        dockerCompat.enable = true;
        composeDns.enable = true;
      };
    };

    security = {
      firejail.enable = true;
      hardening.enable = true;
      polkit.enable = true;
      run0-sudo.enable = true;
      diagnostics.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    unrar
    p7zip
    e2fsprogs
    btrfs-progs # FIXME: Make this available only when btrfs is enabled
    nvme-cli # FIXME: Make this available only on NVME systems
    smartmontools
  ];
}
