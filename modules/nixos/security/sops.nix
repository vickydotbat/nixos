{ pkgs, lib, ... }:

let
  sopsAgeKeyFile = "/nix/persist/secrets/sops/age/keys.txt";
  secretsFile = ../../../secrets/solanine.yaml;
  vickySshSecretsFile = ../../../secrets/ssh-vicky.yaml;
  hostSshSecretsAvailable =
    builtins.pathExists secretsFile && lib.hasInfix "\nssh:" (builtins.readFile secretsFile);
in
{
  sops.age.keyFile = sopsAgeKeyFile;
  sops.defaultSopsFormat = "yaml";

  sops.defaultSopsFile = lib.mkIf (builtins.pathExists secretsFile) secretsFile;

  environment.sessionVariables.SOPS_AGE_KEY_FILE = sopsAgeKeyFile;
  environment.systemPackages = [ pkgs.sops pkgs.age ];

  security.sudo.extraConfig = ''
    Defaults env_keep += "SOPS_AGE_KEY_FILE"
  '';

  sops.secrets =
    (lib.optionalAttrs (builtins.pathExists secretsFile) {
      firefox-backup-age-identity = {
        owner = "vicky";
        mode = "0400";
      };
    })
    // (lib.optionalAttrs hostSshSecretsAvailable {
      "ssh/host/ssh_host_ed25519_key" = {
        path = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
        owner = "root";
        group = "root";
        mode = "0600";
      };

      "ssh/host/ssh_host_ed25519_key.pub" = {
        path = "/nix/persist/etc/ssh/ssh_host_ed25519_key.pub";
        owner = "root";
        group = "root";
        mode = "0644";
      };

      "ssh/host/ssh_host_rsa_key" = {
        path = "/nix/persist/etc/ssh/ssh_host_rsa_key";
        owner = "root";
        group = "root";
        mode = "0600";
      };

      "ssh/host/ssh_host_rsa_key.pub" = {
        path = "/nix/persist/etc/ssh/ssh_host_rsa_key.pub";
        owner = "root";
        group = "root";
        mode = "0644";
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
