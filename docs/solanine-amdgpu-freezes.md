# Solanine AMDGPU Display Freezes

This note records Solanine's recurring Plasma Wayland display freeze. The
failure is not subtle: the screen stops updating, Plasma may play a device
disconnect sound, and power-cycling the monitor or replugging the display cable
can wake the session back into usefulness. Treat this as a display-link and
AMDGPU Display Core problem until new evidence says otherwise.

## Host Shape

- Host: `solanine`
- Desktop: Plasma Wayland
- Board: ASUS PRIME B650M-A WIFI II
- Discrete GPU in the failing trace: `0000:03:00.0`
- Integrated GPU also present: `0000:0e:00.0`
- Current kernel observed during the June 4 traces: `7.0.10`
- Current host-scoped boot parameters:
  - `amdgpu.sg_display=0`
  - `amdgpu.dcdebugmask=0x52`
  - `amdgpu.runpm=0`

`amdgpu.sg_display=0` keeps the integrated display block out of the display
theorem. `amdgpu.runpm=0` keeps the discrete GPU out of runtime power-down
while this is being diagnosed. `amdgpu.dcdebugmask=0x52` is the current trial:
it disables stutter (`0x2`), PSR (`0x10`), and multi-plane offloading (`0x40`).

## Symptoms

- Plasma Wayland freezes while the machine remains recoverable.
- Plasma may play a display or device disconnection sound.
- Turning the monitor off and on, or unplugging/replugging the display cable,
  can restore the session.
- Logs show KWin pageflip timeouts followed by AMDGPU `flip_done` and commit
  wait timeouts.
- Plasma services may report `There are no outputs - creating placeholder
  screen`, which means the session briefly lost all usable outputs.

## Evidence Captured

On June 4, 2026 around `08:55`, the previous generation showed:

- `There are no outputs - creating placeholder screen`
- `amdgpu 0000:03:00.0: [drm] *ERROR* flip_done timed out`
- `amdgpu 0000:03:00.0: [drm] *ERROR* [CRTC:363:crtc-0] commit wait timed out`
- a warning in `amdgpu_dm_atomic_commit_tail`

On June 4, 2026 around `10:44`, after rebooting with
`amdgpu.dcdebugmask=0x12` and `amdgpu.runpm=0`, the failure repeated:

- `kwin_wayland`: `Pageflip timed out! This is a bug in the amdgpu kernel
  driver`
- kernel: `amdgpu 0000:03:00.0: [drm] *ERROR* [CRTC:363:crtc-0] flip_done
  timed out`
- kernel: `amdgpu 0000:03:00.0: [drm] *ERROR* [PLANE:360:plane-6] commit wait
  timed out`
- kernel warning in `amdgpu_dm_atomic_commit_tail`
- Powerdevil saw a DRM hotplug event for connector `393`, reported as
  `card0-DP-5`
- Plasma services again reported no outputs

The `10:44` trace matters because it includes a plane commit timeout. That is
why the current trial adds AMD Display Core multi-plane offload disablement.

## Tried So Far

- Kernel 6.12.
- NixOS LTS/default kernel trial recorded in the old ledger.
- Latest unstable kernel, observed as `7.0.10` during the June 4 traces.
- `amdgpu.dcdebugmask=0x10`, disabling PSR.
- `amdgpu.dcdebugmask=0x12`, disabling PSR and stutter.
- `amdgpu.runpm=0`, disabling runtime power management for the GPU while this
  fault is being diagnosed.
- `amdgpu.sg_display=0`, avoiding the integrated display block.

The `0x10` and `0x12` trials did not hold. Do not repeat them as if they were
untried.

## Current Trial

`hosts/solanine/hardware.nix` now sets:

```nix
"amdgpu.dcdebugmask=0x52"
```

The mask is:

- `0x2`: disable Display Core stutter mode
- `0x10`: disable Panel Self Refresh
- `0x40`: disable multi-plane offloading

This is deliberately host-scoped. If the next boot survives normal Plasma
uptime, leave the parameter in place long enough to gain confidence. If idle
power, thermals, performance, or display correctness become worse, roll back
only the newest change first: return `0x52` to `0x12`.

## References

- Linux kernel AMDGPU module parameter docs: `dcdebugmask` overrides Display
  Core debug options.
- Linux kernel `DC_DEBUG_MASK` docs: `0x2` disables stutter, `0x10` disables
  PSR, and `0x40` disables multi-plane offloading.
- KWin's own failure message asks for `sudo dmesg` or `journalctl -b -k`, plus
  `journalctl --user-unit plasma-kwin_wayland --boot 0`, when reporting this
  class of AMDGPU pageflip timeout.

## Research Bank

These are open questions, not conclusions. Keep adding evidence here before
forging another parameter.

