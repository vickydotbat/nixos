{
  theorem.home.base = {
    distrobox.enable = true;
    shared = {
      enable = true;
      # Solanine is the desktop and is awake most of the time, so it holds the
      # real directory; saturnine is a laptop and mounts it.
      host = "solanine";
    };
    ssh.enable = true;
  };
}
