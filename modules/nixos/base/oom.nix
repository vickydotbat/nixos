{
  config,
  lib,
  ...
}:

# Keeps a runaway user process from taking the desktop down with it.
#
# On 2026-08-05 saturnine stuttered its way through swap and then hit a global
# OOM: a Claude Code process had reached 9.9 GB anon RSS with nothing to stop
# it, and the kernel killed it only after the machine was already unusable.
# `constraint=CONSTRAINT_NONE` in that log means exactly this — no cgroup limit
# applied anywhere, so the first ceiling hit was physical RAM.
#
# Two layers, neither game- nor host-specific:
#
#   MemoryHigh on app.slice throttles into reclaim well before that point. It
#   is a soft limit: over it the process is slowed, not killed, which turns a
#   freeze into something noticeably slow but survivable.
#
#   systemd-oomd on the user slices acts on PSI pressure rather than waiting
#   for allocation failure, so it kills the offender early instead of letting
#   the kernel pick a victim late.
#
# A third layer closes a hole the first two left. Rootless Podman puts every
# container and pod under the user manager's `user.slice`, beside `app.slice`
# and outside both rules. On 2026-10-04 a local game server there looped to
# 17 GB, swapped, and froze solanine into a reboot. `user.slice` now has a hard
# MemoryMax and no swap, so a runaway container dies at its own ceiling and the
# desktop never notices.
#
# A percentage, not a byte count, so the same value is sane on machines with
# different amounts of RAM.

let
  cfg = config.theorem.nixos.base.oom;
in
{
  options.theorem.nixos.base.oom = {
    enable = lib.mkEnableOption "memory pressure limits for user applications";

    appMemoryHigh = lib.mkOption {
      type = lib.types.str;
      default = "70%";
      description = ''
        Soft memory ceiling for `app.slice`, where desktop applications run.
        Crossing it forces reclaim and slows the slice; it never kills.

        This is the whole slice, not one process: a browser and an editor
        together can reach it without either misbehaving. Too low costs
        throughput on a busy desktop, too high stops preventing the freeze it
        exists to prevent.
      '';
    };

    containerMemoryMax = lib.mkOption {
      type = lib.types.str;
      default = "60%";
      description = ''
        Hard memory ceiling for the user manager's `user.slice`, where rootless
        Podman runs every container and pod. Over it the kernel kills inside
        the slice; nothing outside it is touched. Swap is denied to the slice,
        so a runaway reaches the ceiling quickly instead of thrashing toward it.

        Every container shares it. Raise it when a model or a build legitimately
        needs more, never to get a stuck container moving again.
      '';
    };

    pressureLimit = lib.mkOption {
      type = lib.types.str;
      default = "60%";
      description = ''
        Memory pressure above which systemd-oomd starts killing inside
        `app.slice`, sustained for `pressureDuration`.
      '';
    };

    pressureDuration = lib.mkOption {
      type = lib.types.str;
      default = "20s";
      description = ''
        How long pressure must stay above the limit before oomd acts. Short
        enough to beat a freeze, long enough that a compile or a game load
        does not trip it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.oomd = {
      enable = true;
      # The user slices are where this actually matters. The system slice is
      # left alone: killing a service to save a desktop app is the wrong trade.
      enableUserSlices = true;
    };

    systemd.user.slices.app.sliceConfig = {
      MemoryHigh = cfg.appMemoryHigh;
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = cfg.pressureLimit;
    };

    systemd.user.slices.user.sliceConfig = {
      MemoryHigh = "50%";
      MemoryMax = cfg.containerMemoryMax;
      MemorySwapMax = "0";
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = cfg.pressureLimit;
    };

    systemd.oomd.settings.OOM = {
      DefaultMemoryPressureDurationSec = cfg.pressureDuration;
    };
  };
}
