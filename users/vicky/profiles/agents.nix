{
  theorem.home.agents = {
    ollama = {
      enable = true;
      acceleration = "rocm";
      host = "0.0.0.0";
    };

    # ComfyUI runs as an on-demand rootless Podman container; start it with
    # `comfyui`, browse to http://127.0.0.1:8188. First run pulls the image.
    comfyui.enable = true;

    # opencode.enable = true;
    pi.enable = true;
    omp.enable = true;
    codex.enable = true;
    claude.enable = true;
    codegraph.enable = true;
    mattSkills.enable = true;
  };
}
