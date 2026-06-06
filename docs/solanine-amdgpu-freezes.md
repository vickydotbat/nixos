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
- Current kernel observed during the June 4-5 traces: `7.0.10`
- Current host-scoped boot parameters:
  - `amdgpu.sg_display=0`
  - `amdgpu.dcdebugmask=0x52`
  - `amdgpu.runpm=0`

`amdgpu.sg_display=0` keeps the integrated display block out of the display
theorem. `amdgpu.runpm=0` keeps the discrete GPU out of runtime power-down
while this is being diagnosed. `amdgpu.dcdebugmask=0x52` is the current
configured mask: it disables stutter (`0x2`), PSR (`0x10`), and multi-plane
offloading (`0x40`).

## Symptoms

- Plasma Wayland freezes while the machine remains recoverable.
- Plasma may play a display or device disconnection sound.
- Turning the monitor off and on, or unplugging/replugging the display cable,
  can restore the session.
- Logs show KWin pageflip timeouts followed by AMDGPU `flip_done` and commit
  wait timeouts in the older, confirmed driver-timeout traces.
- Plasma services may report `There are no outputs - creating placeholder
  screen`, which means the session briefly lost all usable outputs.
- A newer June 6 incident produced the `no outputs` and DisplayPort hotplug
  pattern without kernel `flip_done`/commit wait evidence. Keep it in the same
  ledger because it touches the same monitor link, but do not pretend it proves
  the same AMDGPU pageflip timeout class.

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
why the next trial added AMD Display Core multi-plane offload disablement.

On June 5, 2026, the machine booted at `08:00:17 CEST`, and Vicky's Plasma
Wayland session opened at `08:00:37 CEST`. The display froze around `09:10`,
with the first journal evidence at `09:09:14`: about `1:08:57` after boot and
`1:08:37` after session start.

The boot was running the current parameter set:

- `amdgpu.sg_display=0`
- `amdgpu.dcdebugmask=0x52`
- `amdgpu.runpm=0`

The failure still repeated:

- `kwin_wayland`: `Pageflip timed out! This is a bug in the amdgpu kernel
  driver`
- kernel: `amdgpu 0000:03:00.0: [drm] *ERROR* [CRTC:257:crtc-0] flip_done
  timed out`
- kernel: `amdgpu 0000:03:00.0: [drm] *ERROR* [CRTC:257:crtc-0] commit wait
  timed out`
- kernel: `amdgpu 0000:03:00.0: [drm] *ERROR* [PLANE:254:plane-4] commit wait
  timed out`
- kernel warning in `amdgpu_dm_atomic_commit_tail`
- Powerdevil saw DRM hotplug events for connector `287`, again reported as
  `card0-DP-5`
- Plasma services again reported `There are no outputs - creating placeholder
  screen`

Recovery matched the standing monitor-link pattern: turning the monitor off
played KDE's disconnect tone, and turning it back on caused a delayed reconnect
tone and restored the display. No second pageflip or AMDGPU timeout trace was
present after `09:12:30` as of the `09:15` check, but the day is still young;
do not let one quiet interval become doctrine.

On June 6, 2026, Vicky returned to the machine and found a black screen after
turning the monitor back on. The closest journal evidence is around
`12:45-12:46 CEST`, roughly `28.8` hours into the current boot. This does not
match the earlier pageflip-timeout trace:

- No kernel entries were present between `12:43` and `12:48`.
- No kernel `flip_done`, `commit wait`, `amdgpu_dm_atomic_commit_tail`, AMDGPU
  reset, or ring timeout entries appeared after `12:00`.
- `plasma-kwin_wayland` had no pageflip or timeout entries in the
  `12:43-12:48` window.
- Powerdevil saw DRM hotplug events for connector `287`, reported again as
  `card0-DP-5`, at `12:45:31`, `12:46:05`, and `12:46:11`.
- At `12:46:05`, Plasma-adjacent services reported `There are no outputs -
  creating placeholder screen`, including `plasmashell`, `kded6`,
  `powerdevil`, `xdg-desktop-portal-kde`, `kwalletd6`, `dolphin`, and others.
- A similar no-output cluster appeared earlier at `12:04:17`, also tied to
  connector `287` / `card0-DP-5`, but it was not directly observed by the
  operator.

Interpretation: this is still display-link evidence, but it is currently a
monitor wake/hotplug/no-output incident rather than a confirmed AMDGPU pageflip
timeout. The recovery path and `card0-DP-5` connector are familiar; the missing
kernel and KWin timeout evidence is the part that matters.

## Tried So Far

