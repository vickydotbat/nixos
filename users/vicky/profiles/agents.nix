{
  config,
  repository,
  lib,
  ...
}:
let
  home = config.home.homeDirectory;
  trustedProjects = [
    "${home}/Obsidian/Echo-Reliquary"
    "${home}/Projects/westgate/repositories"
    "${home}/Projects/westgate/repositories/migration"
    "${home}/Projects/westgate/repositories/migration/sow-assets-manifest"
    "${home}/Projects/westgate/repositories/migration/sow-codebase"
    "${home}/Projects/westgate/repositories/migration/sow-depot"
    "${home}/Projects/westgate/repositories/migration/sow-depot-proxy"
    "${home}/Projects/westgate/repositories/migration/sow-docs"
    "${home}/Projects/westgate/repositories/migration/sow-module"
    "${home}/Projects/westgate/repositories/migration/sow-nodebb"
    "${home}/Projects/westgate/repositories/migration/sow-nodebb-plugin-wiki"
    "${home}/Projects/westgate/repositories/migration/sow-nodebb-plugin-support"
    "${home}/Projects/westgate/repositories/migration/sow-mcp-server"
    "${home}/Projects/westgate/repositories/migration/sow-nodebb-theme"
    "${home}/Projects/westgate/repositories/migration/sow-platform"
    "${home}/Projects/westgate/repositories/migration/sow-tools"
    "${home}/Projects/westgate/repositories/migration/sow-topdata"
  ];
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

      environmentFile = "/run/user/1000/secrets/headroom-env";

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
    };

    skills = {
      enable = true;

      guardrails = {
        enable = true;
        source = ../../../assets/agent-guardrails;

        # These are OpenCode-shaped skills, so I would keep these false by default.
        codex = false;
        claude = false;

        shared = true;
        commands = true;
        agentsMd = true;
      };
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

    codex = {
      enable = true;
    };

    claude = {
      enable = true;
    };
  };
}
