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
        ollamaCloudModelIds = [
          "glm-5.2:cloud"
          "glm-4.7:cloud"
          "qwen3-coder:480b-cloud"
          "kimi-k2.7-code:cloud"
          "gpt-oss:120b-cloud"
          "gpt-oss:20b-cloud"
        ];

        defaultModel = "glm-5.2:cloud";
        smallModel = "gpt-oss:20b-cloud";
      };
    };

    skills = {
      enable = true;

      guardrails = {
        enable = true;
        source = ./assets/agent-guardrails;

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
    };

    codex = {
      enable = true;
    };

    claude = {
      enable = true;
    };
  };
}
