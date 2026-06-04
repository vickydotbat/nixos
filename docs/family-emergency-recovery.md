# Family Emergency Recovery

This guide is for the person caring for these machines if Vicky cannot: illness,
death, travel, damaged hardware, or any other day when the usual maintainer is
unavailable.

You are not expected to be a NixOS administrator. Go slowly. The machines were
built to be repairable, and the strict parts are there to protect private life:
accounts, browser sessions, SSH identities, and the ability to rebuild.

This document contains no passwords, recovery phrases, or private keys. It
explains what they are and where they fit. The real secrets live outside this
repository. Some are also kept encrypted in Vicky's and the admin account's
password manager, currently KeePassXC.

## First Rules

1. Do not wipe, reinstall, or factory-reset anything first.
2. Do not publish files from `secrets/`, `/nix/persist/secrets/`, KeePassXC, or
   a home directory.
3. Do not paste secret material into chat, email, issue trackers, or websites.
4. If a machine is still logged in and working, keep it powered and plugged in.
5. If unsure, ask a trusted technical person to read this with you before
   typing commands.

Preserve first. A running unlocked machine may already have KeePassXC, browser
sessions, or runtime secrets available. A reboot can close those doors.

## Before Browsing: Hidden Files

Linux hides files and folders whose names start with a dot, such as `.ssh`,
`.config`, `.local`, `.mozilla`, or `.password-store`. They are normal files,
not mistakes. Important key files, browser data, KeePassXC material, SSH notes,
or recovery clues may be inside hidden folders.

Before deciding something is missing, show hidden files.

In common file managers:

- **Dolphin**: press `Ctrl` + `H`, or use the menu and enable **Show Hidden
  Files**.
- **Thunar**: press `Ctrl` + `H`, or use **View -> Show Hidden Files**.
- **Nautilus / Files**: press `Ctrl` + `H`, or use the three-line menu and
  enable **Show Hidden Files**.

The same shortcut usually hides them again. Showing hidden files is safe; it
only changes what you can see. Deleting or moving them is not safe unless a
technical helper explains why.

In a terminal, these commands help you look gently:

```bash
pwd
ls -la
cd /home/vicky
ls -la
```

`pwd` shows where you are. `ls -la` lists files, including hidden ones. `cd`
moves into a folder. Press `Tab` while typing a file or folder name to ask the
terminal to complete it. If a name contains spaces, ask a helper before
guessing the command.

## What May Surprise You

These machines use a few protective habits that can look strange during
recovery. This is normal.

- **Some files are deliberately temporary.** Impermanence means parts of the
  system are rebuilt fresh on boot. Files that must survive are usually under
  `/nix/persist`, declared in this repository, or stored in a user's persisted
  home data.
- **A file may disappear after reboot.** Passwords changed through a desktop
  settings panel, quick edits under `/etc`, or files saved in temporary places
  may not survive unless the change is declared or persisted.
- **Some files are only present while the system is running.** Secrets under
  `/run/secrets` are created after boot from encrypted SOPS files. They are not
  normal documents and should not be copied casually.
- **Some files may be blocked by permissions.** That does not mean they are
  gone. It may mean you need the right account, `admin`, `sudo`, `run0`, or a
  technical helper.
- **Some applications are restricted on purpose.** Hardening and sandboxing can
  stop an app from seeing every folder. If a file picker cannot see something,
  try the file manager, a terminal, or ask a helper.
- **Remote access is key-only.** SSH is meant to use approved keys, not password
  guessing. If SSH fails, local login, TTY, or a recovery USB may still work.

The framework is simple: first ask whether the disk is unlocked, then whether
you are in the right account, then whether hidden files are visible, then
whether the file lives under `/nix/persist`, `/run/secrets`, a home directory,
or a USB/backup drive.

## The Short Version

There is a chain of locks.

