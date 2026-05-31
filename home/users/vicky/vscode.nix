{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
      ];

      userSettings = {
        "editor.fontSize" = 14;
        "editor.fontLigatures" = true;
        "editor.rulers" = [ 100 ];
        "editor.wordWrapColumn" = 100; # column to wrap at, ignored by default due to wordWrap, relevant e.g. for markdown
        "editor.wordWrap" = "on"; # by default, wrap at the viewport
        "rewrap.wrappingColumn" = 100; # rewrap text with rewrap extension at column 100
        "editor.cursorStyle" = "line";
        "editor.cursorBlinking" = "solid";
        "editor.renderWhitespace" = "boundary";
        "editor.guides.bracketPairs" = true;

        "diffEditor.maxComputationTime" = 0;
      };
    };
  };
}