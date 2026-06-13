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

    "ovh-main" = {
      HostName = "51.254.142.98";
      Port = 2222;
      User = "sow-deploy";
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = "yes";
      StrictHostKeyChecking = "accept-new";
    };

    "git.westgate.pw" = {
      HostName = "git.westgate.pw";
      AddressFamily = "inet6";
      Port = 22;
      User = "git";
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = true;
      ConnectTimeout = 8;
    };
  };
}