1. **LUKS disk encryption** may unlock the disk at boot.
2. **Linux login** unlocks a user session such as `vicky`, `mattia`, or `admin`.
3. **KeePassXC** unlocks the password database.
4. **SOPS age keys** unlock this repository's encrypted secret files.
5. **NixOS rebuilds** use those decrypted secrets to recreate users, SSH keys,
   host keys, and recovery tools.

If one link is missing, identify that link. Do not skip ahead by reinstalling.

## What Each Piece Means

### LUKS

LUKS is disk encryption. It protects the machine while powered off. If the
machine asks for a disk password before the normal login screen, that is
probably LUKS.

`firelink` is declared with a LUKS encrypted root disk named `cryptroot`. Its
storage file says the encrypted disk opens as `/dev/mapper/cryptroot`.

Without the LUKS password:

- the disk contents remain locked
- the normal user accounts cannot start
- the password manager on that disk may not be reachable
- the SOPS key stored on that disk may not be reachable

The LUKS password is not in this repository. Look in the family emergency
records and KeePassXC material.

### Linux Login Accounts

These are the normal accounts on the machine.

- `vicky` is Vicky's daily-driver account.
- `mattia` is the managed desktop account for Firelink.
- `admin` is a repair account, meant for maintenance.
- `root` is the highest local authority inside Linux. It may not be available
  as a normal graphical login. Treat it as something a repair command, `sudo`,
  `run0`, or a rescue disk may use, not as the first account to try at the login
  screen.

At the graphical login screen, try the normal user first. Use `admin` for
repair. Use `root` only when a trusted repair instruction specifically needs it.

Administrative commands usually use `sudo`. Some hardened systems may use
`run0` instead. A **technical helper** is a trusted person comfortable with
Linux recovery: a family administrator, Linux-capable friend, or professional
repair person who understands that encrypted data must be preserved. If a guide
says `sudo` and it is unavailable, ask whether this machine uses `run0`.

### KeePassXC

KeePassXC is the password manager: a locked box containing other keys.

The KeePassXC database itself is encrypted. It may require:

- a database file, usually ending in `.kdbx`
- a master password
- possibly a separate key file, often named with a `key-` prefix, though the
  exact name and extension may vary

This repository deliberately does not name the master password or key file. Look
for those details in family emergency records, not Git.

The KeePassXC databases for Vicky and admin may contain copies of:

- account passwords
- root or admin recovery passwords
- LUKS recovery material
- SOPS age private keys
- SSH private keys or notes about them
- service account credentials

If KeePassXC opens, search for the specific item needed. Do not export
everything. Copy only what the repair requires.

Do not assume `admin` can open Vicky's KeePassXC database by itself. The
database or key file may be in Vicky's home directory, on a USB drive, on an
external backup disk, or in another emergency location. A `.kdbx` file, its
password, and any required key file must be kept together logically, even if
stored separately.

### SOPS

SOPS is how this repository stores secrets safely in Git.

Files like these are encrypted:

- `secrets/hosts-solanine.yaml`
- `secrets/hosts-firelink.yaml`
- `secrets/users-admin.yaml`
- `secrets/users-vicky.yaml`
- `secrets/users-mattia.yaml`

They can live in Git because they are encrypted. They need the matching SOPS age
private key to be useful.

The live NixOS machines normally keep the SOPS age key at:

```text
/nix/persist/secrets/sops/age/keys.txt
```

That file is sensitive. It can unlock this repository's encrypted secrets. Do
not email it, upload it, or paste it into chat.

Copies of this key, or notes for restoring it, may be in Vicky's and admin's
KeePassXC databases. That is the emergency bridge: KeePassXC can restore the
SOPS key, and the SOPS key can help rebuild the machine.

Restoring a SOPS age key means putting the right private key text where the
machine expects it:

```text
/nix/persist/secrets/sops/age/keys.txt
```

Have a technical helper do this after the key is found in KeePassXC or another
emergency record. Keep it readable only by the administrator account. Never put
it in the repository, a shared folder, cloud notes, email, or chat.

