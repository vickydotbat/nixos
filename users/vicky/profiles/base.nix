{
  theorem.home.base = {
    distrobox.enable = true;
    ssh.enable = true;
    ollama = {
      enable = true;
      acceleration = "rocm";
      host = "0.0.0.0";
    };
  };
}
