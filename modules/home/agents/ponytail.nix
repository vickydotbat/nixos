{
  config,
  lib,
  inputs,
  ...
}:

# Ponytail (https://github.com/DietrichGebert/ponytail), installed declaratively
# instead of by upstream's plugin installer. Skills are plain directories holding
# a SKILL.md, linked flat into each harness's skills directory the same way
# `mattSkills` does.
#
# This lived in the Codex module until that module became package-only; it is
# harness-agnostic now, so it sits alongside the other skill modules instead.

let
  cfg = config.theorem.home.agents.ponytail;

  # skills/<skill>/SKILL.md -> { <skill> = <path>; }
  skillDir = "${cfg.src}/skills";
  entries = lib.attrNames (builtins.readDir skillDir);
  isSkill = name: builtins.pathExists "${skillDir}/${name}/SKILL.md";
  skills = lib.genAttrs (lib.filter isSkill entries) (name: "${skillDir}/${name}");

  linksFor =
    dir:
    lib.mapAttrs' (
      name: path:
      lib.nameValuePair "${dir}/${name}" {
        source = path;
        recursive = false;
      }
    ) skills;
in
{
  options.theorem.home.agents.ponytail = {
    enable = lib.mkEnableOption "Ponytail agent skills";

    src = lib.mkOption {
      type = lib.types.path;
      default = inputs.ponytail;
      defaultText = lib.literalExpression "inputs.ponytail";
      description = ''
        Checkout of github:DietrichGebert/ponytail. Pinned through
        `flake.lock` so updates are a `nix flake update`, not a `git pull`.
      '';
    };

    level = lib.mkOption {
      type = lib.types.enum [
        "off"
        "lite"
        "full"
        "ultra"
      ];
      default = "full";
      description = ''
        Default Ponytail mode for new sessions. Upstream rejects anything
        outside these four as a *default* — `review` exists but is
        session-only, and an invalid value silently falls back to `full`.
      '';
    };

    pluginTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ".claude/skills" ];
      description = ''
        Directories, relative to `$HOME`, that get a single symlink to the
        whole checkout at `<dir>/ponytail`.

        Claude Code treats any directory under `~/.claude/skills/` that carries
        a `.claude-plugin/plugin.json` as a plugin and loads it as
        `<name>@skills-dir` with no `settings.json` entry — verified against
        claude-code 2.1.222 with an otherwise empty `CLAUDE_CONFIG_DIR`. That
        registers the skills *and* the SessionStart/SubagentStart/
        UserPromptSubmit hooks in one link, which is why hook registration is
        not managed separately here.
      '';
    };

    skillTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ".agents/skills" ];
      description = ''
        Directories, relative to `$HOME`, that get one symlink per skill. The
        plugin mechanism above is Claude Code-specific, so Agent Skills-style
        harnesses still want bare skill directories.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = skills != { };
        message = "theorem.home.agents.ponytail: no skills found under ${skillDir}.";
      }
      {
        assertion = builtins.pathExists "${cfg.src}/.claude-plugin/plugin.json";
        message = ''
          theorem.home.agents.ponytail: no .claude-plugin/plugin.json in ${cfg.src}.
          Without it the checkout links as an inert directory and the hooks never
          register.
        '';
      }
    ];

    # Env var wins over the config file upstream; both are set so a session
    # started outside the Home Manager environment still gets the right mode.
    home.sessionVariables.PONYTAIL_DEFAULT_MODE = cfg.level;

    xdg.configFile."ponytail/config.json".text = builtins.toJSON {
      defaultMode = cfg.level;
    };

    home.file = lib.mkMerge (
      (map linksFor cfg.skillTargets)
      ++ (map (dir: {
        "${dir}/ponytail" = {
          source = cfg.src;
          recursive = false;
        };
      }) cfg.pluginTargets)
    );
  };
}
