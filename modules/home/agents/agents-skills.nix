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

  # Link every immediate child of a source directory into a target prefix.
  # Directories are linked recursively; files are linked normally.
  mkLinks =
    targetPrefix: source:
    lib.mapAttrs' (
      name: type:
      lib.nameValuePair "${targetPrefix}/${name}" (
        {
          source = source + "/${name}";
        }
        // lib.optionalAttrs (type == "directory") {
          recursive = true;
        }
      )
    ) (builtins.readDir source);

  mkLinksIfExists =
    targetPrefix: source:
    lib.optionalAttrs (source != null && builtins.pathExists source) (mkLinks targetPrefix source);

  mkSkillLinks = targetPrefix: source: mkLinksIfExists targetPrefix source;

  superpowersShared = lib.optionalAttrs cfg.superpowers.enable (
    mkSkillLinks ".agents/skills" cfg.superpowers.source
  );

  ponytailShared = lib.optionalAttrs cfg.ponytail.enable (
    mkSkillLinks ".agents/skills" cfg.ponytail.source
  );

  guardrailsShared = lib.optionalAttrs (cfg.guardrails.enable && cfg.guardrails.shared) (
    mkSkillLinks ".agents/skills" (cfg.guardrails.source + "/skills")
  );

  superpowersCodex = lib.optionalAttrs (cfg.superpowers.enable && cfg.targets.codex) (
    mkSkillLinks ".codex/skills" cfg.superpowers.source
  );

  ponytailCodex = lib.optionalAttrs (cfg.ponytail.enable && cfg.targets.codex) (
    mkSkillLinks ".codex/skills" cfg.ponytail.source
  );

  guardrailsCodex = lib.optionalAttrs (
    cfg.guardrails.enable && cfg.targets.codex && cfg.guardrails.codex
  ) (mkSkillLinks ".codex/skills" (cfg.guardrails.source + "/skills"));

  superpowersOpenCode = lib.optionalAttrs (cfg.superpowers.enable && cfg.targets.opencode) (
    mkSkillLinks ".config/opencode/skills" cfg.superpowers.source
  );

  ponytailOpenCode = lib.optionalAttrs (cfg.ponytail.enable && cfg.targets.opencode) (
    mkSkillLinks ".config/opencode/skills" cfg.ponytail.source
  );

  guardrailsOpenCode = lib.optionalAttrs (cfg.guardrails.enable && cfg.targets.opencode) (
    mkSkillLinks ".config/opencode/skills" (cfg.guardrails.source + "/skills")
  );

  guardrailsOpenCodeCommands = lib.optionalAttrs (
    cfg.guardrails.enable && cfg.targets.opencode && cfg.guardrails.commands
  ) (mkLinksIfExists ".config/opencode/commands" (cfg.guardrails.source + "/commands"));

  guardrailsOpenCodeAgentDefinitions = lib.optionalAttrs (
    cfg.guardrails.enable && cfg.targets.opencode && cfg.guardrails.agents
  ) (mkLinksIfExists ".config/opencode/agents" (cfg.guardrails.source + "/agents"));

  guardrailsOpenCodeAgentsMd =
    lib.optionalAttrs
      (
        cfg.guardrails.enable
        && cfg.targets.opencode
        && cfg.guardrails.agentsMd
        && builtins.pathExists (cfg.guardrails.source + "/AGENTS.md")
      )
      {
        ".config/opencode/AGENTS.md".source = cfg.guardrails.source + "/AGENTS.md";
      };

  superpowersClaude = lib.optionalAttrs (cfg.superpowers.enable && cfg.targets.claude) (
    mkSkillLinks ".claude/skills" cfg.superpowers.source
  );

  ponytailClaude = lib.optionalAttrs (cfg.ponytail.enable && cfg.targets.claude) (
    mkSkillLinks ".claude/skills" cfg.ponytail.source
  );

  guardrailsClaude = lib.optionalAttrs (
    cfg.guardrails.enable && cfg.targets.claude && cfg.guardrails.claude
  ) (mkSkillLinks ".claude/skills" (cfg.guardrails.source + "/skills"));

  allSkillFiles =
    superpowersShared
    // ponytailShared
    // guardrailsShared
    // superpowersCodex
    // ponytailCodex
    // guardrailsCodex
    // superpowersOpenCode
    // ponytailOpenCode
    // guardrailsOpenCode
    // superpowersClaude
    // ponytailClaude
    // guardrailsClaude;

  allCommandFiles = guardrailsOpenCodeCommands;

  allAgentFiles = guardrailsOpenCodeAgentDefinitions // guardrailsOpenCodeAgentsMd;
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

    guardrails = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install local agent guardrail skills and OpenCode commands.";
      };

      source = lib.mkOption {
        type = lib.types.path;
        description = ''
          Root directory containing AGENTS.md and .opencode/skills plus optionally
          .opencode/commands and .opencode/agents.

          Example layout:

            AGENTS.md
            .opencode/skills/context-discovery/SKILL.md
            .opencode/commands/context-pass.md
            .opencode/agents/context-scout.md
        '';
      };

      shared = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install guardrail skills into .agents/skills.";
      };

      codex = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Also install guardrail skills into .codex/skills.";
      };

      claude = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Also install guardrail skills into .claude/skills.";
      };

      commands = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install guardrail OpenCode commands into ~/.config/opencode/commands.";
      };

      agents = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install guardrail OpenCode agents into ~/.config/opencode/agents.";
      };

      agentsMd = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install guardrail AGENTS.md into ~/.config/opencode/AGENTS.md.";
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
        // allCommandFiles
        // allAgentFiles
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
