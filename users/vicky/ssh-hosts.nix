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
      Port = 2222;
      HostName = "51.254.142.98";
    };

    "git.westgate.pw" = {
      HostName = "git.westgate.pw";
      Port = 22;
      User = "git";
      IdentitiesOnly = true;
    };
  };
}
