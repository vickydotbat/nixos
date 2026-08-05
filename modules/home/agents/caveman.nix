{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# Caveman (https://github.com/JuliusBrussee/caveman), installed declaratively
# instead of by upstream's `install.sh`. Same shape as the Ponytail module next
# door: skills linked flat per harness, default mode set by env var and config
# file.

let
  cfg = config.theorem.home.agents.caveman;

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
  options.theorem.home.agents.caveman = {
    enable = lib.mkEnableOption "Caveman agent skills";

    src = lib.mkOption {
      type = lib.types.path;
      default = inputs.caveman;
      defaultText = lib.literalExpression "inputs.caveman";
      description = ''
        Checkout of github:JuliusBrussee/caveman. Pinned through `flake.lock`
        so updates are a `nix flake update`, not a `git pull`.
      '';
    };

    level = lib.mkOption {
      type = lib.types.enum [
        "off"
        "lite"
        "full"
        "ultra"
        "wenyan-lite"
        "wenyan"
        "wenyan-full"
        "wenyan-ultra"
      ];
      default = "full";
      description = ''
        Default Caveman compression mode for new sessions. The `wenyan-*`
        levels render replies in classical Chinese; they compress hardest and
        are the one case where Caveman does not keep your language. Upstream
        also accepts `commit`, `review`, and `compress`, but those are
        per-invocation modes rather than defaults, so they are not offered here.
      '';
    };

    pluginTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ".claude/skills" ];
      description = ''
        Directories, relative to `$HOME`, that get a single symlink to the
        whole checkout at `<dir>/caveman`. See the matching option on
        `ponytail` for why this registers the hooks too.

        Note that the checkout carries a second copy of four skills under
        `plugins/caveman/skills/`, so Claude Code lists 12 skills where only 6
        are distinct. The nested copy has no manifest of its own, so linking
        the root is the only option; the duplication is upstream's.
      '';
    };

    skillTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ".agents/skills" ];
      description = ''
        Directories, relative to `$HOME`, that get one symlink per skill, taken
        from the top-level `skills/` tree only.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = skills != { };
        message = "theorem.home.agents.caveman: no skills found under ${skillDir}.";
      }
      {
        assertion = builtins.pathExists "${cfg.src}/.claude-plugin/plugin.json";
        message = ''
          theorem.home.agents.caveman: no .claude-plugin/plugin.json in ${cfg.src}.
          Without it the checkout links as an inert directory and the hooks never
          register.
        '';
      }
    ];

    # Same Node dependency as the ponytail module next door; listing it in both
    # keeps either one working when the other is disabled. Identical derivation,
    # so home.packages dedupes it.
    home.packages = [ pkgs.nodejs ];

    home.sessionVariables.CAVEMAN_DEFAULT_MODE = cfg.level;

    xdg.configFile."caveman/config.json".text = builtins.toJSON {
      defaultMode = cfg.level;
    };

    home.file = lib.mkMerge (
      (map linksFor cfg.skillTargets)
      ++ (map (dir: {
        "${dir}/caveman" = {
          source = cfg.src;
          recursive = false;
        };
      }) cfg.pluginTargets)
    );
  };
}
