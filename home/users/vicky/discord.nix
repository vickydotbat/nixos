{
  programs.discord.enable = true;
  services.arrpc.enable = true;

  home.persistence."/nix/persist" = {
    directories = [
      ".config/discord"
    ];
  };
}
