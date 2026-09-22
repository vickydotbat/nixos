{
  config,
  ...
}:
{
  # The tracker client reads PLANE_BASE_URL, PLANE_WORKSPACE and PLANE_API_KEY
  # from the environment, and falls back to ~/.config/sow/plane.env when the
  # environment is bare (ADR-0059). SOPS renders that file once, and both views
  # point at it: the symlink for anything that reads the config path, the shell
  # sourcing it for anything that reads the environment.
  #
  # The symlink leaves the plaintext in /run/secrets. A copied file would have
  # to pass through the world-readable Nix store to get here.
  xdg.configFile."sow/plane.env".source =
    config.lib.file.mkOutOfStoreSymlink "/run/secrets/plane-vicky-env";

  # ponytail: interactive shells only. A tool launched straight from a desktop
  # menu gets the config file above instead, which is the documented path.
  programs.bash.initExtra = ''
    if [ -r /run/secrets/plane-vicky-env ]; then
      set -a
      . /run/secrets/plane-vicky-env
      set +a
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