### Terminal And Text Commands

Some repairs use a terminal: a window for typed commands. On a desktop, search
the application launcher for `Terminal`, `Konsole`, or a similar name.

If the desktop is broken, use a text login screen called a TTY. Hold `Ctrl` and
`Alt`, then press `F3`. If that fails, try `F2`, `F4`, or `F5`. To return to the
graphical screen, try `Ctrl` + `Alt` + `F1` or `F2`.

At a TTY login prompt:

1. Type the account name, such as `admin`.
2. Press Enter.
3. Type the password. The screen may show nothing while you type; that is
   normal.
4. Press Enter again.

Commands in this guide appear in blocks. A helper can type them one line at a
time. If you are not comfortable with terminals, do not improvise; ask what a
command changes before it runs.

### SSH

SSH is a way to open a terminal on one machine from another machine. It can help
a trusted helper repair a machine without sitting at its keyboard.

SSH usually works only when:

- the target machine is powered on
- LUKS has already been unlocked, unless special remote-unlock support exists
- the target machine has network access
- the OpenSSH server is enabled on the target
- the connecting user has an approved private SSH key

SSH does not bypass LUKS or KeePassXC. If the disk is still locked at boot, SSH
usually cannot reach the normal system yet. Some systems can be configured for
remote LUKS unlock, but do not assume that path exists unless a maintainer says
so.

Approved normal access is:

- `admin` may connect to the `admin` account on every host.
- `vicky` may connect to the `vicky` account on `solanine`.
- `mattia` may connect to the `mattia` account on `firelink`.
- Vicky and Mattia are mutually trusted for emergency user-account access.

That last rule means Vicky's SSH key may be accepted for Mattia's account, and
Mattia's SSH key may be accepted for Vicky's account. It is for family repair,
not curiosity.

A helper may use commands shaped like:

```bash
ssh admin@solanine
ssh vicky@solanine
ssh mattia@firelink
```

The names may need a local network address instead, such as
`ssh admin@192.168.1.20`. If SSH fails, use the local keyboard, TTY, or a
recovery USB instead.

### Recovery USB Drives

A recovery USB can start a computer even when the installed system is damaged.
It is a spare doorway, not a master key. If the disk uses LUKS, the USB still
needs the LUKS password or recovery material.

There may be several kinds of USB devices in an emergency kit:

- a **bootable installer or rescue USB**, often labeled `NixOS`, `Linux`,
  `rescue`, `installer`, or `recovery`
- an **external backup drive** holding copies of home files, KeePassXC
  databases, repository copies, or browser backups
- a **key-material USB** holding a KeePassXC key file or other unlock material
- a **hardware security key**, such as a small USB token, if one is used for
  account login or disk unlock

They may be with emergency papers, in a safe, desk drawer, laptop bag, backup
drive pouch, admin kit, or with the trusted maintainer. Label purpose, not
secrets: `Vicky recovery USB` is useful; `LUKS password for Firelink` on a tag
is not.

Keep pieces separated when possible. A thief who finds one piece should not
immediately find every piece.

Use a recovery USB when:

- the machine will not reach the normal login screen
- the bootloader is broken
- the graphical desktop is unusable
- you need to copy files before repair
- a technical helper needs an outside system to inspect the disk
- you are preparing to reinstall only after the data has been preserved

If the machine is already on and unlocked, do not boot USB first. Preserve the
live session.

To boot from a USB drive:

1. Shut down only if the live session cannot be preserved or a helper says to.
2. Plug in the recovery USB drive.
3. Turn the machine on.
4. Immediately tap the boot-menu key several times. Common keys are `F12`,
   `F11`, `F10`, `F9`, `Esc`, or `Del`. Some laptops require holding `Fn` while
   pressing the function key.
5. Choose the USB entry. It may show the USB brand name. Prefer an entry that
   begins with `UEFI` when there is a choice.
