{

  /*
    Managed desktop requirements for this user live in
    docs/TODO-husband-system.md. Keep this profile small until that ledger
    decides the account, persistence, and GUI application boundary.

    Current operator notes to preserve for that repair:
    - OpenOffice/LibreOffice
    - WinBoat with Microsoft Office 365 if possible
    - Basic Firefox with chrome backup
    - A simple image editor (so not gimp)
    - Tools for Dungeons and Dragons DMing if they can be found

    The user will not need custom shell configuration. Plasma comes with
    Konsole, which is sufficient for basic maintenance tasks.

    The user will also need extensive gaming support.

    Host state should persist only the necessary folders. User state may need a
    broader home persistence posture than Vicky's workshop so ordinary desktop
    expectations remain predictable.
  */
  imports = [
    ./profiles/desktop.nix
  ];
}
