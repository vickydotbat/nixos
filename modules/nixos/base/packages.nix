{
  config,
  lib,
  pkgs,
  ...
}:
/*
  NOTE: This is for packages that every system should realistically have. We're talking stuff like:
  - Core utilities every system needs regardless of hardware setup.
  - Things you'd tear your hair out over if you needed it in a pinch and it wasn't available.
  - Anything that frequently gets activated on the vast majority of packages too.
  - Git is a great example, Nano is always a good fallback editor. I threw in vim just in case someone likes vim more.
*/
let
  cfg = config.theorem.nixos.base.packages;
in
{
  options.theorem.nixos.base.packages.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Install the small base package set expected on every maintained host.
      Disable only for deliberately austere images.
    '';
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      nano
      vim
      unzip
      zip
    ];
  };
}
