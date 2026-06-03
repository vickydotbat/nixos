{
  username = "vicky";
  description = "Vicky";
  uid = 1000;
  homeDirectory = "/home/vicky";
  extraGroups = [
    "wheel"
    "networkmanager"
  ];
  passwordHashSecret = "users/vicky/password-hash";

  home = {
    enable = true;
    module = ./home.nix;
  };

  ssh = {
    enable = true;
    sopsFile = ../../secrets/ssh-vicky.yaml;
    privateKeySecret = "ssh/vicky/id_ed25519";
    publicKeySecret = "ssh/vicky/id_ed25519.pub";
    privateKeyPath = "/run/secrets/ssh-vicky-id_ed25519";
    publicKeyPath = "/run/secrets/ssh-vicky-id_ed25519.pub";
  };
}
