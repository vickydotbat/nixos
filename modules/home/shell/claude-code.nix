{
  config,
  inputs,
  lib,
  options,
  pkgs,
  repository ? {
    path = "/nix/nixos";
    group = "nixcfg";
  },
  ...
}:

# Claude Code is operator tooling. This module installs the selected package,
# writes reusable baseline config, and persists agent state only when the user's
# Home persistence theorem says that state should survive reboot.
#
# Unlike the normal flake-input style, the default package is a live wrapper:
# every `claude` launch refreshes and runs the configured flake ref directly.

let
  cfg = config.theorem.home.shell.claude;

  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;

  json = pkgs.formats.json { };

  computedSettingsFile = json.generate "claude-settings.json" cfg.computedSettings;

  initialConfigFile = json.generate "claude-settings-initial.json" cfg.initialConfig.settings;

  superpowersSkills = lib.mapAttrs (
    name: _type: lib.mkDefault (cfg.superpowers.source + "/${name}")
  ) (builtins.readDir cfg.superpowers.source);

  claudeLivePackage = pkgs.stdenvNoCC.mkDerivation {
    pname = "claude-live";
    version = "999.0.0";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      install -d "$out/bin"
      cat > "$out/bin/claude" <<'EOF'
      #!${pkgs.runtimeShell}
      set -euo pipefail

      flake_ref=${lib.escapeShellArg cfg.live.flakeRef}
      flake_attr=${lib.escapeShellArg cfg.live.flakeAttr}
      nix_command=${lib.escapeShellArg "${pkgs.nix}/bin/nix"}
      nix_args=(
        --extra-experimental-features
        'nix-command flakes'
      )

      run_ref="$flake_ref"
      if [[ -n "$flake_attr" ]]; then
        run_ref="$flake_ref#$flake_attr"
      fi

      ${lib.optionalString cfg.live.refreshOnRun ''
        if ! "$nix_command" "''${nix_args[@]}" flake metadata --refresh "$flake_ref" >/dev/null; then
          printf '%s\n' "claude live refresh failed; using cached flake if available: $flake_ref" >&2
        fi
      ''}

      exec "$nix_command" "''${nix_args[@]}" run "$run_ref" -- "$@"
      EOF
      chmod +x "$out/bin/claude"

      runHook postInstall
    '';

    meta = {
      description = "Self-refreshing Claude Code latest wrapper";
      homepage = "https://github.com/ryoppippi/nix-claude-code";
      mainProgram = "claude";
    };
  };

  renderTextOrPath = value: if builtins.isPath value then { source = value; } else { text = value; };

  renderSkill =
    name: value:
    let
      pathHasSkill = builtins.isPath value && builtins.pathExists "${value}/SKILL.md";
    in
    if pathHasSkill then
      lib.nameValuePair ".claude/skills/${name}" {
        source = value;
        recursive = true;
      }
    else if builtins.isPath value then
      lib.nameValuePair ".claude/skills/${name}/SKILL.md" {
        source = value;
      }
    else
      lib.nameValuePair ".claude/skills/${name}/SKILL.md" {
        text = value;
      };

  skillFiles = lib.mapAttrs' renderSkill cfg.computedSkills;