- Is the freeze tied to monitor handling: refresh rate, VRR/adaptive sync,
  DisplayPort link training, DSC, MST, EDID reads, hotplug handling, or power
  state transitions?
- Why does power-cycling or replugging the monitor shake the session loose? The
  working suspicion is that it forces a hotplug event, DisplayPort link retrain,
  EDID reread, or KWin output reconfiguration. The June 4 `10:44` trace did show
  a DRM hotplug event immediately after the timeout sequence, but that does not
  yet prove whether hotplug caused the freeze or helped recover from it.
- What actually triggers the freeze after login? The known pattern is roughly
  10-15 minutes after logging in to a Plasma session on two subsequent boots.
  Track whether the trigger aligns with session restore, Discord/Spotify start,
  KScreen applying output state, monitor sleep timers, powerdevil display
  watching, cursor/input wake, or the first hardware-accelerated application.
- Why do some days have no freeze, while other days have one early freeze and
  then no repeat? This may point to a one-time initialization race, monitor
  wake/link state, KWin output state restoration, a firmware timing window, or a
  workload that only runs shortly after login.
- Does sleep or suspend change the probability? Track whether the failure occurs
  after cold boot only, after resume only, or after both. Also note whether
  monitor standby without full system suspend is enough to trigger it.
- Does the monitor workaround behave differently if using monitor power-cycle,
  DisplayPort cable replug, GPU port change, HDMI, or a different refresh rate?
  These are separate tests; do not change several in the same boot.
- Does forcing a lower refresh rate reduce the fault? If testing this, record
  the exact mode before and after with `kscreen-doctor -o` or Plasma's display
  settings.
- Does disabling VRR/adaptive sync reduce the fault? This is a strong candidate
  because the symptom is a pageflip/commit wait failure in the display path.
- Does the freeze correlate with KWin planes or direct scanout? If `0x52`
  changes behavior, keep that result tied to the `0x40` multi-plane offload bit.
- Does the failure only appear with the current DisplayPort path? Record the
  connector reported by logs, the physical GPU port, cable, adapter, and monitor
  input used for each trial.
- Does runtime power management matter despite `amdgpu.runpm=0`? If failures
  continue, compare power/clock state evidence before removing the parameter.
- Do Mesa, firmware, or kernel updates change the frequency? Keep these trials
  separate from monitor and boot-parameter trials so the repair has a single
  cause to bless or reject.

## Validation Rite

After rebooting into a generation with the new parameter:

```bash
tr ' ' '\n' < /proc/cmdline | rg '^amdgpu\.'
```

Confirm that the output includes:

```text
amdgpu.sg_display=0
amdgpu.dcdebugmask=0x52
amdgpu.runpm=0
```

Then use the normal Plasma Wayland session through the workflows that have
previously frozen. After a meaningful session, check:

```bash
journalctl -b -k | rg 'flip_done|commit wait|amdgpu_dm|Pageflip'
```

```bash
journalctl --user-unit plasma-kwin_wayland --boot 0 | rg 'Pageflip|timed out'
```

No matches is a good sign, not proof. This fault is intermittent; the theorem
earns trust through uptime.

## Capture Before The Next Change

If the freeze returns, capture the logs before changing another parameter:

```bash
journalctl -b --since '15 minutes ago' --no-pager > /tmp/solanine-amdgpu-freeze-journal.txt
journalctl -b -k --since '15 minutes ago' --no-pager > /tmp/solanine-amdgpu-freeze-kernel.txt
journalctl --user-unit plasma-kwin_wayland --boot 0 --since '15 minutes ago' --no-pager > /tmp/solanine-amdgpu-freeze-kwin.txt
tr ' ' '\n' < /proc/cmdline | rg '^amdgpu\.' > /tmp/solanine-amdgpu-freeze-cmdline.txt
```

Keep the exact time of the freeze and whether the recovery came from monitor
power-cycle, cable replug, keyboard input, or a full session restart. Those
details tell us whether the next trial should focus on DisplayPort link
training, KWin planes, runtime power, VRR, Mesa, firmware, or kernel version.

## Next Trials

Do these one at a time. The forge cannot tell which charm held if three are
changed in one boot.

1. If `0x52` fails, capture logs and consider a display path trial: different
   GPU port, different DisplayPort cable, or HDMI if available.
2. If the same plane timeout repeats, test disabling VRR/adaptive sync in Plasma
   for this monitor before adding more kernel parameters.
3. If runtime power or thermal cost becomes too high while freezes continue,
   remove `amdgpu.runpm=0` first.
4. If a newer kernel or firmware update claims AMD Display Core fixes, test that
   in a separate generation and keep the boot parameter change otherwise stable.
5. If upstream reporting becomes useful, attach `sudo dmesg` or `journalctl -b
   -k`, plus `journalctl --user-unit plasma-kwin_wayland --boot 0`, matching the
   KWin request printed in the logs.
