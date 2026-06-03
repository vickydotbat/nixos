{
  username = "guest";
  description = "Low-access guest account";
  uid = 1002;
  homeDirectory = "/home/guest";
  extraGroups = [ ];
  passwordHashSecret = null;

  home = {
    enable = false;
  };

  ssh = {
    enable = false;
  };
}
