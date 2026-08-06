{
  config,
  lib,
  inputs,
  ...
}:

# Matt Pocock's agent skills (https://github.com/mattpocock/skills), linked from
# a pinned checkout for harnesses that cannot install plugins. Every skill is a
# directory holding a SKILL.md; upstream groups them in category folders, and
# agents want them flat under a skills directory.
#
# Claude Code does not go through here: it installs the same repo as a
# marketplace plugin (see `claudeDefaults.plugins`), which self-updates. Only
# the Agent Skills-style harnesses, Codex and pi, need this checkout.

let
  cfg = config.theorem.home.agents.mattSkills;

  # skills/<category>/<skill>/SKILL.md -> { <skill> = <path>; }
  skillsIn =
    category:
    let
      dir = "${cfg.src}/skills/${category}";
      entries = lib.attrNames (builtins.readDir dir);
      isSkill = name: builtins.pathExists "${dir}/${name}/SKILL.md";
    in
    lib.genAttrs (lib.filter isSkill entries) (name: "${dir}/${name}");

  skills = lib.foldl' (acc: c: acc // skillsIn c) { } cfg.categories;

  selected = removeAttrs skills cfg.exclude;

  linksFor =
    dir:
    lib.mapAttrs' (
      name: path:
      lib.nameValuePair "${dir}/${name}" {
        source = path;
        recursive = false;
      }
    ) selected;
in
{
  options.theorem.home.agents.mattSkills = {
    enable = lib.mkEnableOption "Matt Pocock's agent skills";

    src = lib.mkOption {
      type = lib.types.path;
      default = inputs.matt-skills;
      defaultText = lib.literalExpression "inputs.matt-skills";
      description = "Checkout of github:mattpocock/skills.";
    };

    categories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "engineering"
        "productivity"
        "misc"
      ];
      description = ''
        Category folders under `skills/` to install. `deprecated` is never
        wanted; `in-progress` and `personal` are opt-in because upstream
        changes them without warning.
      '';
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "setup-matt-pocock-skills" ];
      description = ''
        Skill names to skip. The installer skill is excluded by default: it
        clones the repo and runs the link script, which Nix already does here.
      '';
    };

    targets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ".agents/skills" ];
      description = ''
        Directories, relative to `$HOME`, that get one symlink per skill.
        `.claude/skills` is deliberately absent: Claude Code gets these skills
        from the marketplace, and linking them here too would load them twice.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = selected != { };
        message = "theorem.home.agents.mattSkills: no skills selected; check `categories`/`exclude`.";
      }
    ];

    home.file = lib.mkMerge (map linksFor cfg.targets);
  };
}
