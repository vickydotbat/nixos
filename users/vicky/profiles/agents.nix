{
  config,
  inputs,
  lib,
  options,
  ...
}:
let
  accountSecretsFile = ../../../secrets/users-vicky.yaml;
  hasHeadroomEnvSecret =
    builtins.pathExists accountSecretsFile
    && lib.hasInfix "headroom-env:" (builtins.readFile accountSecretsFile);
  hasHomePersistence = options.home ? persistence;
  persistenceEnabled = config.theorem.home.base.persistence.enable;
  homeDir = config.home.homeDirectory;

  skills = {
    persist = persistenceEnabled;

    targets = {
      codex = config.theorem.home.agents.codex.enable or false;
      opencode = config.theorem.home.agents.opencode.enable or false;
      claude = config.theorem.home.agents.claude.enable or false;
    };

    local = {
      enable = true;
      source = ../agents;

      # `all` is the harness-neutral kit. Harness directories below this source
      # are installed only into the tool that owns that configuration surface.
      globalSkills = true;
      globalCommands = true;
      codex = true;
      opencode = true;
      claude = true;
    };

    superpowers = {
      enable = true;
      source = inputs.superpowers + "/skills";
    };

    ponytail = {
      enable = true;
      source = inputs.ponytail + "/skills";
      level = "full";
    };

    pi = {
      enable = config.theorem.home.agents.pi.enable or false;
      source = ../agents/pi;

      agentInstructions = true;
      extensions = true;
      skills = true;
    };
  };

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

  superpowersShared = lib.optionalAttrs skills.superpowers.enable (
    mkSkillLinks ".agents/skills" skills.superpowers.source
  );

  ponytailShared = lib.optionalAttrs skills.ponytail.enable (
    mkSkillLinks ".agents/skills" skills.ponytail.source
  );

  superpowersCodex = lib.optionalAttrs (skills.superpowers.enable && skills.targets.codex) (
    mkSkillLinks ".codex/skills" skills.superpowers.source
  );

  ponytailCodex = lib.optionalAttrs (skills.ponytail.enable && skills.targets.codex) (
    mkSkillLinks ".codex/skills" skills.ponytail.source
  );

  superpowersOpenCode = lib.optionalAttrs (skills.superpowers.enable && skills.targets.opencode) (
    mkSkillLinks ".config/opencode/skills" skills.superpowers.source
  );

  ponytailOpenCode = lib.optionalAttrs (skills.ponytail.enable && skills.targets.opencode) (
    mkSkillLinks ".config/opencode/skills" skills.ponytail.source
  );

  superpowersClaude = lib.optionalAttrs (skills.superpowers.enable && skills.targets.claude) (
    mkSkillLinks ".claude/skills" skills.superpowers.source
  );

  ponytailClaude = lib.optionalAttrs (skills.ponytail.enable && skills.targets.claude) (
    mkSkillLinks ".claude/skills" skills.ponytail.source
  );

  localGlobalSkills = lib.optionalAttrs (skills.local.enable && skills.local.globalSkills) (
    mkSkillLinks ".agents/skills" (skills.local.source + "/all/skills")
  );

  localGlobalCommands = lib.optionalAttrs (skills.local.enable && skills.local.globalCommands) (
    mkLinksIfExists ".agents/commands" (skills.local.source + "/all/commands")
  );

  localCodexConfig = lib.optionalAttrs (
    skills.local.enable && skills.targets.codex && skills.local.codex
  ) (mkLinksIfExists ".codex" (skills.local.source + "/codex"));

  localOpenCodeConfig = lib.optionalAttrs (
    skills.local.enable && skills.targets.opencode && skills.local.opencode
  ) (mkLinksIfExists ".config/opencode" (skills.local.source + "/opencode"));

  localClaudeConfig = lib.optionalAttrs (
    skills.local.enable && skills.targets.claude && skills.local.claude
  ) (mkLinksIfExists ".claude" (skills.local.source + "/claude"));

  allSkillFiles =
    superpowersShared
    // ponytailShared
    // superpowersCodex
    // ponytailCodex
    // superpowersOpenCode
    // ponytailOpenCode
    // superpowersClaude
    // ponytailClaude
    // localGlobalSkills
    // localGlobalCommands
    // localCodexConfig
    // localOpenCodeConfig
    // localClaudeConfig;

  mkSeedRulesIfExists =
    targetPrefix: source:
    lib.optionals (source != null && builtins.pathExists source) (
      lib.mapAttrsToList (
        name: type:
        "C ${homeDir}/${targetPrefix}/${name} ${
          if type == "directory" then "0700" else "0600"
        } - - - ${source + "/${name}"}"
      ) (builtins.readDir source)
    );

  localSeedDirectories = lib.optionals skills.local.enable (
    [
      "d ${homeDir}/.agents 0700 - - -"
      "d ${homeDir}/.agents/skills 0700 - - -"
      "d ${homeDir}/.agents/commands 0700 - - -"
    ]
    ++ lib.optionals (skills.targets.codex && skills.local.codex) [
      "d ${homeDir}/.codex 0700 - - -"
      "d ${homeDir}/.codex/skills 0700 - - -"
    ]
    ++ lib.optionals (skills.targets.opencode && skills.local.opencode) [
      "d ${homeDir}/.config 0700 - - -"
      "d ${homeDir}/.config/opencode 0700 - - -"
      "d ${homeDir}/.config/opencode/agents 0700 - - -"
      "d ${homeDir}/.config/opencode/commands 0700 - - -"
      "d ${homeDir}/.config/opencode/skills 0700 - - -"
    ]
    ++ lib.optionals (skills.targets.claude && skills.local.claude) [
      "d ${homeDir}/.claude 0700 - - -"
      "d ${homeDir}/.claude/skills 0700 - - -"
    ]
  );

  piSeedDirectories = lib.optionals skills.pi.enable ([
    "d ${homeDir}/.agents 0700 - - -"
    "d ${homeDir}/.agents/skills 0700 - - -"
    "d ${homeDir}/.pi 0700 - - -"
    "d ${homeDir}/.pi/agent 0700 - - -"
    "d ${homeDir}/.pi/agent/extensions 0700 - - -"
  ]);

  piAgentInstructionSeedRules = lib.optionals (skills.pi.enable && skills.pi.agentInstructions) (
    mkSeedRulesIfExists ".pi/agent" (skills.pi.source + "/agent")
  );

  piExtensionSeedRules = lib.optionals (skills.pi.enable && skills.pi.extensions) (
    mkSeedRulesIfExists ".pi/agent/extensions" (skills.pi.source + "/extensions")
  );

  piSkillSeedRules = lib.optionals (skills.pi.enable && skills.pi.skills) (
    mkSeedRulesIfExists ".agents/skills" (skills.pi.source + "/skills")
  );

  allSeedRules =
    localSeedDirectories
    ++ piSeedDirectories
    ++ piAgentInstructionSeedRules
    ++ piExtensionSeedRules
    ++ piSkillSeedRules;

  opencodeCloudProvider = "ollama-cloud";
  opencodeCloudModelIds = [
    # GLM
    "glm-5.2:cloud"
    "glm-5.1:cloud"
    "glm-4.7:cloud"
    # Qwen
    "qwen3-coder:480b-cloud"
    # Kimi
    "kimi-k2.7-code:cloud"
    "kimi-k2.6:cloud"
    # GPT-OSS
    "gpt-oss:120b-cloud"
    "gpt-oss:20b-cloud"
    # Deepseek
    "deepseek-v4-pro:cloud"
    "deepseek-v4-flash:cloud"
    # Minimax
    "minimax-m3:cloud"
    # Gemini / Gemma
    "gemini-3-flash-preview:cloud"
    "gemma4:cloud"
    # Nemotron
    "nemotron-3-super:cloud"
    # Mistral
    "mistral-large-3:675b-cloud"
  ];

  opencodeCloudModels = {
    "glm-5.2:cloud" = {
      name = "GLM 5.2 Cloud";
      limit = {
        context = 65536;
        input = 49152;
        output = 8192;
      };
    };

    "glm-5.1:cloud" = {
      name = "GLM 5.1 Cloud";
      limit = {
        context = 65536;
        input = 49152;
        output = 8192;
      };
    };

    "glm-4.7:cloud" = {
      name = "GLM 4.7 Cloud";
      limit = {
        context = 65536;
        input = 49152;
        output = 8192;
      };
    };

    "qwen3-coder:480b-cloud" = {
      name = "Qwen3 Coder 480B Cloud";
      limit = {
        context = 131072;
        input = 98304;
        output = 16384;
      };
    };

    "kimi-k2.7-code:cloud" = {
      name = "Kimi K2.7 Code Cloud";
      limit = {
        context = 131072;
        input = 98304;
        output = 16384;
      };
    };

    "kimi-k2.6:cloud" = {
      name = "Kimi K2.6 Cloud";
      limit = {
        context = 131072;
        input = 98304;
        output = 16384;
      };
    };

    "gpt-oss:120b-cloud" = {
      name = "GPT OSS 120B Cloud";
      limit = {
        context = 65536;
        input = 49152;
        output = 8192;
      };
    };

    "gpt-oss:20b-cloud" = {
      name = "GPT OSS 20B Cloud";
      limit = {
        context = 32768;
        input = 24576;
        output = 4096;
      };
    };

    "deepseek-v4-pro:cloud" = {
      name = "DeepSeek V4 Pro Cloud";
      limit = {
        context = 65536;
        input = 49152;
        output = 8192;
      };
    };

    "deepseek-v4-flash:cloud" = {
      name = "DeepSeek V4 Flash Cloud";
      limit = {
        context = 65536;
        input = 49152;
        output = 8192;
      };
    };

    "minimax-m3:cloud" = {
      name = "MiniMax M3 Cloud";
      limit = {
        context = 65536;
        input = 49152;
        output = 8192;
      };
    };

    "gemini-3-flash-preview:cloud" = {
      name = "Gemini 3 Flash Preview Cloud";
      limit = {
        context = 65536;
        input = 49152;
        output = 8192;
      };
    };

    "gemma4:cloud" = {
      name = "Gemma 4 Cloud";
      limit = {
        context = 32768;
        input = 24576;
        output = 4096;
      };
    };

    "nemotron-3-super:cloud" = {
      name = "Nemotron 3 Super Cloud";
      limit = {
        context = 65536;
        input = 49152;
        output = 8192;
      };
    };

    "mistral-large-3:675b-cloud" = {
      name = "Mistral Large 3 675B Cloud";
      limit = {
        context = 65536;
        input = 49152;
        output = 8192;
      };
    };
  };
  opencodeSafeAgents = {
    build = {
      model = "${opencodeCloudProvider}/qwen3-coder:480b-cloud";
      temperature = 0.1;
      steps = 12;
    };

    plan = {
      model = "${opencodeCloudProvider}/kimi-k2.7-code:cloud";
      temperature = 0.1;
      steps = 8;
      permission = {
        edit = "deny";
        task = "ask";
        bash = {
          "git status*" = "allow";
          "git diff*" = "allow";
          "rg *" = "allow";
          "sed -n *" = "allow";
          "git commit*" = "deny";
          "git push*" = "deny";
          "git reset --hard*" = "deny";
          "git clean*" = "deny";
          "rm -rf *" = "deny";
          "* secrets/*" = "deny";
          "* /run/secrets/*" = "deny";
          "* /run/agenix/*" = "deny";
        };
      };
    };

    reviewer = {
      mode = "subagent";
      model = "${opencodeCloudProvider}/kimi-k2.7-code:cloud";
      temperature = 0.0;
      steps = 6;
      permission = {
        edit = "deny";
        task = "deny";
        todowrite = "deny";
        bash = {
          "git status*" = "allow";
          "git diff*" = "allow";
          "git show*" = "allow";
          "rg *" = "allow";
          "sed -n *" = "allow";
          "nixfmt --check *" = "allow";
          "git commit*" = "deny";
          "git push*" = "deny";
          "git reset --hard*" = "deny";
          "git clean*" = "deny";
          "rm -rf *" = "deny";
          "* secrets/*" = "deny";
          "* /run/secrets/*" = "deny";
          "* /run/agenix/*" = "deny";
        };
      };
    };

    glm-worker = {
      mode = "subagent";
      model = "${opencodeCloudProvider}/glm-5.2:cloud";
      temperature = 0.1;
      steps = 4;
      description = "Bounded GLM worker for exactly one narrow implementation task.";
      prompt = ''
        Implement exactly one named task and then stop.

        Do not dispatch subagents. Do not commit. Do not push. Do not
        run broad cleanup. Do not read secrets, credentials, auth files,
        tokens, `.sops`, `/run/secrets`, `/run/agenix`, or SSH material.

        Stay inside the named files or the smallest necessary local
        context. After at most four tool steps, summarize what changed,
        what was not verified, and stop. If tests fail, report the
        failure and stop instead of continuing.
      '';
      permission = {
        edit = "ask";
        task = "deny";
        todowrite = "deny";
        webfetch = "deny";
        websearch = "deny";
        external_directory = "deny";
        bash = {
          "git status*" = "allow";
          "git diff*" = "allow";
          "rg *" = "allow";
          "sed -n *" = "allow";
          "nixfmt --check *" = "allow";
          "git commit*" = "deny";
          "git push*" = "deny";
          "git reset --hard*" = "deny";
          "git clean*" = "deny";
          "rm -rf *" = "deny";
          "rm -fr *" = "deny";
          "mv *" = "deny";
          "chmod *" = "deny";
          "chown *" = "deny";
          "* .sops/*" = "deny";
          "* .sops/**" = "deny";
          "* *.sops.*" = "deny";
          "* secrets/*" = "deny";
          "* /run/secrets/*" = "deny";
          "* /run/agenix/*" = "deny";
          "* ~/.ssh/*" = "deny";
          "* ~/.config/opencode/auth*" = "deny";
        };
      };
    };
  };
