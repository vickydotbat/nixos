{
  pkgs,
  ...
}:
let
  prettierFormatter = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };

  prettierTwoSpaceFormatter = prettierFormatter // {
    "editor.insertSpaces" = true;
    "editor.tabSize" = 2;
    "prettier.tabWidth" = 2;
  };
in
{
  theorem.home.editor = {
    helix = {
      enable = true;
      settings = {
        theme = "catppuccin_mocha";

        editor = {
          line-number = "relative";
          mouse = true;
          cursorline = true;
          bufferline = "multiple";
          color-modes = true;
          true-color = true;

          indent-guides.render = true;
          soft-wrap.enable = true;
        };

        keys.normal = {
          space.w = ":write";
          space.q = ":quit";
          space.x = ":buffer-close";
        };
      };
    };

    vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        mkhl.direnv
        editorconfig.editorconfig
        tamasfe.even-better-toml
        redhat.vscode-yaml
        mhutchie.git-graph
        waderyan.gitblame
        usernamehw.errorlens
        gruntfuggly.todo-tree
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode.cpptools
        ms-vscode.cmake-tools
        catppuccin.catppuccin-vsc
        esbenp.prettier-vscode
        pkief.material-icon-theme
        streetsidesoftware.code-spell-checker
        evertjunior.mass-renamer
      ];
      extraPackages = with pkgs; [
        nixd
        nil
        nixfmt
        prettier
        statix
        deadnix
      ];
      userSettings = {
        "workbench.startupEditor" = "none";
        "workbench.welcomePage.walkthroughs.openOnInstall" = false;
        "workbench.tips.enabled" = false;
        "extensions.ignoreRecommendations" = true;
        "security.workspace.trust.startupPrompt" = "never";
        "security.workspace.trust.enabled" = false;
        "explorer.confirmDragAndDrop" = false;
        "update.showReleaseNotes" = false;

        "telemetry.telemetryLevel" = "off";
        "workbench.enableExperiments" = false;
        "workbench.settings.enableNaturalLanguageSearch" = false;
        "update.mode" = "none";
        "extensions.autoCheckUpdates" = false;
        "extensions.autoUpdate" = false;

        "settingsSync.keybindingsPerPlatform" = false;

        "window.titleBarStyle" = "native";
        "window.customTitleBarVisibility" = "never";
        "window.menuBarVisibility" = "toggle";
        "window.commandCenter" = false;
        "workbench.sideBar.location" = "right";

        "editor.fontFamily" = "'JetBrains Mono', 'Fira Code', 'monospace'";
        "editor.fontLigatures" = true;
        "editor.fontSize" = 14;
        "editor.rulers" = [ 80 ];
        "editor.renderWhitespace" = "none";
        "workbench.colorCustomizations"."editorWhitespace.foreground" = "#3a3a3a";
        "window.autoDetectColorScheme" = true;
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.preferredLightColorTheme" = "Catppuccin Latte";
        "workbench.preferredDarkColorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "material-icon-theme";

        "editor.minimap.enabled" = false;
        "editor.scrollBeyondLastLine" = false;
        "editor.stickyScroll.enabled" = true;
        "editor.scrollbar.vertical" = "visible";

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

        "editor.formatOnSave" = true;
        "editor.formatOnPaste" = false;
        "editor.formatOnType" = false;
        "editor.defaultFormatter" = "esbenp.prettier-vscode";

        "editor.insertSpaces" = true;
        "editor.tabSize" = 4;
        "editor.detectIndentation" = false;
        "prettier.enable" = true;
        "prettier.requireConfig" = false;
        "prettier.useEditorConfig" = true;
        "prettier.useTabs" = false;
        "prettier.tabWidth" = 4;

        "editor.wordWrapColumn" = 100;
        "editor.wordWrap" = "on";
        "rewrap.wrappingColumn" = 100;

        "editor.inlineSuggest.enabled" = false;
        "editor.acceptSuggestionOnEnter" = "on";
        "editor.acceptSuggestionOnCommitCharacter" = false;
        "editor.suggest.preview" = true;
        "editor.suggestSelection" = "recentlyUsed";
        "editor.copyWithSyntaxHighlighting" = false;

        "editor.cursorStyle" = "line";
        "editor.cursorBlinking" = "solid";

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
        "files.associations"."appsettings*.json" = "jsonc";

        "git.autofetch" = "all";
        "git.autofetchPeriod" = 120;

        "git.confirmSync" = true;
        "git.rebaseWhenSync" = false;

        "git.enableSmartCommit" = false;
        "git.openRepositoryInParentFolders" = "never";

        # Shared-repo safety:
        "git.allowForcePush" = false;
        "git.confirmForcePush" = true;
        "git.useForcePushWithLease" = true;

        "git.closeDiffOnOperation" = true;
        "diffEditor.experimental.showMoves" = true;
        "diffEditor.ignoreTrimWhitespace" = false;
        "diffEditor.diffAlgorithm" = "advanced";
        "diffEditor.maxComputationTime" = 0;

        # Git Blame: keep it mostly out of the way
        "gitblame.statusBarMessageFormat" = "\${author.name}, \${time.ago}";
        "gitblame.statusBarMessageNoCommit" = "Uncommitted";
        "gitblame.parallelBlames" = 1;
        "gitblame.extendedHoverInformation" = "off";

        # Git Graph: useful defaults
        "git-graph.repository.fetchAndPrune" = true;
        "git-graph.repository.commits.fetchAvatars" = false;
        "git-graph.repository.commits.showSignatureStatus" = false;
        "git-graph.repository.commits.showRemoteBranches" = true;
        "git-graph.repository.commits.showTags" = true;
        "git-graph.repository.commits.showLocalBranches" = true;

        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.formatterPath" = "nixfmt";
        "nix.serverSettings".nixd.formatting.command = [ "nixfmt" ];
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.formatOnSave" = true;
          "editor.insertSpaces" = true;
          "editor.tabSize" = 2;
          "editor.codeActionsOnSave" = { };
        };
        "cSpell.enabledFileTypes".nix = false;
        "cSpell.allowCompoundWords" = true;
        "cSpell.dictionaries" = [
          "bash"
          "companies"
          "cpp"
          "cpp-compound-words"
          "cpp-legacy"
          "cpp-refined"
          "css"
          "filetypes"
          "fonts"
          "game-development"
          "gaming-terms"
          "git"
          "html"
          "html-symbol-entities"
          "makefile"
          "node"
          "npm"
          "powershell"
          "public-licenses"
          "python"
          "python-common"
          "shellscript"
          "softwareTerms"
          "typescript"
        ];
        "cSpell.words" = [
          "cachix"
          "deadnix"
          "disko"
          "home-manager"
          "impermanence"
          "libexec"
          "mkEnableOption"
          "mkForce"
          "mkIf"
          "mkOption"
          "nixcfg"
          "nixd"
          "nixfmt"
          "nixos"
          "nixpkgs"
          "Polkit"
          "run0"
          "sops"
          "statix"
          "systemd"
        ];

        "direnv.restart.automatic" = true;

        "yaml.format.enable" = true;
        "yaml.validate" = true;

        "evenBetterToml.formatter.allowedBlankLines" = 2;

        "editor.quickSuggestions" = {
          other = false;
          comments = false;
          strings = false;
        };

        "terminal.integrated.tabs.enabled" = false;
        "terminal.integrated.scrollback" = 5000;
        "terminal.integrated.cursorStyle" = "line";
        "terminal.integrated.minimumContrastRatio" = 1;
        "terminal.integrated.env.linux" = {
          EDITOR = "code -rw";
          VISUAL = "code -rw";
        };
        "terminal.integrated.commandsToSkipShell" = [
          "workbench.action.toggleSidebarVisibility"
        ];
        "terminal.integrated.initialHint" = false;
        "terminal.integrated.enablePersistentSessions" = false;

        "[scala]" = prettierTwoSpaceFormatter;
        "[javascript]" = prettierTwoSpaceFormatter;
        "[javascriptreact]" = prettierTwoSpaceFormatter;
        "[typescript]" = prettierTwoSpaceFormatter;
        "[typescriptreact]" = prettierTwoSpaceFormatter;
        "[json]" = prettierTwoSpaceFormatter;
        "[jsonc]" = prettierTwoSpaceFormatter;
        "[html]" = prettierTwoSpaceFormatter;
        "[css]" = prettierTwoSpaceFormatter;
        "[scss]" = prettierTwoSpaceFormatter;
        "[less]" = prettierTwoSpaceFormatter;
        "[vue]" = prettierTwoSpaceFormatter;
        "[svelte]" = prettierTwoSpaceFormatter;
        "[graphql]" = prettierTwoSpaceFormatter;
        "[yaml]" = prettierTwoSpaceFormatter;
        "[markdown]" = prettierTwoSpaceFormatter // {
          "editor.wordWrap" = "bounded";
        };
        "[mdx]" = prettierTwoSpaceFormatter;

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
}
