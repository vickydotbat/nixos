{
  inputs,
  pkgs,
  ...
}:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # Derived, not hardcoded: a nixpkgs Blender bump would otherwise silently
  # strand the old config directory and take the MCP addon with it.
  nixpkgsBlenderVersion = pkgs.lib.versions.majorMinor pkgs.blender.version;
in
{
  theorem.home.desktop = {
    blender = {
      enable = true;
      # Only the nixpkgs Blender's own config directories belong here. The NWN
      # module already persists 4.0 and 5.0 for the pinned NWN Blender; listing
      # them again would duplicate the bind mount.
      #
      # 5.1 is the state from before nixpkgs moved to 5.2. Drop it once the
      # current Blender has been set up once.
      persistedConfigVersions = pkgs.lib.unique [
        "5.1"
        nixpkgsBlenderVersion
      ];
      mcp = {
        enable = true;
        # Persistence and addon reach differ: 5.0 is the blender-501-bin NWN
        # pin, persisted elsewhere, but it still wants the MCP addon here.
        addonVersions = pkgs.lib.unique [
          "5.0"
          "5.1"
          nixpkgsBlenderVersion
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
