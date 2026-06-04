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
    };
    discord = {
      enable = true;
      autostart.enable = true;
    };
    gimp = {
      enable = true;
      package = pkgs.gimp3-custom;
    };
    keepassxc.enable = true;
    obsidian.enable = true;
    plasma.enable = true;
    spicetify = {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        hidePodcasts
        shuffle
      ];
    };
  };

  programs.ghostty.settings = {
    font-size = 11;
    window-padding-x = 8;
    window-padding-y = 8;
    copy-on-select = "clipboard";
    clipboard-read = "allow";
    clipboard-write = "allow";
  };
}
