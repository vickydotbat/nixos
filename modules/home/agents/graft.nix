# graft, a context graph of a repository written as linked markdown files, in
# the theorem.home.agents namespace.
#
# Package-only, like codegraph and rtk. `graft init` edits agent config files
# (`~/.claude`, Codex, Cursor) and writes a `graft/` folder inside the repo, so
# it stays a per-project command you run yourself. `graft init` also sets
# `statusLine` in `~/.claude/settings.json`; claudeDefaults seeds that key once
# and then leaves the file alone, so the two do not fight.
#
# Nix owns the version: bump `pkgs/graft.nix` instead of running
# `graft upgrade`, which would install a second copy over npm.
#
# `~/.graft` only holds a telemetry id and an update-check cache, so nothing
# here is persisted.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.agents.graft;
in
{
  options.theorem.home.agents.graft = {
    enable = lib.mkEnableOption "graft codebase context graph CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.graft;
      defaultText = lib.literalExpression "pkgs.graft";
      description = "The graft package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # The Claude Code hooks `graft init` writes run as `node <shim>.cjs`, not
    # through graft's own wrapper, so they need this to find the install. The
    # package patches upstream's habit of baking an absolute path into the shim,
    # which would put a /nix/store path in a file meant to be committed.
    home.sessionVariables.GRAFT_DIST =
      "${cfg.package}/lib/node_modules/@nanonets/graft/dist/claude";
  };
}
