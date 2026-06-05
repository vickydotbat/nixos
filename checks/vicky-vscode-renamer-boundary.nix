{
  inputs,
  pkgs,
}:

let
  lib = inputs.nixpkgs.lib;
  solanine = inputs.self.nixosConfigurations.solanine;
  config = solanine.config;
  systemPkgs = solanine.pkgs;
  extensions = config.home-manager.users.vicky.programs.vscode.profiles.default.extensions;

  hasPname =
    name: packages:
    builtins.any (pkg: (pkg.pname or "") == name || lib.hasPrefix "${name}-" (pkg.name or "")) packages;
in
assert systemPkgs.vscode-extensions ? evertjunior;
assert systemPkgs.vscode-extensions.evertjunior ? mass-renamer;
assert hasPname "vscode-extension-evertjunior-mass-renamer" extensions;
pkgs.runCommand "vicky-vscode-renamer-boundary" { } ''
  touch "$out"
''
