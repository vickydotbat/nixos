{
  inputs,
  pkgs,
}:

let
  lib = inputs.nixpkgs.lib;
  solanine = inputs.self.nixosConfigurations.solanine;
  config = solanine.config;
  extensions = config.home-manager.users.vicky.programs.vscode.profiles.default.extensions;
  settings = config.home-manager.users.vicky.programs.vscode.profiles.default.userSettings;

  hasPname =
    name: packages:
    builtins.any (pkg: (pkg.pname or "") == name || lib.hasPrefix "${name}-" (pkg.name or "")) packages;
in
assert hasPname "vscode-extension-catppuccin-catppuccin-vsc" extensions;
assert settings."window.autoDetectColorScheme";
assert settings."workbench.colorTheme" == "Catppuccin Mocha";
assert settings."workbench.preferredLightColorTheme" == "Catppuccin Latte";
assert settings."workbench.preferredDarkColorTheme" == "Catppuccin Mocha";
pkgs.runCommand "vicky-vscode-theme-boundary" { } ''
  touch "$out"
''
