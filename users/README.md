# Users

This directory holds repository-level user doctrine.

Hosts choose from these declarations. The user tree names the person or account
role, the groups it needs, the password secret it expects, and whether Home
Manager should be forged for it. System modules consume the chosen accounts;
Home Manager modules consume the chosen user's home profile.

## Layout

- `admin/` is the mandatory repair account. It belongs to `wheel` and exists so
  a host has a known administrative handhold even when daily-driver users are
  being recalibrated.
- `guest/` is an opt-in low-access account. It should not receive SSH private
  key material or administrative groups.
- `vicky/` is the current daily-driver user, including her Home Manager profile
  and SSH client settings.

## Failure Modes

- Do not put host hardware, host package choices, or machine-specific secrets
  here. Users describe accounts; hosts decide whether those accounts belong on a
  given machine.
- Do not give a daily-driver account duties that belong to `admin`. Repair needs
  a separate grip when personal configuration is the broken mechanism.
- `admin` currently reuses the root password hash secret on Solanine. Split this
  into a dedicated `users/admin/password-hash` secret when the encrypted file is
  next opened for secret maintenance.
