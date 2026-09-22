{
  lib,
  ...
}:

let
  # Skill directories linked into every harness that reads a skills folder.
  skills = {
    human-voice = ../agents/all/skills/human-voice;
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
    claude = {
      enable = true;

      # Start Claude inside the project's devshell when the repo has a
      # flake.nix, so it gets the same tools the project promises.
      useDevShell = true;
    };
    codegraph.enable = true;

    # Builds a markdown context graph of a repo so agents stop re-reading it.
    # Package-only: run `graft init` once per project to build the graph and
    # wire it into Claude Code.
    graft.enable = true;
    herdr.enable = true;
    rtk.enable = true;

    # Refuses a delete git cannot undo: rm -r or a wildcard rm aimed at files
    # that are untracked, or at a folder outside any repo.
    rmGuard.enable = true;

    # Blocks two things CLAUDE.md only asks for in prose, which agents skip:
    # a new branch on top of unmerged work, and any push that lands on main.
    gitGuard.enable = true;

    # The system theorem is tended by one pair of hands and takes every change
    # on main, so there the guard flips: pushing main passes, opening a branch
    # is refused.
    gitGuard.trunkRepos = [ "vickydotbat/nixos" ];

    # Keeps a git-spice stack from replaying work the forge already squashed.
    # At session start it untracks branches whose upstream is gone, asks the
    # forge what merged, and replays the rest — rolling back if the replay
    # conflicts rather than leaving a detached HEAD behind.
    gsAutosync.enable = true;

    # Gives every subagent its own folder under the session's scratch
    # directory and refuses the shared one. Subagents inherit the parent's
    # session id, so without this they all write /tmp/<session>/pr-body.md and
    # quietly overwrite each other.
    scratchGuard.enable = true;

    # Refuses an issue or pull request opened without its comments. A comment
    # often changes what the body says, so the thread is read whole or not at
    # all.
    issueGuard.enable = true;

    # Matt Pocock's skills for Codex and pi only; Claude Code takes them from
    # the marketplace below.
    mattSkills.enable = true;

    # Runs linters and turns each finding into a coaching guide the agent acts
    # on. Nothing happens in a project without a `.habit-hooks/config.toml`;
    # `habit-hooks init` writes one. The doctrine line lives in
    # `agents/all/CLAUDE.md`.
    habitHooks = {
      enable = true;
      languages = [
        "python"
        "typescript"
      ];
    };

    # Always-on output shaping. `level` is the default mode for a new session;
    # it accepts a runtime switch afterwards.
    ponytail.enable = true;

    # Off on purpose: caveman drops articles and filler, which fights the ELI5
    # output style below. Ponytail only shapes what gets built, not how it reads,
    # so it stays.
    caveman.enable = false;

    # Seeds statusLine and permissions.defaultMode into ~/.claude/settings.json
    # once, then leaves the file alone so in-CLI changes stick. Marketplaces
    # and plugins are the exception; those are re-applied on every rebuild.
    claudeDefaults = {
      enable = true;

      # Output style new sessions start in. The matching file is linked into
      # ~/.claude/output-styles below.
      outputStyle = "ELI5";

      # Matt Pocock's skills used to be linked from a pinned checkout. Upstream
      # ships them as a marketplace plugin now, so Claude Code fetches and
      # updates them itself instead of waiting for a `nix flake update`.
      # Policy keys, re-applied on every rebuild so no machine drifts. Taste
      # keys — model, theme, effortLevel, autoCompact — stay mutable on
      # purpose, so changing them in the CLI still sticks.
      settings = {
        # Off: cloud connectors, remote control of this session, and the
        # bundled skill set (the marketplace plugins below cover it).
        disableClaudeAiConnectors = true;
        disableRemoteControl = true;
        disableBundledSkills = true;

        # Off: the Workflows and Artifact features, plus the nag that asks
        # about Workflows once they are gone.
        disableWorkflows = true;
        disableArtifact = true;
        skipWorkflowUsageWarning = true;

        # Claude Code writing to memory files behind your back; CLAUDE.md is
        # a read-only store link now anyway.
        autoMemoryEnabled = false;

        permissions = {
          allow = [ "Bash(codex exec*)" ];

          # Tools that are off for good: plan mode (the ELI5 output style
          # drives the flow instead), notebook edits, and everything that
          # would let a session reach outside it — messages, notifications, remote
          # triggers, wakeups, cron.
          deny = [
            "EnterPlanMode"
            "ExitPlanMode"
            "DesignSync"
            "NotebookEdit"
            "SendMessage"
            "PushNotification"
            "RemoteTrigger"
            "ReportFindings"
            "ScheduleWakeup"
            "AskUserQuestion"
            "CronCreate"
            "CronDelete"
            "CronList"
          ];
        };
      };

      # Marketplaces Claude Code installs from, and what to enable out of them.
      # ponytail still gets linked into `~/.agents/skills` by its own module,
      # for harnesses that do not speak the plugin protocol.
      marketplaces = {
        mattpocock = "mattpocock/skills";
        ponytail = "DietrichGebert/ponytail";
        caveman = "JuliusBrussee/caveman";
      };

      plugins = {
        "mattpocock-skills@mattpocock" = true;
        "ponytail@ponytail" = true;

        # Explicitly off, to match `caveman.enable = false` above: the plugin
        # would bring the SessionStart hook back on its own. The marketplace
        # entry stays so turning it on is a one-word change.
        "caveman@caveman" = false;
      };
    };
  };

  home.file = lib.mkMerge (
    (map linksFor skillTargets)
    ++ [
      {
        # Output style selected by claudeDefaults.outputStyle above. Claude Code
        # reads styles from this directory by their `name:` front-matter field.
        ".claude/output-styles/ELI5.md".source = ../agents/all/output-styles/ELI5.md;

        # Global agent doctrine, identical on every machine. `force` because
        # hosts configured before this line have a hand-written copy in place.
        #
        # The link points into the Nix store, so it is read-only: Claude Code's
        # `#` memory shortcut cannot append to it. Edit the file in this repo
        # and rebuild instead. `autoMemoryEnabled` is off in settings.json, so
        # nothing else writes here either.
        ".claude/CLAUDE.md" = {
          source = ../agents/all/CLAUDE.md;
          force = true;
        };

        # Codex and Pi read their own doctrine files, written in their own
        # voice and referring to their own subagents and skills, so they are
        # not copies of CLAUDE.md above. Each one is the live file as of this
        # commit, moved into the repo so every machine gets the same text.
        ".codex/AGENTS.md" = {
          source = ../agents/codex/AGENTS.md;
          force = true;
        };

        ".pi/agent/AGENTS.md" = {
          source = ../agents/pi/agent/AGENTS.md;
          force = true;
        };

        # Appended to Pi's system prompt; the NixOS half of the rules above.
        ".pi/agent/APPEND_SYSTEM.md" = {
          source = ../agents/pi/agent/APPEND_SYSTEM.md;
          force = true;
        };
      }
    ]
  );
}
