{
  inputs,
  lib,
  ...
}:

let
  # Skill directories linked into every harness that reads a skills folder.
  # `human-voice` is written here; `i-have-adhd` comes from a pinned checkout
  # of https://github.com/ayghri/i-have-adhd.
  skills = {
    human-voice = ../agents/all/skills/human-voice;
    i-have-adhd = "${inputs.i-have-adhd}/skills/i-have-adhd";
  };

  skillTargets = [
    ".claude/skills"
    ".agents/skills"
  ];

  linksFor =
    dir: lib.mapAttrs' (name: path: lib.nameValuePair "${dir}/${name}" { source = path; }) skills;
in
{
  theorem.home.agents = {
    ollama = {
      enable = true;
      acceleration = "rocm";
      host = "0.0.0.0";
    };

    # ComfyUI runs as an on-demand rootless Podman container; start it with
    # `comfyui`, browse to http://127.0.0.1:8188. First run pulls the image.
    comfyui.enable = false;

    # Odysseus container image was pruned; keep it off explicitly.
    odysseus.enable = false;

    # opencode.enable = true;
    pi.enable = true;
    omp.enable = false;
    codex.enable = true;
    claude.enable = true;
    codegraph.enable = true;
    herdr.enable = true;
    rtk.enable = true;

    # Blocks destructive shell commands (rm -rf /, git reset --hard, ...)
    # before Claude Code runs them, via a PreToolUse hook.
    dcg.enable = true;

    # Always-on output shaping, same tier as the ADHD kit above. `level` is the
    # default mode for a new session; both accept a runtime switch afterwards.
    ponytail.enable = true;
    caveman.enable = true;

    # Seeds statusLine and permissions.defaultMode into ~/.claude/settings.json
    # once, then leaves the file alone so in-CLI changes stick. Marketplaces
    # and plugins are the exception; those are re-applied on every rebuild.
    claudeDefaults = {
      enable = true;

      # Matt Pocock's skills used to be linked from a pinned checkout. Upstream
      # ships them as a marketplace plugin now, so Claude Code fetches and
      # updates them itself instead of waiting for a `nix flake update`.
      # Marketplaces Claude Code installs from, and what to enable out of them.
      # ponytail and caveman still get linked into `~/.agents/skills` by their
      # own modules, for harnesses that do not speak the plugin protocol.
      marketplaces = {
        mattpocock = "mattpocock/skills";
        ponytail = "DietrichGebert/ponytail";
        caveman = "JuliusBrussee/caveman";
      };

      plugins = {
        "mattpocock-skills@mattpocock" = true;
        "ponytail@ponytail" = true;
        "caveman@caveman" = true;
      };
    };
  };

  home.file = lib.mkMerge (
    (map linksFor skillTargets)
    ++ [
      {
        # Upstream SessionStart hook for the ADHD kit. It looks for SKILL.md at
        # `../skills/i-have-adhd/SKILL.md` relative to its own path, which from
        # `~/.claude/hooks/` resolves to the skill linked above. Register it in
        # `~/.claude/settings.json` under `hooks.SessionStart`; that file stays
        # mutable because Claude Code writes to it.
        ".claude/hooks/adhd-always-on.sh".source = "${inputs.i-have-adhd}/hooks/always-on.sh";

        # The hook only fires when this flag file exists. Declaring it here is
        # what makes ADHD mode always-on in every session.
        ".claude/.i-have-adhd-always".text = "";
      }
    ]
  );
}
