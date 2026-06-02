{ pkgs, ... }: {
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

  home.persistence."/nix/persist" = {
    directories = [
      ".cache/fontconfig"
    ];
  };
}
