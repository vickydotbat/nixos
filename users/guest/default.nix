let
  thisUser = "guest";
in
{
  username = "${thisUser}";
  description = "Low-access guest account";
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
