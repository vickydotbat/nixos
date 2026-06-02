{ pkgs, ... }:
{
  programs.zellij = {
    enable = true;

    settings = {
      # Less noisy startup.
      show_startup_tips = false;
      show_release_notes = false;

      # Let Zellij stay passive until explicitly used.
      default_mode = "locked";

      # Minimal UI.
      default_layout = "compact";
      simplified_ui = true;
      pane_frames = false;

      # Mouse and clipboard.
      mouse_mode = true;
      copy_clipboard = "system";
      copy_command = "${pkgs.wl-clipboard}/bin/wl-copy";
      copy_on_select = true;

      # Scrollback.
      scroll_buffer_size = 10000;

      # Sessions.
      session_serialization = true;
      pane_viewport_serialization = true;
      attach_to_session = true;
    };
  };
}
