{
  inputs,
  pkgs,
}:

# Synthetic Home Manager profile used as a boundary proof. It imports the
# reusable Home module tree without a NixOS `osConfig` and without any
# `users/vicky` profile, so `nix flake check` can catch shared-module drift into
# one operator's working surface.
(inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;

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
        base = {
          persistence.enable = false;
          ssh.enable = false;
        };

        shell = {
          git.enable = false;
          ripgrep.enable = true;
          shell = {
            enable = true;
            nixosAliases.enable = false;
            elevationAlias.enable = false;
          };
        };
      };
    }
  ];
}).activationPackage
