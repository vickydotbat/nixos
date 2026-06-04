let
  thisUser = "admin";
  accountSecretsFile = ../../secrets/users-${thisUser}.yaml;
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

  secrets = {
    sopsFile = accountSecretsFile;
  };

  home = {
    enable = true;
    module = ./home.nix;
  };

  ssh = {
    enable = true;
    authorizedUsers = [ thisUser ];
    sopsFile = accountSecretsFile;
    privateKeySecret = "ssh/${thisUser}/id_ed25519";
    publicKeySecret = "ssh/${thisUser}/id_ed25519.pub";
    privateKeyPath = "/run/secrets/ssh-${thisUser}-id_ed25519";
    publicKeyPath = "/run/secrets/ssh-${thisUser}-id_ed25519.pub";
  };
}
