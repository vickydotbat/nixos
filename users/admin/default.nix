{
  username = "admin";
  description = "Break-glass administrator";
  uid = 1001;
  homeDirectory = "/home/admin";
  extraGroups = [ "wheel" ];
  passwordHashSecret = "users/root/password-hash";

  home = {
    enable = false;
  };

  ssh = {
    enable = false;
  };
}
