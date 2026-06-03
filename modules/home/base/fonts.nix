{
  config,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.base.fonts;
  graphicsEnabled = (osConfig.theorem.nixos.desktop.graphics.enable or false);
  desktopAppEnabled =
    let
      home = config.theorem.home;
    in
    lib.any (enabled: enabled) [
      (home.desktop.blender.enable or false)
      (home.desktop.discord.enable or false)
      (home.desktop.gimp.enable or false)
      (home.desktop.keepassxc.enable or false)
      (home.desktop.obsidian.enable or false)
      (home.desktop.plasma.enable or false)
      (home.desktop.spicetify.enable or false)
      (home.editor.vscode.enable or false)
      (home.web.firefox.enable or false)
      (home.web.ungoogled-chromium.enable or false)
    ];
in
{
  options.theorem.home.base.fonts.enable = lib.mkOption {
    type = lib.types.bool;
    default = graphicsEnabled && desktopAppEnabled;
    defaultText = lib.literalExpression ''
      osConfig.theorem.nixos.desktop.graphics.enable && any desktop/app theorem is enabled
    '';
    description = ''
      Enable user font packages. Defaults on for graphics-enabled systems with
      desktop applications, because GUI repair starts with text rendering that
      can actually carry its load.
    '';
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

    fonts.fontconfig = {
      enable = true;
    };

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        ".cache/fontconfig"
      ];
    };
  };
}