- Kernel 6.12.
- NixOS LTS/default kernel trial recorded in the old ledger.
- Latest unstable kernel, observed as `7.0.10` during the June 4-5 traces.
- `amdgpu.dcdebugmask=0x10`, disabling PSR.
- `amdgpu.dcdebugmask=0x12`, disabling PSR and stutter.
- `amdgpu.dcdebugmask=0x52`, disabling PSR, stutter, and multi-plane
  offloading. This did not prevent the June 5 freeze.
- `amdgpu.runpm=0`, disabling runtime power management for the GPU while this
  fault is being diagnosed.
- `amdgpu.sg_display=0`, avoiding the integrated display block.

These parameters also did not prevent the June 6 monitor-wake/no-output
incident, but that incident lacks the pageflip timeout signature. Keep that
distinction visible before changing another kernel parameter.

The `0x10`, `0x12`, and `0x52` trials did not hold. Do not repeat them as if
they were untried.

## Current State

`hosts/solanine/hardware.nix` now sets:

```nix
"amdgpu.dcdebugmask=0x52"
```

The mask is:

- `0x2`: disable Display Core stutter mode
- `0x10`: disable Panel Self Refresh
- `0x40`: disable multi-plane offloading

This is deliberately host-scoped, but it is no longer a successful trial. The
June 5 trace proves that disabling multi-plane offloading with `0x40` did not
remove the pageflip-timeout fault class. The June 6 trace shows a related
monitor-link failure without pageflip timeout evidence. Keep the setting stable
until the next deliberate test unless power, thermals, performance, or display
correctness become worse.

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
- Are there two related failure modes here: one AMDGPU/KWin pageflip timeout,
  and one monitor-wake hotplug path where Plasma temporarily sees no outputs
  without a kernel timeout? The June 6 evidence suggests yes, but one incident
  is not enough to split the theorem.
- Does sleep or suspend change the probability? Track whether the failure occurs
  after cold boot only, after resume only, or after both. Also note whether
  monitor standby without full system suspend is enough to trigger it.
- Does simple monitor standby/wake trigger the no-output cluster even when the
  system itself does not suspend? The June 6 `12:45-12:46` incident looks like
  monitor wake or DisplayPort hotplug without a matching system sleep.
- Does the monitor workaround behave differently if using monitor power-cycle,
  DisplayPort cable replug, GPU port change, HDMI, or a different refresh rate?
  These are separate tests; do not change several in the same boot.
- Does forcing a lower refresh rate reduce the fault? If testing this, record
  the exact mode before and after with `kscreen-doctor -o` or Plasma's display
  settings.
- Does disabling VRR/adaptive sync reduce the fault? This is a strong candidate
  because the symptom is a pageflip/commit wait failure in the display path.
- Does the freeze correlate with KWin planes or direct scanout? The June 5
  failure still had a plane commit timeout under `0x52`, so the `0x40`
  multi-plane offload bit was not enough by itself.
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

For monitor-wake incidents that do not show kernel timeouts, also check:

```bash
journalctl -b --since '10 minutes ago' --no-pager | rg 'There are no outputs|prop_connector|card0-DP-5|hotplug|placeholder screen'
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
journalctl -b --since '15 minutes ago' --no-pager | rg 'There are no outputs|prop_connector|card0-DP-5|hotplug|placeholder screen' > /tmp/solanine-amdgpu-freeze-display-link.txt
```

Keep the exact time of the freeze and whether the recovery came from monitor
power-cycle, cable replug, keyboard input, or a full session restart. Those
details tell us whether the next trial should focus on DisplayPort link
training, KWin planes, runtime power, VRR, Mesa, firmware, or kernel version.

## Next Trials

Do these one at a time. The forge cannot tell which charm held if three are
changed in one boot.

1. Consider a display path trial: different GPU port, different DisplayPort
   cable, or HDMI if available. The June 6 no-output incident strengthens this
   path because the only strong evidence was DisplayPort hotplug on
   `card0-DP-5`, not a kernel pageflip timeout.
2. KScreen mode `3:1920x1080@119.98` is now the current lower-refresh trial.
   A direct `kscreen-doctor output.DP-2.mode.3` switch briefly produced a black
   screen and monitor-side `Input not supported` flashing on June 5, 2026, but
   selecting the same mode through Plasma's Display Configuration was accepted.
   The declarative state should therefore mirror Plasma's accepted
   `kwinoutputconfig.json`, not a hand-built timing guess.
3. Test disabling VRR/adaptive sync in Plasma for this monitor before adding
   more kernel parameters.
4. If runtime power or thermal cost becomes too high while freezes continue,
   remove `amdgpu.runpm=0` first.
5. If a newer kernel or firmware update claims AMD Display Core fixes, test that
   in a separate generation and keep the boot parameter change otherwise stable.
6. If upstream reporting becomes useful, attach `sudo dmesg` or `journalctl -b
   -k`, plus `journalctl --user-unit plasma-kwin_wayland --boot 0`, matching the
   KWin request printed in the logs.