in
lib.mkMerge [
  {
    theorem.home.agents = {
      ollama = {
        enable = true;
        acceleration = "rocm";
        host = "0.0.0.0";
      };
      odysseus = {
        enable = true;
      };

      headroom = {
        enable = true;

        host = "127.0.0.1";
        port = 8787;
        mode = "token";

        opencode = {
          enable = true;

          # Built-in OpenCode / Models.dev provider ID.
          providerId = "ollama-cloud";

          # Only these appear in OpenCode's model picker.
          ollamaCloudModelIds = opencodeCloudModelIds;

          defaultModel = "qwen3-coder:480b-cloud";
          smallModel = "gpt-oss:20b-cloud";

          ollamaCloudModels = opencodeCloudModels;
          agents = opencodeSafeAgents;
        };
      }
      // lib.optionalAttrs hasHeadroomEnvSecret {
        environmentFile = "/run/secrets/headroom-vicky-env";
      };

      opencode = {
        enable = true;
        safeConfig = {
          enable = true;
          providerId = opencodeCloudProvider;
          modelIds = opencodeCloudModelIds;
          defaultModel = "qwen3-coder:480b-cloud";
          smallModel = "gpt-oss:20b-cloud";
          models = opencodeCloudModels;
          agents = opencodeSafeAgents;
        };
      };

      pi = {
        enable = true;
        seedConfig = true;

        ollama = {
          enable = true;
          defaultModel = "qwen3-coder:480b-cloud";
          models = opencodeCloudModelIds;
        };
      };

      codex = {
        enable = true;
      };

      claude = {
        enable = true;
      };
    };

    home.file =
      allSkillFiles
      // lib.optionalAttrs skills.ponytail.enable {
        ".config/ponytail/config.json".text = builtins.toJSON {
          defaultMode = skills.ponytail.level;
        };
      };

    systemd.user.tmpfiles.rules = allSeedRules;

    home.sessionVariables = lib.mkIf skills.ponytail.enable {
      PONYTAIL_DEFAULT_MODE = skills.ponytail.level;
    };
  }

  (lib.optionalAttrs hasHomePersistence {
    home.persistence."/nix/persist" = lib.mkIf skills.persist {
      directories = [
        ".agents"
      ]
      ++ lib.optional skills.ponytail.enable ".config/ponytail";
    };
  })
]
