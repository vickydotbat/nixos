let
  thisUser = "vicky";
  thisUserName = "Vicky";
in
{
  username = "${thisUser}";
  description = "${thisUserName}";
  uid = 1001;
  homeDirectory = "/home/${thisUser}";
  extraGroups = [
    "wheel"
    "networkmanager"
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
