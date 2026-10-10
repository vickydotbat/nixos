{
  config,
  lib,
  inputs,
  ...
}:

# Olaf Freund's Nix skills (https://github.com/olafkfreund/nix-skills): the
# Nix language, nixpkgs, Home Manager, devenv, NixOS operations, and a pinned
# NixOS Wiki. Each skill is a directory holding a SKILL.md under `skills/`,
# linked flat into every harness's skills directory the way `ponytail` does.
#
# Upstream is not a Claude Code marketplace, so `.claude/skills` is a target
# here too. The repository's own `docs/nixos-managing` skill stays: it holds
# the impermanence, LUKS, disko, and monitoring rites this kit does not.

let
  cfg = config.theorem.home.agents.nixSkills;

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
  options.theorem.home.agents.nixSkills = {
    enable = lib.mkEnableOption "olafkfreund's Nix agent skills";

    src = lib.mkOption {
      type = lib.types.path;
      default = inputs.nix-skills;
      defaultText = lib.literalExpression "inputs.nix-skills";
      description = ''
        Checkout of github:olafkfreund/nix-skills. Pinned through
        `flake.lock` so updates are a `nix flake update nix-skills`.
      '';
    };

    targets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        ".agents/skills"
        ".claude/skills"
      ];
      description = ''
        Directories, relative to `$HOME`, that get one symlink per skill.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = skills != { };
        message = "theorem.home.agents.nixSkills: no skills found under ${skillDir}.";
      }
    ];

    home.file = lib.mkMerge (map linksFor cfg.targets);
  };
}