6. Choose a live, rescue, or installer environment. Do not choose erase, format,
   partition, or install until data has been copied and reinstalling is
   deliberate.

If the machine ignores the USB, a helper may need to change firmware settings,
adjust Secure Boot, try another USB port, or recreate the drive. That is normal
repair work, not a reason to wipe the disk.

Once booted from USB, the computer is running from the USB, not the installed
system. The internal disk may appear locked. If it is LUKS-encrypted, opening it
asks for the LUKS password. Without that password, the files remain protected.

A recovery USB can help a technical helper:

- copy home files to an external drive
- open a LUKS-encrypted disk when the password is known
- inspect disks without starting the broken installed system
- repair a bootloader
- check whether `/nix/nixos` and `secrets/*.yaml` are present
- restore `/nix/persist/secrets/sops/age/keys.txt` from KeePassXC or emergency
  records
- mount the installed system under `/mnt` for repair
- enter the installed system with `nixos-enter`
- run checks, dry-builds, or a rebuild from the repository
- install NixOS or another operating system after backups are verified

A recovery USB cannot:

- bypass LUKS without the password or a valid recovery key
- unlock KeePassXC without its database password and required key file
- prove which files are safe to delete
- make a destructive reinstall safe before backups are checked

When copying files from a recovery USB session, copy rather than move. Use a
trusted external drive with enough space. Use a clear folder name:

```text
2026-06-04-firelink-recovery-copy
```

After copying, open a few copied files from the external drive. A checked backup
is calmer than a hopeful one.

### This Repository And GitHub

This repository is the set of files that describes these NixOS machines. The
local copy is normally at:

```text
/nix/nixos
```

Git tracks changes. GitHub may hold an online copy. GitHub is not the secret by
itself: files in `secrets/` are encrypted and need the SOPS age private key.

Important boundary: the repository alone is not enough to unlock secrets. The
repository plus the SOPS age private key is powerful. Do not send those
together.

In an emergency, first look for the local checkout:

```bash
cd /nix/nixos
git status
```

If the machine is gone, a helper may need a fresh copy from GitHub or another
Git remote. The address is not listed here because access may change. Look in
emergency records, browser bookmarks, the GitHub account, or another machine
with this repository. A clone command looks like this:

```bash
git clone <repository-address> nixos
cd nixos
```

After cloning, `secrets/*.yaml` should be present but still locked until the
matching SOPS age key is restored.

### NixOS Rebuilds

NixOS rebuilds read this repository and recreate accounts, packages, services,
and runtime secrets.

A rebuild is not the first emergency step. It comes after the secret chain is
understood.

For NixOS work in this repository, a technical helper should start with checks
that do not switch the live system:

```bash
nix flake check
nix build .#nixosConfigurations.solanine.config.system.build.toplevel --dry-run
nix build .#nixosConfigurations.firelink.config.system.build.toplevel --dry-run
```

Only switch a host when the helper knows whether they are working locally or
deploying remotely.

## What Is In Each Secret File

Host files belong to machines:

- `secrets/hosts-solanine.yaml`
- `secrets/hosts-firelink.yaml`

They hold host-owned secrets:

- root password hashes
- host SSH server keys
- host service secrets

User files belong to login accounts:

- `secrets/users-admin.yaml`
- `secrets/users-vicky.yaml`
- `secrets/users-mattia.yaml`

They hold user-owned secrets:

- the user's login password hash
- the user's outbound SSH identity
- the user's Firefox backup identity, when that user has Firefox backup enabled

Firefox backups are user-centered. A user's archives are encrypted for that
user's backup key. Admin is not a recovery recipient for another user's Firefox
backups.

The Firefox profile being protected normally lives at:

```text
/nix/persist/home/<user>/.mozilla/firefox/<user>
```

The encrypted backup archives normally live at:

```text
/nix/persist/home/<user>/Backups/firefox-state/
```

The archive names look like:

```text
firefox-state-20260604T120000Z.tar.age
```

