{ inputs, pkgs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  theorem.home = {
    base = {
      distrobox.enable = true;
      ssh.enable = true;
    };

    desktop = {
      blender.enable = true;
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

    editor = {
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
          eamodio.gitlens
          usernamehw.errorlens
          gruntfuggly.todo-tree
          ms-python.python
          ms-python.vscode-pylance
          ms-vscode.cpptools
          ms-vscode.cmake-tools
        ];
        extraPackages = with pkgs; [
          nixd
          nil
          nixfmt
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
          "editor.renderWhitespace" = "boundary";
          "workbench.colorCustomizations"."editorWhitespace.foreground" = "#3a3a3a";

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

          "editor.insertSpaces" = false;
          "editor.tabSize" = 4;
          "editor.detectIndentation" = true;

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
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;
          "git.allowForcePush" = true;
          "git.confirmForcePush" = false;
          "git.openRepositoryInParentFolders" = "never";
          "gitlens.telemetry.enabled" = false;

          "git.closeDiffOnOperation" = true;
          "diffEditor.experimental.showMoves" = true;
          "diffEditor.ignoreTrimWhitespace" = false;
          "diffEditor.diffAlgorithm" = "advanced";
          "diffEditor.maxComputationTime" = 0;

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

          "[scala]" = {
            "editor.insertSpaces" = true;
            "editor.tabSize" = 2;
          };
          "[markdown]" = {
            "editor.wordWrap" = "bounded";
            "editor.insertSpaces" = true;
            "editor.tabSize" = 2;
          };
          "[haskell]"."editor.insertSpaces" = true;
          "[python]"."editor.insertSpaces" = true;
          "[agda]"."editor.insertSpaces" = true;

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

    gaming = {
      nwn.enable = true;
    };

    shell = {
      bat.enable = true;
      codex = {
        enable = true;
        initialConfig = {
          enable = true;
          settings = {
            model = "gpt-5.5";
            model_reasoning_effort = "high";
            model_reasoning_summary = "concise";
            model_verbosity = "medium";

            approval_policy = "never";
            sandbox_mode = "workspace-write";

            web_search = "cached";
            file_opener = "vscode";
            hide_agent_reasoning = true;

            history.persistence = "none";

            sandbox_workspace_write = {
              network_access = false;
              exclude_slash_tmp = true;
              exclude_tmpdir_env_var = true;
            };

            shell_environment_policy."inherit" = "core";
          };
        };
      };
      ghostty.enable = true;
      git.enable = true;
      nix-index = {
        enable = true;
        commandNotFound.enable = true;
      };
      ripgrep = {
        enable = true;
        arguments = [
          "--hidden"
          "--smart-case"
          "--max-columns=200"
          "--max-columns-preview"

          "--glob=!.git/"
          "--glob=!result"
          "--glob=!result-*"
          "--glob=!.direnv/"
          "--glob=!.devenv/"

          "--colors=line:style:bold"
        ];
      };
      shell.enable = true;
      starship.enable = true;
      zellij.enable = true;
    };

    web = {
      firefox.enable = true;
      firefox-backup.enable = true;
      ungoogled-chromium.enable = true;
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
