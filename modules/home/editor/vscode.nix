{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.editor.vscode;
in
{
  options.theorem.home.editor.vscode.enable = lib.mkEnableOption "Visual Studio Code";

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;

      profiles.default = {
        enableExtensionUpdateCheck = false;
        enableUpdateCheck = false;

        extensions = with pkgs.vscode-extensions; [
          # Nix
          jnoortheen.nix-ide
          mkhl.direnv

          # General config/data files
          editorconfig.editorconfig
          tamasfe.even-better-toml
          redhat.vscode-yaml

          # Git
          eamodio.gitlens

          # Editing quality of life
          usernamehw.errorlens
          gruntfuggly.todo-tree

          # Python, if useful
          ms-python.python
          ms-python.vscode-pylance

          # C/C++, if useful
          ms-vscode.cpptools

          # CMake, if useful
          ms-vscode.cmake-tools
        ];

        userSettings = {
          # First-launch / welcome / sign-in / nag reduction
          "workbench.startupEditor" = "none";
          "workbench.welcomePage.walkthroughs.openOnInstall" = false;
          "workbench.tips.enabled" = false;
          "extensions.ignoreRecommendations" = true;
          "security.workspace.trust.startupPrompt" = "never";
          "security.workspace.trust.enabled" = false;
          "explorer.confirmDragAndDrop" = false;
          "update.showReleaseNotes" = false;

          # Telemetry / experiments
          "telemetry.telemetryLevel" = "off";
          "workbench.enableExperiments" = false;
          "workbench.settings.enableNaturalLanguageSearch" = false;
          "update.mode" = "none";
          "extensions.autoCheckUpdates" = false;
          "extensions.autoUpdate" = false;

          # Accounts / Settings Sync
          "settingsSync.keybindingsPerPlatform" = false;

          # Window styles
          "window.titleBarStyle" = "native";
          "window.customTitleBarVisibility" = "never";
          "window.menuBarVisibility" = "toggle";
          "window.commandCenter" = false;
          "workbench.sideBar.location" = "right";

          # Font
          "editor.fontFamily" = "'JetBrains Mono', 'Fira Code', 'monospace'";
          "editor.fontLigatures" = true;
          "editor.fontSize" = 14;
          "editor.rulers" = [ 80 ];
          "editor.renderWhitespace" = "boundary";
          "workbench.colorCustomizations" = {
            "editorWhitespace.foreground" = "#3a3a3a";
          };

          # Scrollbar
          "editor.minimap.enabled" = false;
          "editor.scrollBeyondLastLine" = false;
          "editor.stickyScroll.enabled" = true;
          "editor.scrollbar.vertical" = "visible";

          # Brackets
          "editor.bracketPairColorization.enabled" = true;
          "editor.guides.bracketPairs" = "active";
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

          # Formatting
          "editor.formatOnSave" = true;
          "editor.formatOnPaste" = false;
          "editor.formatOnType" = false;

          # by default, use tabs for indentation for accessibility reasons
          "editor.insertSpaces" = false;
          "editor.tabSize" = 4;
          "editor.detectIndentation" = true;

          # Word Wrap
          "editor.wordWrapColumn" = 100; # column to wrap at, ignored by default due to wordWrap, relevant e.g. for markdown
          "editor.wordWrap" = "on"; # by default, wrap at the viewport
          "rewrap.wrappingColumn" = 100; # rewrap text with rewrap extension at column 100

          # Disable suggestions
          "editor.inlineSuggest.enabled" = false;
          "editor.acceptSuggestionOnEnter" = "on";
          "editor.acceptSuggestionOnCommitCharacter" = false;
          "editor.suggest.preview" = true;
          "editor.suggestSelection" = "recentlyUsed";
          "editor.copyWithSyntaxHighlighting" = false;

          # Cursor style
          "editor.cursorStyle" = "line";
          "editor.cursorBlinking" = "solid";

          # Files
          "files.trimTrailingWhitespace" = true;
          "files.insertFinalNewline" = true;
          "files.trimFinalNewlines" = true;
          "files.autoSave" = "off";
          "files.enableTrash" = false;
          "files.eol" = "\n";
          "files.exclude" = {
            "**/.direnv" = true;
            "**/.git" = true;
            "**/.hg" = true;
            "**/.svn" = true;
            "**/.DS_Store" = true;
          };
          "search.exclude" = {
            "**/.direnv" = true;
            "**/.git" = true;
            "**/node_modules" = true;
            "**/result" = true;
            "**/result-*" = true;
            "**/.devenv" = true;
          };
          "files.watcherExclude" = {
            "**/.direnv/**" = true;
            "**/.git/objects/**" = true;
            "**/.git/subtree-cache/**" = true;
            "**/node_modules/**" = true;
            "**/result/**" = true;
            "**/result-*/**" = true;
          };
          "files.associations" = {
            # dotnet appsettings.json allows comments
            "appsettings*.json" = "jsonc";
          };

          # Git
          "git.autofetch" = "all"; # regularly fetch from all remotes of the repo
          "git.autofetchPeriod" = 120;
          "git.confirmSync" = false; # no confirm dialog on sync
          "git.enableSmartCommit" = true; # commit all if nothing staged
          "git.allowForcePush" = true;
          "git.confirmForcePush" = false;
          "git.openRepositoryInParentFolders" = "never";
          "gitlens.telemetry.enabled" = false;

          # Diff editor
          "git.closeDiffOnOperation" = true; # close diff editors on commits etc.
          "diffEditor.experimental.showMoves" = true;
          "diffEditor.ignoreTrimWhitespace" = false;
          "diffEditor.diffAlgorithm" = "advanced";
          "diffEditor.maxComputationTime" = 0;

          # Nix IDE
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nixd";
          "nix.formatterPath" = "nixfmt";
          "nix.serverSettings" = {
            nixd = {
              formatting.command = [ "nixfmt" ];
            };
          };
          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
            "editor.formatOnSave" = true;
            "editor.insertSpaces" = true;
            "editor.tabSize" = 2;
            "editor.codeActionsOnSave" = { };
          };

          # Direnv
          "direnv.restart.automatic" = true;

          # YAML
          "yaml.format.enable" = true;
          "yaml.validate" = true;

          # TOML
          "evenBetterToml.formatter.allowedBlankLines" = 2;

          # no pop-up suggestions
          "editor.quickSuggestions" = {
            "other" = false;
            "comments" = false;
            "strings" = false;
          };

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
          "terminal.integrated.enablePersistentSessions" = false;

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

          # Todo-tree
          "todo-tree.general.tags" = [
            "TODO"
            "FIXME"
            "BUG"
            "HACK"
            "NOTE"
            "REVIEW"
          ];
          "todo-tree.regex.regex" = "(//|#|<!--|;|/\\*|^\\s*\\*)\\s*($TAGS)[: ]";
          "todo-tree.tree.showScanModeButton" = false;
          "todo-tree.tree.disableCompactFolders" = false;
        };
      };
    };

    home.packages = with pkgs; [
      nixd
      nil # optional fallback LSP
      nixfmt
      statix
      deadnix
    ];

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        ".config/Code/User/globalStorage"
        ".config/Code/User/workspaceStorage"
      ];
    };
  };
}
