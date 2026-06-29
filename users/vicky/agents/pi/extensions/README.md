# Pi Agent Extensions

This directory is reserved for Pi extension seeds that are safe to install as
plain files under `~/.pi/agent/extensions/`.

Do not add extension installers, network setup, model downloads, or other
activation-time work here. Home Manager may seed files, but the running agent
must own any expensive or stateful setup after activation has finished.

## Current State

No active Pi extension is declared in this tree yet. Add one only when its
failure modes are clear and it can be reviewed like ordinary source code.
