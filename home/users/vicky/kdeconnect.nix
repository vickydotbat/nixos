{
  services.kdeconnect = {
    enable = true;
  };

  home.persistence."/nix/persist" = {
    directories = [
      ".config/kdeconnect"
    ];
  };
}
