{ ... }:

{
  programs.helix = {
    enable = true;

    settings = {
      theme = "catppuccin_mocha";

      editor = {
        line-number = "relative";
        mouse = true;
        cursorline = true;
        bufferline = "multiple";
        color-modes = true;
        true-color = true;

        indent-guides = {
          render = true;
        };

        soft-wrap = {
          enable = true;
        };
      };

      keys.normal = {
        space.w = ":write";
        space.q = ":quit";
        space.x = ":buffer-close";
      };
    };
  };
}