These backups contain selected Firefox state: bookmarks, history, favicons,
cookies, form history, saved-login files, certificates, dictionary data, site
permissions, open tabs, bookmark backups, and session backups. They are not a
full home backup, just the browser state most likely to matter after a rebuild.

The backup unlocks with the user's Firefox backup age identity. On a running
system, it is deployed at:

```text
/run/secrets/firefox-backup-<user>-age-identity
```

Its encrypted source is `firefox-backup-age-identity` in the user's secret file,
for example `secrets/users-vicky.yaml`.

If the user's session and Firefox backup tools are available, a helper can
restore the newest archive with:

```bash
firefox-state-restore
```

Close Firefox before restoring. The command prints where it placed the files.
Do not try to decrypt another user's Firefox archive with `admin`; this system
does not support that path.

## Emergency States

### The Machine Is On And Logged In

This is the easiest state.

1. Keep it plugged in.
2. Do not reboot.
3. Check whether KeePassXC is already open.
4. If KeePassXC is locked, look for the family emergency instructions for its
   password and key file.
5. Export nothing unless a trusted helper tells you why.
6. If you need browser data, copy or back up the relevant files before making
   changes.

If Vicky's session is open, gather needed records from that session before
changing anything.

### The Machine Is On But Locked

Try the normal login password. If needed, try `admin`.

If neither works, do not force a reset yet. It can make the next step harder.

### The Machine Is Off And Asks For A Disk Password

That is probably LUKS.

1. Find the LUKS password or recovery material in the emergency records.
2. Unlock the disk.
3. Log into the normal user or `admin`.
4. Open KeePassXC if more secrets are needed.

If you log in as `admin`, do not assume Vicky's KeePassXC database is already
available there. It may be in Vicky's home directory, on a USB drive, or on an
external backup disk. Look for a `.kdbx` database file and any matching key
file described by the emergency records. Do not move the only copy.

If LUKS cannot be unlocked, the data remains protected. Recovery then depends on
backups, KeePassXC copies elsewhere, or another machine with the needed secrets.

### The Machine Boots But Login Fails

Use the `admin` account if available. It exists for repair.

Once logged in as admin, a technical helper can open a terminal or TTY and
inspect the system without changing it:

```bash
journalctl -b --no-pager
systemctl --failed
ls /run/secrets
```

Do not change passwords with desktop settings unless a maintainer confirms the
change is declared in SOPS. Otherwise it may disappear on reboot.

### The Machine Is Lost Or Destroyed

You need three things to rebuild a replacement:

1. This repository, restored from `/nix/nixos`, GitHub, another Git remote, or a
   backup.
2. The encrypted `secrets/*.yaml` files.
3. A matching SOPS age private key, usually restored to
   `/nix/persist/secrets/sops/age/keys.txt`.

If KeePassXC is available, search for the SOPS age key or restore notes. A
helper can place the recovered key on the replacement machine, then verify it
decrypts the needed `secrets/hosts-<host>.yaml` and `secrets/users-<name>.yaml`
files before switching the new system.

You may also need:

- LUKS recovery material for disks you still have
- the KeePassXC database, password, and key file
- backups of user home data
- Firefox backup archives and the matching user's Firefox backup identity

Do not publish the repository together with the SOPS age private key.

### Vicky Is Dead, Ill, Or Cannot Consent

This is not only technical. Move gently and keep a record.

1. Preserve devices and backup drives.
2. Do not erase anything.
3. Locate the family emergency notes for KeePassXC, LUKS, and account access.
4. If legal or family authority matters, settle that before opening private
   accounts.
5. Use the minimum access needed for the immediate care task.
6. Keep a written log of what was opened and why.

The goal is care, not curiosity. Private data remains private.

## A Practical Recovery Order

When unsure, use this order:

