{ config, lib, pkgs, unstable, ... }:
let
  gimpPluginPython = pkgs.python3.withPackages (ps: with ps; [
    pygobject3
  ]);

  myGimp = pkgs.symlinkJoin {
    name = "gimp3-with-plt-python";
    paths = [ pkgs.gimp3-with-plugins ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      wrapProgram $out/bin/gimp \
        --set PATH ${pkgs.lib.makeBinPath [
          gimpPluginPython
          pkgs.coreutils
          pkgs.bash
        ]} \
        --prefix GI_TYPELIB_PATH : ${pkgs.lib.makeSearchPath "lib/girepository-1.0" [
          pkgs.gimp
          pkgs.gtk3
          pkgs.gegl
          pkgs.babl
        ]}
    '';
  };

  neverwinter-nim = pkgs.callPackage ./pkgs/neverwinter-nim.nix { };
  blender-402-bin = pkgs.callPackage ./pkgs/blender-402-bin.nix { };
in
{
  imports = [./spicetify.nix];

  home.username = "vicky";
  home.homeDirectory = "/home/vicky";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = [
    pkgs.bat
    pkgs.eza
    pkgs.fd
    pkgs.fzf
    pkgs.ripgrep
    pkgs.jq
    pkgs.fastfetch
    pkgs.blender
    myGimp
    neverwinter-nim
    blender-402-bin    
  ];

    programs.git = {
        enable = true;
        lfs.enable = true;
        settings = {
        user.name = "vickydotbat";
        user.email = "vickydotbat@tutamail.com";
        };
    };

    programs.discord.enable = true;
    services.arrpc.enable = true;

  programs.vscode = {
    enable = true;
    package = unstable.vscode;
  };

  programs.distrobox = {
    enable = true;
  };

  services.podman = {
    enable = true;
  };

  programs.keepassxc.enable = true;

  services.kdeconnect.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        IdentityFile = "~/.ssh/id_ed25519";
        SetEnv = {
          TERM = "xterm-256color";
        };
        AddKeysToAgent = "yes";
      };

      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };

      "ovh_sow" = {
        User = "ubuntu";
        Port = 50340;
        HostName = "51.254.142.98";
        IdentityFile = "~/.ssh/id_ed25519";
      };

      "git-ssh.westgate.pw" = {
        HostName = "git-ssh.westgate.pw";
        Port = 2222;
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
    };
  };
}
