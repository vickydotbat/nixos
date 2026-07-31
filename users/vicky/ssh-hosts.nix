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

    # Household machines, reachable by DHCP reservation. Both hosts authorize
    # this same key for `vicky`, so these work in either direction. Host key
    # checking is left at its default: once each host's OpenSSH keys are stored
    # in `secrets/hosts-<host>.yaml` they survive reboots, and a changed key
    # should be a question rather than something accepted silently.
    "solanine" = {
      HostName = "192.168.1.62";
      User = "vicky";
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = true;
    };

    "saturnine" = {
      HostName = "192.168.1.8";
      User = "vicky";
      IdentityFile = "~/.ssh/id_ed25519";
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

    "netcup-game" = {
      HostName = "152.53.92.154";
      Port = 2222;
      User = "sow-deploy";
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = "yes";
      StrictHostKeyChecking = "accept-new";
    };

    "git.westgate.pw" = {
      HostName = "git.westgate.pw";
      Port = 22;
      User = "git";
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = true;
      ConnectTimeout = 8;
    };
  };
}
