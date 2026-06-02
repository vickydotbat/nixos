{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.nixos.gaming.steam;
in
{
  options.theorem.nixos.gaming.steam.enable = lib.mkEnableOption "Steam gaming profile";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = false;
    };

    programs.gamescope = {
      enable = true;
      capSysNice = false;
    };

    hardware.steam-hardware.enable = true;
    programs.gamemode.enable = true;

    environment.systemPackages = with pkgs; [
      steam-run
    ];
  };
}
