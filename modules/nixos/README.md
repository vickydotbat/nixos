# NixOS Modules

This tree declares reusable system mechanisms under `theorem.nixos.*`.

Each module should stay quiet until a host profile enables it. A good module
names one repairable mechanism, exposes the smallest useful option surface, and
then maps that choice onto native NixOS options. Host identity, hardware facts,
disk layout, and one-off package choices belong in `hosts/<host>/`, not here.

Use this tree for system-owned substrate: boot posture, networking, desktop
services, graphics and audio support, security profiles, persistence,
virtualisation, secret binding, and other root-owned machinery. When a module
creates or depends on an access group, the module should own that group grant
instead of freezing it into static user declarations.

Sharp mechanisms need named escape hatches. If an option can break login,
networking, containers, portals, firmware updates, or rollback, document the
failure mode beside the option and validate it with a targeted eval or dry
build before switching a host.
