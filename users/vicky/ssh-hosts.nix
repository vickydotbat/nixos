{
  programs.ssh.settings = {
    "*" = {
      IdentityFile = "~/.ssh/id_ed25519";
      SetEnv = {
        TERM = "xterm-256color";
      };
      AddKeysToAgent = "yes";
    };

    "github.com" = {
      User = "git";
      IdentitiesOnly = true;
    };

    "ovh_sow" = {
      User = "ubuntu";
      HostName = "51.254.142.98";
    };

    "git-ssh.westgate.pw" = {
      HostName = "git-ssh.westgate.pw";
      Port = 2222;
      User = "git";
      IdentitiesOnly = true;
    };
  };
}
