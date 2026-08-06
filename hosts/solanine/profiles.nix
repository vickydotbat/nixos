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
        "vscode-extension-ms-vscode-remote-remote-ssh"
        "claude-code"
        "nwtoolset"
      ];
      packages.enable = true;
      persistence.enable = true;
      ssh = {
        enable = true;
      };
      # This host is worked on from a phone, so `sshd` is reached over the
      # tailnet instead of an address exposed to the local network.
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
      jailmole.enable = true;
      keyd = {
        enable = true;
        settings.deathadder = {
          ids = [ "1532:0084:288cfcd8" ]; # Razer DeathAdder V2
          settings.main = {
            f1 = "middlemouse"; # Remap my first mouse button to middlemouse
          };
        };
        settings.geekykb = {
          # this geeky keyboard is weird because it has 3 entries in keyd
          ids = [ "3532:c0c9:b80f2b4d" ]; # Geeky GK75 gaming keyboard
          settings.main = {
            capslock = "f24";
            home = "f23";
            end = "f22";
            scrolllock = "f21";
          };
        };
      };
    };

    gaming = {
      core.enable = true;
      # The V Rising server moved to saturnine, so this host is a plain Steam
      # client again and needs no server-browser query ports open.
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
      hardening = {
        enable = true;
        # Keep coredumps so a kwin/Wayland session crash leaves a backtrace.
        coredumps.disable = false;
      };
      polkit.enable = true;
      run0-sudo.enable = true;
      diagnostics.enable = true;
    };
  };

  # `sshd` listens for the tailnet only. The base SSH module opens port 22 on
  # every interface by default, which was how the household machines reached
  # each other; the tailnet now carries that traffic, and inbound SSH from the
  # local network is no longer wanted. Closing it here leaves exactly one
  # approach road, and one is easier to reason about than two.
  #
  # If the tailnet is ever unreachable, this host is reached by sitting at it.
  services.openssh.openFirewall = false;

  environment.systemPackages = with pkgs; [
    unrar
    p7zip
    e2fsprogs
    btrfs-progs # FIXME: Make this available only when btrfs is enabled
    nvme-cli # FIXME: Make this available only on NVME systems
    smartmontools
    nodejs
  ];
}
