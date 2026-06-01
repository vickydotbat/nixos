{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        IdentityFile = "~/.ssh/id_ed25519";
        SetEnv = {
          TERM = "xterm-256color";
        };
        AddKeysToAgent = "yes";
      };

      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };

      "ovh_sow" = {
        User = "ubuntu";
        Port = 50340;
        HostName = "51.254.142.98";
        IdentityFile = "~/.ssh/id_ed25519";
      };

      "git-ssh.westgate.pw" = {
        HostName = "git-ssh.westgate.pw";
        Port = 2222;
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
    };
  };

  home.persistence."/nix/persist" = {
    directories = [
      ".ssh"
    ];
  };
}
