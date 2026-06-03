{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.theorem.nixos.desktop.jailwolf;

  command = "librewolf-private";

  librewolfIcons = pkgs.runCommand "librewolf-icons" { } ''
    mkdir -p $out/share/icons
    cp -r ${pkgs.librewolf}/share/icons/hicolor $out/share/icons/
  '';

  librewolfProfile = pkgs.writeText "librewolf-private.profile" ''
    # Start from Firejail's Firefox profile. LibreWolf is Firefox-derived.
    include ${pkgs.firejail}/etc/firejail/firefox.profile

    # Disposable browser state.
    private
    private-cache
    private-tmp

    # Tighter device exposure.
    private-dev

    # Hardening.
    seccomp
    caps.drop all
    noroot

    # Explicitly deny sensitive host state.
    blacklist ''${HOME}/.ssh
    blacklist ''${HOME}/.gnupg
    blacklist ''${HOME}/.password-store
    blacklist ''${HOME}/.config/keepassxc
    blacklist ''${HOME}/.local/share/keyrings
    blacklist ''${HOME}/.mozilla
    blacklist ''${HOME}/.librewolf
    blacklist ''${HOME}/.cache/librewolf
    blacklist ''${HOME}/.config/librewolf
    blacklist ''${HOME}/.local/share/librewolf
  '';

  desktopItem = pkgs.makeDesktopItem {
    name = command;
    desktopName = "LibreWolf Private";
    genericName = "Disposable Hardened Browser";
    exec = "/run/current-system/sw/bin/${command} %U";
    icon = "librewolf";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeTypes = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };
in
{
  options.theorem.nixos.desktop.jailwolf.enable = lib.mkEnableOption ''
    Firejailed LibreWolf disposable browser. This stays an explicit desktop
    application choice; the Firejail substrate may follow it, but Firejail alone
    should not summon a browser onto a host.
  '';

  config = lib.mkIf cfg.enable {
    programs.firejail.wrappedBinaries = {
      ${command} = {
        executable = "${lib.getBin pkgs.librewolf}/bin/librewolf";
        profile = librewolfProfile;
      };
    };

    environment.systemPackages = [
      desktopItem
      librewolfIcons
    ];
  };
}
