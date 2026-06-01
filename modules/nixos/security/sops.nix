{ pkgs, lib, ... }:

let
  secretsFile = ../../../secrets/solanine.yaml;
  vickySshSecretsFile = ../../../secrets/ssh-vicky.yaml;
in
{
  sops.age.keyFile = "/nix/persist/secrets/sops/age/keys.txt";
  sops.defaultSopsFormat = "yaml";

  sops.defaultSopsFile = lib.mkIf (builtins.pathExists secretsFile) secretsFile;

  environment.systemPackages = [ pkgs.sops pkgs.age ];

  sops.secrets =
    (lib.optionalAttrs (builtins.pathExists secretsFile) {
      firefox-backup-age-identity = {
        owner = "vicky";
        mode = "0400";
      };
    })
    // (lib.optionalAttrs (builtins.pathExists vickySshSecretsFile) {
      "ssh/vicky/id_ed25519" = {
        sopsFile = vickySshSecretsFile;
        path = "/run/secrets/ssh-vicky-id_ed25519";
        owner = "vicky";
        group = "users";
        mode = "0600";
      };

      "ssh/vicky/id_ed25519.pub" = {
        sopsFile = vickySshSecretsFile;
        path = "/run/secrets/ssh-vicky-id_ed25519.pub";
        owner = "vicky";
        group = "users";
        mode = "0644";
      };
    });
}
