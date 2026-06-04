{
  inputs,
  pkgs,
}:

let
  inherit (pkgs) lib;
  config = inputs.self.nixosConfigurations.firelink.config;
  mattiaHome = config.home-manager.users.mattia;
  autostartText = mattiaHome.xdg.configFile."autostart/discord.desktop".text;
in
assert lib.elem "discord" config.theorem.nixos.base.nix.unfreePackageNames;
assert mattiaHome.programs.discord.enable;
assert lib.hasInfix "/bin/discord --start-minimized" autostartText;
pkgs.runCommand "firelink-discord-boundary" { } ''
  touch "$out"
''
