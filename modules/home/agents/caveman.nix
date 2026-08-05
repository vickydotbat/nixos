{
  config,
  lib,
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

    targets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        ".claude/skills"
        ".agents/skills"
      ];
      description = ''
        Directories, relative to `$HOME`, that get one symlink per skill.
        Defaults cover Claude Code and Agent Skills-compatible harnesses.
      '';
    };

    installHooks = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Link Caveman's hook scripts into `~/.claude/hooks/caveman`. The hooks
        `require()` each other by relative path, so the whole directory is
        linked rather than individual files. Registering them still means
        editing `~/.claude/settings.json`, which stays mutable because Claude
        Code writes to it; see `.claude-plugin/plugin.json` in the checkout for
        the stanza to paste.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = skills != { };
        message = "theorem.home.agents.caveman: no skills found under ${skillDir}.";
      }
    ];

    home.sessionVariables.CAVEMAN_DEFAULT_MODE = cfg.level;

    xdg.configFile."caveman/config.json".text = builtins.toJSON {
      defaultMode = cfg.level;
    };

    home.file = lib.mkMerge (
      (map linksFor cfg.targets)
      ++ lib.optional cfg.installHooks {
        ".claude/hooks/caveman".source = "${cfg.src}/src/hooks";
      }
    );
  };
}
