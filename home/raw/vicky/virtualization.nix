{ ... }:

{
  programs.distrobox = {
    enable = true;
  };

  services.podman = {
    enable = true;
  };

  home.persistence."/nix/persist" = {
    directories = [
      ".local/share/containers"
    ];
  };
}
