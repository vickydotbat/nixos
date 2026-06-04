let
  thisUser = "mattia";
  thisUserName = "Mattia";
  accountSecretsFile = ../../secrets/users-${thisUser}.yaml;
in
{
  username = "${thisUser}";
  description = "${thisUserName}";
  uid = 1002;
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
    authorizedUsers = [
      thisUser
      "vicky"
    ];
    sopsFile = accountSecretsFile;
    privateKeySecret = "ssh/${thisUser}/id_ed25519";
    publicKeySecret = "ssh/${thisUser}/id_ed25519.pub";
    privateKeyPath = "/run/secrets/ssh-${thisUser}-id_ed25519";
    publicKeyPath = "/run/secrets/ssh-${thisUser}-id_ed25519.pub";
  };
}
