{
  config,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:

# User font baseline for graphical homes. It follows the NixOS graphics profile
# when one exists, and stays disabled for standalone Home flakes unless the user
# selects it directly.
let
  cfg = config.theorem.home.base.fonts;
  graphicsEnabled =
    if osConfig == null then false else osConfig.theorem.nixos.desktop.graphics.enable or false;
in
{
  options.theorem.home.base.fonts = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = graphicsEnabled;
      defaultText = lib.literalExpression ''
        osConfig.theorem.nixos.desktop.graphics.enable
      '';
      description = ''
        Enable user font packages. Defaults on for graphics-enabled systems,
        because GUI repair starts with text rendering that can carry its load.
      '';
    };

    fontconfig.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      defaultText = lib.literalExpression "theorem.home.base.fonts.enable";
      description = ''
        Enable fontconfig and persist its cache when Home Manager persistence is
        active.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Broad Unicode coverage
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji

      # Good defaults / document compatibility
      liberation_ttf
      dejavu_fonts

      # Coding fonts
      fira-code
      fira-code-symbols
      jetbrains-mono

      # Terminal / icon glyphs
      nerd-fonts.symbols-only
      # Or use a patched font instead:
      # nerd-fonts.fira-code
      # nerd-fonts.jetbrains-mono

      # Optional: Microsoft-ish compatibility
      corefonts
      vista-fonts
    ];

    fonts.fontconfig = lib.mkIf cfg.fontconfig.enable {
      enable = true;
    };

    home.persistence."/nix/persist" = lib.mkIf (cfg.fontconfig.enable && config.theorem.home.base.persistence.enable) {
      directories = [
        ".cache/fontconfig"
      ];
    };
  };
}
