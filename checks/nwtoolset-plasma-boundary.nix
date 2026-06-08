{
  inputs,
  pkgs,
}:

let
  inherit (pkgs) lib;
  system = pkgs.stdenv.hostPlatform.system;

  solanineHome = inputs.self.nixosConfigurations.solanine.config.home-manager.users.vicky;

  localPkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "nwtoolset" ];
    overlays = [
      inputs.self.overlays.default
      inputs.nur.overlays.default
    ];
  };

  noPlasmaHome =
    (inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = localPkgs;
      modules = [
        inputs.self.homeModules.shared
        {
          home = {
            username = "boundary";
            homeDirectory = "/tmp/home-boundary";
            stateVersion = "25.11";
            enableNixpkgsReleaseCheck = false;
          };

          programs.home-manager.enable = false;

          theorem.home = {
            desktop.plasma.enable = false;
            gaming.nwn.enable = true;
          };
        }
      ];
    }).config;

  hasNwtoolsetRule =
    rules:
    lib.any (
      rule:
      rule.description == "NWToolset Plasma window integration"
      && rule.match.window-class.value == "nwtoolset.exe"
      && rule.match.window-class.type == "exact"
      && rule.match.window-types == 1
      && rule.apply.skiptaskbar.value == false
      && rule.apply.skiptaskbar.apply == "force"
      && rule.apply.skippager.value == false
      && rule.apply.skippager.apply == "force"
    ) rules;

  solanineDesktopEntry = solanineHome.xdg.dataFile."applications/nwtoolset.desktop".text;
in
assert solanineHome.theorem.home.desktop.plasma.enable;
assert solanineHome.theorem.home.gaming.nwn.enable;
assert hasNwtoolsetRule solanineHome.programs.plasma.window-rules;
assert lib.hasInfix "StartupWMClass=nwtoolset.exe" solanineDesktopEntry;
assert !noPlasmaHome.theorem.home.desktop.plasma.enable;
assert !(noPlasmaHome.programs ? plasma);
assert !(noPlasmaHome.xdg.dataFile ? "applications/nwtoolset.desktop");
pkgs.runCommand "nwtoolset-plasma-boundary" { } ''
  touch "$out"
''
