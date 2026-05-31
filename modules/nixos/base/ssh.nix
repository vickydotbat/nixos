{
  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
      UseDns = false;
    };

    openFirewall = true;
  };

  programs.ssh.startAgent = true;
}
