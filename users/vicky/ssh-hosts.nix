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

    # Household machines, now reached over the tailnet rather than by DHCP
    # reservation. No `HostName` is given on purpose: the alias resolves
    # through Tailscale's MagicDNS, so the same entry works from the sofa and
    # from a phone on mobile data, and no LAN address goes stale here when the
    # router hands out something new. Both hosts authorize this same key for
    # `vicky`, so these work in either direction.
    #
    # The consequence to know: these aliases need Tailscale up on both ends.
    # The hosts no longer accept SSH on the local network, so there is no LAN
    # fallback if the tailnet is down. The fallback is a keyboard.
    #
    # Host key checking is left at its default: once each host's OpenSSH keys
    # are stored in `secrets/hosts-<host>.yaml` they survive reboots, and a
    # changed key should be a question rather than something accepted silently.
    "solanine" = {
      User = "vicky";
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = true;
    };

    "saturnine" = {
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
