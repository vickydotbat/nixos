let
  thisUser = "guest";
in
{
  username = "${thisUser}";
  description = "Guest";
  uid = 29999;
  homeDirectory = "/home/${thisUser}";
  avatar = ./avatar.png;
  extraGroups = [ ];
  passwordHashSecret = null;

  home = {
    enable = false;
  };

  ssh = {
    enable = false;
  };
}
