{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:

let
  # The V Rising server is a single-machine role, not a hardware capability, so
  # it is chosen by host identity rather than by a `theorem.nixos.*` flag. Only
  # one host may own the world saves at a time; two hosts running the same
  # `saveName` would be two divergent worlds, not a shared one.
  # ponytail: a hostname literal beats a new NixOS option for a single role.
  # Promote to `theorem.nixos.gaming.vrising.enable` if a second role-bearing
  # service needs the same treatment.
  vrisingHost = "saturnine";
  isVrisingHost = osConfig != null && osConfig.networking.hostName == vrisingHost;
in
{
  theorem.home.gaming = {
    nwn.enable = true;
    vrising = {
      enable = isVrisingHost;
      serverName = "VickyKillin's World";
      saveName = "world1";
      maxUsers = 8;
      public = true;
      # Empty preset so the server reads the migrated ServerGameSettings.json
      # (the single-player rules) instead of a canned preset.
      preset = "";

      # RCON exists so the idle-restart guard can ask whether anyone is on.
      # The port stays unpublished (`rconPublish` defaults false), so this is
      # reachable only through `podman exec` on this host. It is world-readable
      # in the Nix store, which is acceptable for something nothing outside the
      # container can connect to; publishing the port would change that.
      rconPassword = "wch3wLeDyve5Lv61uvsG";

      # Twice daily, and only when nobody is on and the world is freshly saved.
      maintenance.enable = true;
    };
    lutris.enable = true;
    mangohud = {
      enable = true;

      # Home Manager only writes ~/.config/MangoHud/MangoHud.conf when `settings`
      # is non-empty, and it writes it as a read-only store symlink. So the
      # moment anything lands here, Nix owns the whole file and Goverlay stops
      # being an editor. That is the trade: Goverlay can still read and preview
      # the HUD, but every future tweak belongs in this attribute set.
      #
      # The values below are the Goverlay 1.8.2 layout, carried over verbatim.
      # `fps_limit` is the one addition. The display is 120 Hz and a cap just
      # under refresh keeps frame pacing even, which matters most for older
      # single-threaded games (TERA is a 2011 Unreal 3 title) where the frame
      # time swings around.
      #
      # ponytail: the global config, not `settingsPerApplication`. A per-app file
      # replaces MangoHud.conf rather than merging with it, so a per-game cap
      # would mean restating the whole layout per game. One cap at refresh rate
      # is the right default for every game here.
      settings = {
        # Appearance + Layout
        background_alpha = 0.0;
        font_scale = 0.65;
        round_corners = 0;
        background_color = "000000";
        text_color = "C0C0C0";
        position = "top-center";
        horizontal = 1;
        hud_compact = 1;
        hud_no_margin = 1;

        # What shows
        ram = 1;
        swap = 1;
        vram = 1;
        ram_temp = 1;
        cpu_temp = 1;
        gpu_list = 0;
        gpu_temp = 1;
        cpu_mhz = 1;

        # FPS
        fps_limit = 118; # TODO: Dynamically generated per-host from current refresh rate.
        fps_limit_method = "late";
        fps_color_change = 1;
        # vsync = 4;

        # Hotkeys
        toggle_hud = "Shift_L+F12";
        toggle_preset = " ";
        toggle_hud_position = " ";
        toggle_fps_limit = " ";
        toggle_logging = " ";

        # Logs
        output_folder = "${config.xdg.dataHome}/goverlay";
        log_duration = 30;
        log_interval = 100;

        # Desktop apps that pick up the Vulkan layer and do not want a HUD.
        blacklist = [
          "zenity"
          "protonplus"
          "lsfg-vk-ui"
          "bazzar"
          "gnome-calculator"
          "pamac-manager"
          "lact"
          "ghb"
          "bitwig-studio"
          "ptyxis"
          "yumex"
        ];
      };
    };
  };

  # Thunderstore mod manager, on both hosts. It is a client-side tool: it
  # installs BepInEx and mods into a Steam game directory
  # (~/.local/share/Steam/steamapps/common/VRising) and knows nothing about the
  # dedicated server container. Server mods are a separate job.
  # ponytail: a package plus its state directory, no module. Promote to
  # `theorem.home.gaming.r2modman` if a second user ever needs it.
  home.packages = [ pkgs.r2modman ];

  # Profiles, downloaded mods and the manager's own settings all live here.
  # The game directory itself is persisted by modules/home/gaming/steam.nix.
  home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
    directories = [ ".config/r2modmanPlus-local" ];
  };
}
