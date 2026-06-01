{config, ...}:

{
  home.persistence."/nix/persist" = {
    directories = [
      "Documents"
      "Pictures"
      "Videos"
      "Downloads"
      "Projects"
      "Music"
      "Repositories"
      "Templates"
      "Public"
      "Desktop"
      ".local/share/Steam"
    ];
  };
}
