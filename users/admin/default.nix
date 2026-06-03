let
  thisUser = "admin";
in
{
  username = "${thisUser}";
  description = "Administrator";
  uid = 1000;
  homeDirectory = "/home/${thisUser}";
  avatar = ./avatar.png;
  extraGroups = [
    "wheel"
    "nixcfg"
  ];
  passwordHashSecret = "users/${thisUser}/password-hash";

  home = {
    enable = true;
    module = ./home.nix;
  };

  ssh = {
    enable = true;
    sopsFile = ../../secrets/ssh-${thisUser}.yaml;
    privateKeySecret = "ssh/${thisUser}/id_ed25519";
    publicKeySecret = "ssh/${thisUser}/id_ed25519.pub";
    privateKeyPath = "/run/secrets/ssh-${thisUser}-id_ed25519";
    publicKeyPath = "/run/secrets/ssh-${thisUser}-id_ed25519.pub";
  };
}
