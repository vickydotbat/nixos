{ config, lib, pkgs, unstable, spicetify-nix, blender40pkgs, ... }:
let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

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
in
{
  imports = [
    spicetify-nix.homeManagerModules.spicetify
    
  ];

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
    myGimp
    neverwinter-nim
    
    (pkgs.writeShellScriptBin "blender40" ''
      exec ${blender40pkgs.blender}/bin/blender "$@"
    '')
  ];

  xdg.desktopEntries.blender40 = {
    name = "Blender 4.0";
    genericName = "3D Modeler";
    exec = "blender40 %f";
    terminal = false;
    categories = [ "Graphics" "3DGraphics" ];
  };

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


  programs.spicetify = {
    enable = true;

    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      hidePodcasts
      shuffle
    ];
  };

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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        setEnv = {
          TERM = "xterm-256color";
        };
        addKeysToAgent = "yes";
      };

      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };

      "ovh_sow" = {
        user = "ubuntu";
        port = 50340;
        hostname = "51.254.142.98";
        identityFile = "~/.ssh/id_ed25519";
      };

      "git-ssh.westgate.pw" = {
        hostname = "git-ssh.westgate.pw";
        port = 2222;
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
    };
  };
}
