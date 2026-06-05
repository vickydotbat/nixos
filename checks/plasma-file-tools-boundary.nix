{
  inputs,
  pkgs,
}:

let
  lib = inputs.nixpkgs.lib;
  config = inputs.self.nixosConfigurations.solanine.config;

  hasPname =
    name: packages:
    builtins.any (pkg: (pkg.pname or "") == name || lib.hasPrefix "${name}-" (pkg.name or "")) packages;
in
assert hasPname "kfind" config.environment.systemPackages;
assert hasPname "krename" config.environment.systemPackages;
pkgs.runCommand "plasma-file-tools-boundary" { } ''
  touch "$out"
''
