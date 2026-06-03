let
  thisUser = "admin";
in
{
  username = "${thisUser}";
  description = "Administrator";
  uid = 1000;
  homeDirectory = "/home/${thisUser}";
  extraGroups = [
    "wheel"
    "nixcfg"
  ];
  passwordHashSecret = "users/${thisUser}/password-hash";

  home = {
    enable = false;
  };

  ssh = {
    enable = false;
  };
}
