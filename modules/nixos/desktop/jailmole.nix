{
  config,
  lib,
  pkgs,
  ...
}:
# `jailmole` is a disposable Mullvad launcher owned by the desktop theorem,
# not a general browser preference. Firejail follows this explicit app choice
# and the profile denies ordinary browser, key, and password-manager state.
let
  cfg = config.theorem.nixos.desktop.jailmole;

  command = "mullvad-private";

  # mullvadIcons = pkgs.runCommand "mullvad-icons" { } ''
  #   mkdir -p $out/share/icons
  #   cp -r ${pkgs.mullvad}/share/icons/hicolor $out/share/icons/
  # '';

  mullvadProfile = pkgs.writeText "mullvad-private.profile" ''
    # Start from Firejail's Firefox profile. Mullvad is Firefox-derived.
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
    blacklist ''${HOME}/.mullvad
    blacklist ''${HOME}/.cache/mullvad
    blacklist ''${HOME}/.config/mullvad
    blacklist ''${HOME}/.local/share/mullvad
  '';

  desktopItem = pkgs.makeDesktopItem {
    name = command;
    desktopName = "Mullvad Private";
    genericName = "Disposable Hardened Browser";
    exec = "/run/current-system/sw/bin/${command} %U";
    icon = "mullvad-browser";
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
  options.theorem.nixos.desktop.jailmole.enable = lib.mkEnableOption ''
    Firejailed Mullvad disposable browser. This stays an explicit desktop
    application choice; the Firejail substrate may follow it, but Firejail alone
    should not summon a browser onto a host.
  '';

  config = lib.mkIf cfg.enable {
    programs.firejail.wrappedBinaries = {
      ${command} = {
        executable = "${lib.getBin pkgs.mullvad-browser}/bin/mullvad-browser";
        profile = mullvadProfile;
      };
    };

    environment.systemPackages = [
      desktopItem
      # mullvadIcons
    ];
  };
}
