{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        csharpier.csharpier-vscode
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
        "editor.language.brackets" = [
          [
            "["
            "]"
          ]
          [
            "{"
            "}"
          ]
          [
            "("
            ")"
          ]
          [
            "⟨"
            "⟩"
          ]
        ];

        "diffEditor.maxComputationTime" = 0;

        # by default, use tabs for indentation for accessibility reasons
        "editor.insertSpaces" = false;
        "editor.tabSize" = 4;
        "editor.detectIndentation" = true;

        # no pop-up suggestions
        "editor.quickSuggestions" = {
          "other" = false;
          "comments" = false;
          "strings" = false;
        };

        "editor.inlineSuggest.enabled" = false;
        "editor.acceptSuggestionOnEnter" = "on";
        "editor.acceptSuggestionOnCommitCharacter" = false;
        "editor.suggest.preview" = true;
        "editor.suggestSelection" = "recentlyUsed";
        "editor.copyWithSyntaxHighlighting" = false;

        "editor.scrollbar.vertical" = "visible";
        "editor.minimap.enabled" = false;

        "diffEditor.experimental.showMoves" = true;
        "diffEditor.ignoreTrimWhitespace" = false;
        "diffEditor.diffAlgorithm" = "advanced";

        "window.titleBarStyle" = "native";
        "window.customTitleBarVisibility" = "never";
        "window.menuBarVisibility" = "toggle";
        "window.commandCenter" = false;

        "explorer.confirmDragAndDrop" = false;

        "files.trimFinalNewlines" = true;
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;

        "files.watcherExclude" = {
          "**/.bloop" = true;
          "**/.metals" = true;
          "**/.ammonite" = true;
        };

        "files.associations" = {
          # dotnet appsettings.json allows comments
          "appsettings*.json" = "jsonc";
        };
        "files.enableTrash" = false;

        "workbench.startupEditor" = "none";
        "workbench.sideBar.location" = "right";

        "security.workspace.trust.enabled" = false;
        "update.showReleaseNotes" = false;
        "extensions.autoUpdate" = false;

        # git
        "git.enableSmartCommit" = true; # commit all if nothing staged
        "git.confirmSync" = false; # no confirm dialog on sync
        "git.autofetch" = "all"; # regularly fetch from all remotes of the repo
        "git.autofetchPeriod" = 120;
        "git.closeDiffOnOperation" = true; # close diff editors on commits etc.
        "git.allowForcePush" = true;
        "git.confirmForcePush" = false;

        # terminal
        "terminal.integrated.tabs.enabled" = false;
        "terminal.integrated.scrollback" = 5000;
        "terminal.integrated.cursorStyle" = "line";
        "terminal.integrated.minimumContrastRatio" = 1;
        "terminal.integrated.env.linux" = {
          # -r: reuse existing window, -w: wait until file is closed
          EDITOR = "code -rw";
          VISUAL = "code -rw";
        };
        "terminal.integrated.commandsToSkipShell" = [
          "workbench.action.toggleSidebarVisibility"
        ];
        "terminal.integrated.initialHint" = false;

        # language specific indentation settings
        "[scala]" = {
          # follow Scala style guide
          "editor.insertSpaces" = true;
          "editor.tabSize" = 2;
        };
        "[markdown]" = {
          # indent markdown with spaces so YAML frontmatter doesn't break
          "editor.wordWrap" = "bounded"; # wrap markdown files at line width
          "editor.insertSpaces" = true;
          "editor.tabSize" = 2;
        };
        "[haskell]"."editor.insertSpaces" = true; # GHC warns when using tabs
        "[python]"."editor.insertSpaces" = true; # black forces spaces
        "[agda]"."editor.insertSpaces" = true; # agda forces spaces
      };
    };
  };
}
