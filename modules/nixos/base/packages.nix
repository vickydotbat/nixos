{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty
    nano
    git
    vulkan-tools
    steam-run
    zip
    unzip
    unrar
    p7zip
    nix-init
    wineWow64Packages.staging
    nix-index
  ];
}
