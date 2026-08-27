{
  config,
  lib,
  pkgs,
  ...
}:

# Habit Hooks (https://github.com/habit-hooks/habit-hooks), packaged in
# `pkgs/habit-hooks.nix` instead of installed with `uv tool install`, so the
# core, its plugins and the version they agree on are all pinned by this repo.
#
# It runs linters, then replaces each raw rule violation with a short coaching
# guide the agent can act on. There is no hook to register despite the name:
# it is four commands on PATH (`habit-hooks`, `habit-sensors`, `habit-mapper`,
# `habit-snooze`) plus a line in the agent's doctrine telling it to run them.
#
# Upstream has no user-level config file. Everything it reads lives in the
# project it scans, in `.habit-hooks/config.toml`, so this module configures
# what gets installed — plugins and detectors — and nothing about a run.

let
  cfg = config.theorem.home.agents.habitHooks;

  # A plugin spawns its detectors as real programs, so they have to be findable.
  # `habit-sensors` prepends `node_modules/.bin` and `.venv/bin` to PATH, which
  # covers a project that installs its own; these are the fallbacks for one that
  # does not. jscpd, the generic plugin's duplication detector, is not in
  # nixpkgs — a project wanting it needs `jscpd` in its own devDependencies.
  detectorsFor = {
    python = [
      pkgs.ruff
      pkgs.deptry
    ];
    typescript = [ pkgs.nodejs ]; # eslint, knip and ts-morph stay project-local
    php = [ pkgs.php ];
    java = [ pkgs.pmd ];
  };
in
{
  options.theorem.home.agents.habitHooks = {
    enable = lib.mkEnableOption "Habit Hooks structural code-smell coaching";

    languages = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "python"
          "typescript"
          "php"
          "java"
        ]
      );
      default = [
        "python"
        "typescript"
      ];
      description = ''
        Language plugins built into the package, upstream's `[python,typescript]`
        install extras. The languageless `generic` plugin is always included; it
        holds most of the guides.

        A plugin still has to be named in a project's
        `.habit-hooks/config.toml` before it runs. Installing it only makes the
        name resolvable.
      '';
    };

    detectors = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install the detector programs the selected plugins spawn — `ruff` and
        `deptry` for python, `node` for typescript, `php`, `pmd` for java.

        Turn this off on a machine where every project brings its own; the
        project's `node_modules/.bin` and `.venv/bin` are searched first either
        way, so a project-local version always wins.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.habit-hooks.override { inherit (cfg) languages; };
      defaultText = lib.literalExpression "pkgs.habit-hooks.override { inherit languages; }";
      description = "The habit-hooks package to install.";
    };

    skillTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        ".claude/skills"
        ".agents/skills"
      ];
      description = ''
        Directories, relative to `$HOME`, that get the `habit-hooks-review`
        skill: the reviewer sub-agent to run once habit-hooks reports clean.

        Only that one skill is linked. The other two upstream ships,
        `habit-hooks-prompting` and `release-habit-hooks`, are for maintaining
        habit-hooks itself, not for using it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
    ]
    ++ lib.optionals cfg.detectors (lib.concatMap (lang: detectorsFor.${lang}) cfg.languages);

    home.file = lib.listToAttrs (
      map (dir: {
        name = "${dir}/habit-hooks-review";
        value = {
          source = "${cfg.package.skills}/habit-hooks-review";
          recursive = false;
        };
      }) cfg.skillTargets
    );
  };
}
