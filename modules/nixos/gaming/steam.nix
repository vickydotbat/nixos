{
  config,
  lib,
  pkgs,
  ...
}:
# Steam is an explicit gaming profile because it brings unfree packages, device
# support, and optional network listeners. Firewall openings stay named so game
# convenience does not become an ambient service surface.
let
  cfg = config.theorem.nixos.gaming.steam;
in
{
  options.theorem.nixos.gaming.steam = {
    enable = lib.mkEnableOption "Steam gaming profile";

    remotePlayOpenFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open firewall ports for Steam Remote Play. Leave closed unless this
        host intentionally accepts game streaming traffic from the local network.
      '';
    };

    dedicatedServerOpenFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open firewall ports for Steam dedicated server discovery. This is a
        service-facing posture, not a desktop default.
      '';
    };

    localNetworkGameTransfersOpenFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open firewall ports for Steam local network game transfers.
      '';
    };

    gamescope.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Gamescope support for Steam sessions.";
    };
  };

  config = lib.mkIf cfg.enable {
    theorem.nixos.base.nix.unfreePackageNames = [
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
    ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = cfg.remotePlayOpenFirewall;
      dedicatedServer.openFirewall = cfg.dedicatedServerOpenFirewall;
      localNetworkGameTransfers.openFirewall = cfg.localNetworkGameTransfersOpenFirewall;
      gamescopeSession.enable = cfg.gamescope.enable;
    };

    programs.gamescope = lib.mkIf cfg.gamescope.enable {
      enable = true;
      capSysNice = false;
    };

    hardware.steam-hardware.enable = true;

    environment.systemPackages = with pkgs; [
      steam-run
    ];
  };
}
