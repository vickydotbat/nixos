{
  config,
  lib,
  options,
  inputs,
  ...
}:

let
  cfg = config.theorem.home.agents.skills;

  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;

  mkSkillLinks =
    targetPrefix: source:
    lib.mapAttrs' (
      name: _type:
      lib.nameValuePair "${targetPrefix}/${name}" {
        source = source + "/${name}";
        recursive = true;
      }
    ) (builtins.readDir source);

  superpowersShared = lib.optionalAttrs cfg.superpowers.enable (
    mkSkillLinks ".agents/skills" cfg.superpowers.source
  );

  ponytailShared = lib.optionalAttrs cfg.ponytail.enable (
    mkSkillLinks ".agents/skills" cfg.ponytail.source
  );

  superpowersCodex = lib.optionalAttrs (cfg.superpowers.enable && cfg.targets.codex) (
    mkSkillLinks ".codex/skills" cfg.superpowers.source
  );

  ponytailCodex = lib.optionalAttrs (cfg.ponytail.enable && cfg.targets.codex) (
    mkSkillLinks ".codex/skills" cfg.ponytail.source
  );

  superpowersOpenCode = lib.optionalAttrs (cfg.superpowers.enable && cfg.targets.opencode) (
    mkSkillLinks ".config/opencode/skills" cfg.superpowers.source
  );

  ponytailOpenCode = lib.optionalAttrs (cfg.ponytail.enable && cfg.targets.opencode) (
    mkSkillLinks ".config/opencode/skills" cfg.ponytail.source
  );

  superpowersClaude = lib.optionalAttrs (cfg.superpowers.enable && cfg.targets.claude) (
    mkSkillLinks ".claude/skills" cfg.superpowers.source
  );

  ponytailClaude = lib.optionalAttrs (cfg.ponytail.enable && cfg.targets.claude) (
    mkSkillLinks ".claude/skills" cfg.ponytail.source
  );

  allSkillFiles =
    superpowersShared
    // ponytailShared
    // superpowersCodex
    // ponytailCodex
    // superpowersOpenCode
    // ponytailOpenCode
    // superpowersClaude
    // ponytailClaude;
in
{
  options.theorem.home.agents.skills = {
    enable = lib.mkEnableOption "shared AI agent skills";

    persist = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist shared agent skill/config directories when Home persistence is available.
      '';
    };

    targets = {
      codex = lib.mkOption {
        type = lib.types.bool;
        default = config.theorem.home.shell.codex.enable or false;
        defaultText = lib.literalExpression "config.theorem.home.shell.codex.enable or false";
        description = "Install shared skills for Codex.";
      };

      opencode = lib.mkOption {
        type = lib.types.bool;
        default = config.theorem.home.agents.opencode.enable or false;
        defaultText = lib.literalExpression "config.theorem.home.agents.opencode.enable or false";
        description = "Install shared skills for OpenCode.";
      };

      claude = lib.mkOption {
        type = lib.types.bool;
        default = config.theorem.home.agents.claude.enable or false;
        defaultText = lib.literalExpression "config.theorem.home.agents.claude.enable or false";
        description = "Install shared skills for Claude Code.";
      };
    };

    superpowers = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Superpowers skills into enabled agent targets.";
      };

      source = lib.mkOption {
        type = lib.types.path;
        default = inputs.superpowers + "/skills";
        defaultText = lib.literalExpression ''inputs.superpowers + "/skills"'';
        description = "Directory containing Superpowers skill folders.";
      };
    };

    ponytail = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Ponytail skills into enabled agent targets.";
      };

      source = lib.mkOption {
        type = lib.types.path;
        default = inputs.ponytail + "/skills";
        defaultText = lib.literalExpression ''inputs.ponytail + "/skills"'';
        description = "Directory containing Ponytail skill folders.";
      };

      level = lib.mkOption {
        type = lib.types.enum [
          "lite"
          "full"
          "ultra"
          "off"
        ];
        default = "full";
        description = "Default Ponytail mode shared across agent harnesses.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.file =
        allSkillFiles
        // lib.optionalAttrs cfg.ponytail.enable {
          ".config/ponytail/config.json".text = builtins.toJSON {
            defaultMode = cfg.ponytail.level;
          };
        };

      home.sessionVariables = lib.mkIf cfg.ponytail.enable {
        PONYTAIL_DEFAULT_MODE = cfg.ponytail.level;
      };
    })

    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && cfg.persist) {
        directories = [
          ".agents"
        ]
        ++ lib.optional cfg.ponytail.enable ".config/ponytail";
      };
    })
  ];
}