1. Is the machine powered on and unlocked? If yes, preserve that state.
2. Can you open KeePassXC? If yes, use it to find the specific missing key.
3. Can you unlock LUKS after a reboot? If no, do not reinstall.
4. Can you log into `admin`? If yes, use it for repair.
5. Is `/nix/persist/secrets/sops/age/keys.txt` present? If yes, SOPS secrets can
   usually be decrypted by the system.
6. Are the encrypted files in `secrets/` present in the repository clone? If
   no, restore them from Git or backup.
7. Is a recovery USB needed because the installed system will not boot? If yes,
   use it to preserve data before repair or reinstall.
8. Run only checks or dry-builds until a maintainer is ready to switch the
   system.

## What To Ask A Technical Helper

If you need help, give the helper this exact context:

```text
This is a NixOS flake repository.
Secrets are managed with SOPS and age.
The SOPS age key normally lives at /nix/persist/secrets/sops/age/keys.txt.
Host secrets are in secrets/hosts-<host>.yaml.
User secrets are in secrets/users-<name>.yaml.
The password manager is KeePassXC.
The machine may use LUKS disk encryption.
There may be recovery USB drives, backup USB drives, or key-material USB drives.
Please do not wipe or reinstall before checking the secret chain.
```

Ask them to explain each command before running it.

## Things Not To Do

- Do not commit decrypted secrets.
- Do not copy private keys into shared documents.
- Do not rotate passwords unless you know where the declarative SOPS source is.
- Do not delete old generations or backups during the first repair session.
- Do not format, partition, or wipe unless data has been saved and reinstalling
  is deliberate.
- Do not assume a password changed through a desktop settings panel will survive
  reboot on an impermanent system.
- Do not boot a USB installer and click through an install wizard unless the
  files have already been copied and the reinstall is deliberate.

## If You Must Keep Going Without The Maintainer

You may not want to become the system administrator. That is reasonable. Your
first task is to preserve data and keep life moving.

For daily use:

1. Keep the machine plugged in and avoid unnecessary reboots.
2. Keep using the normal account if it works.
3. Keep KeePassXC locked when not needed, but make sure the emergency records
   still explain how to open it.
4. Copy ordinary personal files to a trusted external drive or backup service:
   documents, photos, music, projects, and records.
5. Keep the repository and encrypted `secrets/` files backed up together. Keep
   the SOPS age private key backed up separately inside KeePassXC or another
   encrypted emergency store.
6. Write down repair actions: date, person, machine, what opened, what changed.

For repository care:

- Do not delete `/nix/nixos`.
- Do not delete `secrets/*.yaml`.
- Do not store `/nix/persist/secrets/sops/age/keys.txt` beside an unencrypted
  copy of the repository.
- Ask a technical helper to run `git status` before changing repository files.
- Prefer check and dry-build commands before any command that switches or
  rebuilds the running system.

If NixOS becomes too much to maintain, moving to another operating system is
acceptable after personal data and emergency records are safe. Do not begin by
wiping the disk. First copy user files, browser data, KeePassXC databases, key
files, repository files, and backups to verified storage. Then a helper can
install another system. This is not failure; it is a controlled landing.

## Glossary

**Age key**: A cryptographic key used by SOPS. The private part unlocks secrets.

**Admin account**: A local repair account with more authority than a normal user.

**Encrypted secret file**: A file in `secrets/` that can be stored in Git but
cannot be read without the right key.

**KeePassXC**: The password manager. It is an encrypted box of passwords and
keys.

**LUKS**: Disk encryption used before the operating system starts.

**NixOS generation**: A bootable version of the system configuration. Old
generations can help roll back a bad change.

**Root**: The highest local administrator account. Use it carefully.

**SOPS**: The tool that encrypts and decrypts this repository's secret files.

## Final Word

You do not have to understand everything before asking for help. Protect the
chain:

```text
device -> LUKS -> login -> KeePassXC -> SOPS age key -> encrypted secrets -> rebuild
```

Keep the chain intact. Move slowly. Preserve first, repair second.
