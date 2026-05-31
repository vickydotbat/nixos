{ config, lib, ... }:

let
  cfg = config.vicky.nixos.base.users;
in
{
  options.vicky.nixos.base.users.enable = lib.mkEnableOption "base user accounts";

  config = lib.mkIf cfg.enable {
    users.mutableUsers = false;

    users.users.root.initialHashedPassword = "$y$j9T$G0vEXwrAZuyOgoFr6l2ep0$YTjMMRvHudaNNE4FK1mkf3ZKjaYzl35mYdIu4GPKn0A";

    users.users.vicky = {
      uid = 1000;
      isNormalUser = true;
      initialHashedPassword = "$y$j9T$G0vEXwrAZuyOgoFr6l2ep0$YTjMMRvHudaNNE4FK1mkf3ZKjaYzl35mYdIu4GPKn0A";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
    };
  };
}
