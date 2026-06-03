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
    # TODO: Misterio or someone else has this method of adding users to groups "if the groups exist"; definitely use this as a safety lever. For example: If Docker group exists, add to Docker. Use sane defaults here.
    # TODO: Questionable but likely better for reproducibility: Add users that need to be added to specific groups in the modules themselves. e.g. if there is a docker module, do it there.
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
