let
  thisUser = "vicky";
  thisUserName = "Vicky";
  accountSecretsFile = ../../secrets/users-${thisUser}.yaml;
in
{
  username = "${thisUser}";
  description = "${thisUserName}";
  uid = 1001;
  homeDirectory = "/home/${thisUser}";
  avatar = ./avatar.png;
  extraGroups = [
    "nixcfg"
    # Read the full system journal (kernel, GPU, other units) without run0.
    "systemd-journal"
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
    # mattia has no key set up yet. Listing him pulls `secrets/users-mattia.yaml`
    # into every host that logs vicky in, and sops-install-secrets is
    # all-or-nothing: one file the host cannot decrypt leaves it with no
    # /run/secrets at all. Add him back when his key exists on all hosts.
    authorizedUsers = [
      thisUser
    ];
    sopsFile = accountSecretsFile;
    privateKeySecret = "ssh/${thisUser}/id_ed25519";
    publicKeySecret = "ssh/${thisUser}/id_ed25519.pub";
    privateKeyPath = "/run/secrets/ssh-${thisUser}-id_ed25519";
    publicKeyPath = "/run/secrets/ssh-${thisUser}-id_ed25519.pub";
  };
}
