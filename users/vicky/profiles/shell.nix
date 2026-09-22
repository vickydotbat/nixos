{
  # The Plane work-item tracker reads its credential from the environment, so
  # the shell exports the SOPS-rendered token file at login. The guard keeps a
  # host without the secret quiet instead of noisy.
  #
  # ponytail: interactive shells only. A tool launched straight from a desktop
  # menu never sources this; start it from a terminal, or promote the export to
  # a systemd user environment if that becomes the common path.
  programs.bash.initExtra = ''
    if [ -r /run/secrets/plane-vicky-api-key ]; then
      PLANE_API_KEY="$(< /run/secrets/plane-vicky-api-key)"
      export PLANE_API_KEY
    fi
  '';

  theorem.home.shell = {
    enable = true;
    bat.enable = true;
    kitty.enable = true;
    git.enable = true;
    git-tidy.enable = true;
    nix-index = {
      enable = true;
      commandNotFound.enable = true;
    };
    ripgrep = {
      enable = true;
      arguments = [
        "--hidden"
        "--smart-case"
        "--max-columns=200"
        "--max-columns-preview"

        "--glob=!.git/"
        "--glob=!result"
        "--glob=!result-*"
        "--glob=!.direnv/"
        "--glob=!.devenv/"

        "--colors=line:style:bold"
      ];
    };
    starship.enable = true;

    extraAliases = {
      pi-update = "nix-shell -p nodejs 'python3.withPackages (ps: [ ps.pyyaml ])' --run 'pi update --extensions'";
    };
  };
}
