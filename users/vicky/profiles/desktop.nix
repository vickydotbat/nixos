{
  inputs,
  pkgs,
  ...
}:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  theorem.home.desktop = {
    blender = {
      enable = true;
      persistedConfigVersions = [ "5.1" ];
      mcp = {
        enable = true;
        # 5.1 = nixpkgs Blender, 4.0 = blender-402-bin (NWN pin).
        addonVersions = [
          "5.1"
          "4.0"
        ];
      };
    };
    discord = {
      enable = true;
      autostart.enable = true;
    };
    ghidra.enable = true;
    gimp = {
      enable = true;
      package = pkgs.gimp3-custom;
    };
    keepassxc.enable = true;
    obsidian.enable = true;
    plasma.enable = true;
    vlc.enable = true;
    spicetify = {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        hidePodcasts
        shuffle
      ];
    };
  };
}
