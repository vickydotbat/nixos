{
  inputs,
  pkgs,
}:

let
  lib = inputs.nixpkgs.lib;
  solanine = inputs.self.nixosConfigurations.solanine;
  enabledConfig = solanine.config;
  disabledConfig =
    (solanine.extendModules {
      modules = [
        {
          theorem.nixos.desktop.plasma.browserIntegration.enable = false;
        }
      ];
    }).config;

  hasPname =
    name: packages:
    builtins.any (pkg: (pkg.pname or "") == name || lib.hasPrefix "${name}-" (pkg.name or "")) packages;

  firefoxExtensions =
    config: config.home-manager.users.vicky.programs.firefox.profiles.vicky.extensions.packages;
in
assert enabledConfig.theorem.nixos.desktop.plasma.browserIntegration.enable;
assert hasPname "plasma-browser-integration" enabledConfig.environment.systemPackages;
assert hasPname "plasma-integration" (firefoxExtensions enabledConfig);
assert hasPname "plasma-browser-integration" disabledConfig.environment.plasma6.excludePackages;
assert !(hasPname "plasma-integration" (firefoxExtensions disabledConfig));
pkgs.runCommand "plasma-browser-boundary" { } ''
  touch "$out"
''
