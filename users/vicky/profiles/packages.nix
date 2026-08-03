{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Shrink a Spectacle screencast until Discord accepts it. Discord's free
  # upload limit is 10 MiB, so aim a little under and let the video bitrate be
  # whatever is left after the audio track: bitrate = budget / duration.
  #
  # Two passes, because a one-pass VP9 encode misses a size target badly on
  # clips whose motion is uneven, and missing the target means re-uploading.
  discordify = pkgs.writeShellApplication {
    name = "discordify";

    runtimeInputs = [ pkgs.ffmpeg ];

    text = ''
      if [ $# -lt 1 ]; then
        echo "usage: discordify <video> [output.webm]" >&2
        echo "  DISCORD_MIB=9   size budget, mebibytes" >&2
        echo "  MAX_HEIGHT=720  downscale taller videos to this" >&2
        exit 2
      fi

      input="$1"
      output="''${2:-''${1%.*}.discord.webm}"
      budget_mib="''${DISCORD_MIB:-9}"
      max_height="''${MAX_HEIGHT:-720}"
      audio_bitrate=64000

      duration="$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$input")"
      # Round the duration up: a slightly long estimate lowers the bitrate,
      # which undershoots the budget instead of overshooting it.
      seconds=$(( ''${duration%.*} + 1 ))

      video_bitrate=$(( budget_mib * 1024 * 1024 * 8 / seconds - audio_bitrate ))
      if [ "$video_bitrate" -lt 100000 ]; then
        echo "discordify: $seconds s is too long for ''${budget_mib} MiB; raise DISCORD_MIB or trim the clip" >&2
        exit 1
      fi

      passlog="$(mktemp -d)/vp9"
      trap 'rm -rf -- "$(dirname "$passlog")"' EXIT

      common=(
        -i "$input"
        -vf "scale=-2:'min($max_height,ih)'"
        -c:v libvpx-vp9 -b:v "$video_bitrate"
        -row-mt 1 -deadline good -cpu-used 2
        -passlogfile "$passlog"
      )

      ffmpeg -hide_banner -loglevel warning -y "''${common[@]}" -pass 1 -an -f webm /dev/null
      ffmpeg -hide_banner -loglevel warning -stats -y "''${common[@]}" -pass 2 \
        -c:a libopus -b:a "$audio_bitrate" "$output"

      ls -lh -- "$output"
    '';
  };
in
{
  home.packages = with pkgs; [
    sillytavern
    libreoffice

    discordify
    ffmpeg
  ];

  home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
    directories = [
      ".local/share/SillyTavern"
    ];
  };
}
