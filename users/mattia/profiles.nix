{

  /*
    TODO: This user will need, within possibility, at a minimum:
    - OpenOffice/LibreOffice
    - WinBoat with Microsoft Office 365 if possible
    - Basic Firefox with chrome backup
    - A simple image editor (so not gimp)
    - Tools for Dungeons and Dragons DMing if they can be found
    -

    The user will not need any shell configuration. Plasma comes with konsole, which is sufficient for basic maintenance tasks

    The user will also need extensive gaming support

    Host should only persist necessary folders since this is immutable state anyway.
    User should persist the entire home folder, to keep things predictable for him. There should be no surprises there.
  */
  imports = [
    ./profiles/desktop.nix
  ];
}