in
{
  options.theorem.home.shell.claude = {
    enable = lib.mkEnableOption "Claude Code";

    live = {
      flakeRef = lib.mkOption {
        type = lib.types.str;
        default = "github:ryoppippi/nix-claude-code";
        description = ''
          Flake reference used by the default Claude live wrapper. Keep this
          as a moving reference when Claude Code should track upstream builds
          without teaching this repository's `flake.lock` to carry that churn.
        '';
      };

      flakeAttr = lib.mkOption {
        type = lib.types.str;
        default = "latest";
        description = ''
          Flake output attribute used by `nix run`. Use `latest` for newest
          Claude Code releases, or `stable` for the slower channel.
        '';
      };

      refreshOnRun = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Refresh the Claude live flake before each `claude` invocation. When
          the network or Nix daemon is unavailable, the wrapper warns and then
          tries the cached flake output so the repair bench can still open.
        '';
      };
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = claudeLivePackage;
      defaultText = lib.literalExpression "theorem.home.shell.claude live wrapper";
      description = ''
        Claude Code package to install. Defaults to a self-refreshing wrapper
        around `live.flakeRef`, so latest updates do not require this
        repository's `flake.lock` to move.
      '';
    };

    unrestricted = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Match the local-trusted Codex posture: no recurring approvals and no
        bash sandbox. Sets Claude's permission mode to `bypassPermissions` and
        disables Claude Code bash sandboxing.
      '';
    };

    persistState = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist Claude state when Home persistence is active. Keep this enabled
        when login state, workspace trust, MCP state, or local approval memory
        are part of the operator's repair kit.
      '';
    };

    trustNixosConfiguration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Add `repository.path` as an additional Claude-accessible directory.
        Claude Code project trust itself is stored in `~/.claude.json`, not
        declaratively here.
      '';
    };

    manageSettings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Declaratively own `~/.claude/settings.json`. Disable this when the
        operator wants Claude Code's `/config` UI to own the file after first
        spawn.
      '';
    };

    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = ''
        Additional Claude Code settings written to `~/.claude/settings.json`.
        The module provides defaults with `mkDefault`; user profiles should set
        model choice, approval posture, and other personal doctrine here.
      '';
    };

    computedSettings = lib.mkOption {
      type = json.type;
      default = { };
      internal = true;
      description = ''
        Fully merged Claude Code settings. Internal option used so mkDefault and
        mkMerge are resolved by the module system before JSON generation.
      '';
    };

    context = lib.mkOption {
      type = lib.types.either lib.types.lines lib.types.path;
      default = "";
      description = ''
        Global Claude context written to `~/.claude/CLAUDE.md`. Keep this short:
        repository doctrine belongs in project `CLAUDE.md`, while this is the
        operator's portable field note.
      '';
    };

    superpowers = {
      enable = lib.mkEnableOption "Superpowers Claude skills";

      source = lib.mkOption {
        type = lib.types.path;
        default = inputs.superpowers + "/skills";
        defaultText = lib.literalExpression ''inputs.superpowers + "/skills"'';
        description = ''
          Directory containing Superpowers skill folders. Defaults to the pinned
          `superpowers` flake input so updates pass through `flake.lock` instead
          of an unmanaged `git pull`.
        '';
      };
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Additional Claude skills. Text values become `SKILL.md`. Path values are
        treated as either complete skill directories containing `SKILL.md`, or
        direct `SKILL.md` files. Profile-defined skills win if a name collides.
      '';
    };

    computedSkills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      internal = true;
      description = ''
        Fully merged Claude skills. Internal option used so mkDefault and mkMerge
        are resolved by the module system before rendering home.file entries.
      '';
    };

    initialConfig = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Seed `~/.claude/settings.json` only when it does not already exist.
          Useful when `manageSettings = false`; ignored when the declarative file
          already exists.
        '';
      };

      settings = lib.mkOption {
        type = json.type;
        default = { };
        description = ''
          Initial Claude settings written only when `~/.claude/settings.json` is
          absent. Workflow policy, model choice, and permission posture are user
          doctrine and should be set from user modules.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        cfg.package
      ];

      theorem.home.shell.claude.computedSettings = lib.mkMerge [
        {
          "$schema" = lib.mkDefault "https://json.schemastore.org/claude-code-settings.json";

          model = lib.mkDefault "sonnet";
          effortLevel = lib.mkDefault "high";

          autoMemoryEnabled = lib.mkDefault false;
          cleanupPeriodDays = lib.mkDefault 20;
          editorMode = lib.mkDefault "vim";
          fastModePerSessionOptIn = lib.mkDefault true;
          includeGitInstructions = lib.mkDefault true;

          # Let the Nix wrapper handle updates.
          autoUpdatesChannel = lib.mkDefault "latest";

          # Avoid OS protocol-handler churn from a declarative environment.
          disableDeepLinkRegistration = lib.mkDefault "disable";

          permissions = {
            defaultMode = lib.mkDefault (if cfg.unrestricted then "bypassPermissions" else "acceptEdits");

            additionalDirectories = lib.mkIf cfg.trustNixosConfiguration (
              lib.mkDefault [
                repository.path
              ]
            );

            allow = lib.mkDefault [
              "Bash(git status)"
              "Bash(git diff *)"
              "Bash(git log *)"
              "Bash(git show *)"
              "Bash(rg *)"
              "Bash(fd *)"
              "Bash(ls *)"
              "Bash(cat *)"

              "Bash(nix flake check *)"
              "Bash(nix flake metadata *)"
              "Bash(nix flake show *)"
              "Bash(nix eval *)"
              "Bash(nix build *)"
              "Bash(nix fmt *)"
              "Bash(nixfmt *)"

              "Bash(nh os build *)"
              "Bash(home-manager build *)"
            ];

            ask = lib.mkDefault [
              "Bash(git add *)"
              "Bash(git commit *)"
              "Bash(git push *)"

              "Bash(nix flake update *)"
              "Bash(nh os switch *)"
              "Bash(nixos-rebuild switch *)"
              "Bash(home-manager switch *)"

              "Bash(systemctl *)"
              "Bash(docker *)"
              "Bash(podman *)"

              "Bash(ssh *)"
              "Bash(scp *)"
              "Bash(rsync *)"
              "Bash(curl *)"
              "Bash(wget *)"
            ];

            deny = lib.mkDefault [
              "Read(./.env)"
              "Read(./.env.*)"
              "Read(./secrets/**)"
              "Read(./**/secrets/**)"
              "Read(./.sops.yaml)"
              "Read(./*.age)"

              "Read(~/.ssh/**)"
              "Read(~/.aws/**)"
              "Read(~/.config/sops/**)"

              "Bash(sudo *)"
              "Bash(su *)"
              "Bash(doas *)"
              "Bash(rm -rf *)"
            ];
          };

          sandbox = {
            enabled = lib.mkDefault (!cfg.unrestricted);
            failIfUnavailable = lib.mkDefault false;
            autoAllowBashIfSandboxed = lib.mkDefault true;

            filesystem = {
              allowWrite = lib.mkDefault [
                repository.path
                "/tmp"
              ];

              denyRead = lib.mkDefault [
                "~/.ssh"
                "~/.aws"
                "~/.config/sops"
              ];
            };

            network = {
              # Required on Linux/WSL if sandboxed commands need daemon sockets.
              allowAllUnixSockets = lib.mkDefault true;
            };
          };

          skipDangerousModePermissionPrompt = lib.mkDefault cfg.unrestricted;

          env = {
            API_TIMEOUT_MS = lib.mkDefault "1200000";
            BASH_DEFAULT_TIMEOUT_MS = lib.mkDefault "300000";

            EDITOR = lib.mkDefault "code --wait";
            VISUAL = lib.mkDefault "code --wait";

            # Nix owns the executable freshness.
            DISABLE_AUTOUPDATER = lib.mkDefault "1";

            DO_NOT_TRACK = lib.mkDefault "1";
            DISABLE_TELEMETRY = lib.mkDefault "1";

            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = lib.mkDefault "1";
            CLAUDE_CODE_DISABLE_AUTO_MEMORY = lib.mkDefault "1";
            CLAUDE_CODE_SKIP_PROMPT_HISTORY = lib.mkDefault "1";
            CLAUDE_CODE_SUBPROCESS_ENV_SCRUB = lib.mkDefault "1";

            CLAUDE_CODE_AUTO_CONNECT_IDE = lib.mkDefault "true";
            CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL = lib.mkDefault "1";
          };
        }

        cfg.settings
      ];

      theorem.home.shell.claude.computedSkills = lib.mkMerge [
        (lib.mkIf cfg.superpowers.enable superpowersSkills)
        cfg.skills
      ];

      home.file = lib.mkMerge [
        (lib.mkIf cfg.manageSettings {
          ".claude/settings.json".source = computedSettingsFile;
        })

        (lib.mkIf (cfg.context != "") {
          ".claude/CLAUDE.md" = renderTextOrPath cfg.context;
        })

        skillFiles
      ];

      home.activation.claudeInitialConfig = lib.mkIf cfg.initialConfig.enable (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          config_dir=${lib.escapeShellArg "${config.home.homeDirectory}/.claude"}
          config_file="$config_dir/settings.json"

          if [[ ! -e "$config_file" ]]; then
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -d -m 0700 "$config_dir"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0600 ${lib.escapeShellArg initialConfigFile} "$config_file"
          fi
        ''
      );
    })

    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persistState) {
        directories = [
          ".claude"
        ];

        files = [
          ".claude.json"
        ];
      };
    })
  ];
}
