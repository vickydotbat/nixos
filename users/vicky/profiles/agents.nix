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
    dir:
    lib.mapAttrs' (name: path: lib.nameValuePair "${dir}/${name}" { source = path; }) skills;
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
    mattSkills.enable = true;
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
