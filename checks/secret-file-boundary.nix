{
  inputs,
  pkgs,
}:

let
  inherit (pkgs) lib;
  solanine = inputs.self.nixosConfigurations.solanine.config;
  firelink = inputs.self.nixosConfigurations.firelink.config;
  sopsRules = builtins.readFile ../.sops.yaml;
  solanineSecretsModule = builtins.readFile ../hosts/solanine/secrets.nix;
  firelinkSecretsModule = builtins.readFile ../hosts/firelink/secrets.nix;
  firefoxBackupModule = builtins.readFile ../modules/home/web/firefox-backup.nix;
  adminUserModule = builtins.readFile ../users/admin/default.nix;
  vickyUserModule = builtins.readFile ../users/vicky/default.nix;
  mattiaUserModule = builtins.readFile ../users/mattia/default.nix;

  hasRule = pattern: lib.hasInfix pattern sopsRules;
  hasSource = needle: source: lib.hasInfix needle source;
  solanineSecretNames = builtins.attrNames solanine.sops.secrets;
  firelinkSecretNames = builtins.attrNames firelink.sops.secrets;
in
assert hasRule "secrets/users-admin\\.yaml$";
assert hasRule "secrets/users-vicky\\.yaml$";
assert hasRule "secrets/users-mattia\\.yaml$";
assert hasRule "secrets/hosts-solanine\\.yaml$";
assert hasRule "secrets/hosts-firelink\\.yaml$";
assert !(hasRule "secrets/solanine\\.yaml$");
assert !(hasRule "secrets/firelink\\.yaml$");
assert !(hasRule "secrets/ssh-admin\\.yaml$");
assert !(hasRule "secrets/ssh-vicky\\.yaml$");
assert !(hasRule "secrets/ssh-mattia\\.yaml$");
assert hasSource "accountSecretsFile = ../../secrets/users-" adminUserModule;
assert hasSource "accountSecretsFile = ../../secrets/users-" vickyUserModule;
assert hasSource "accountSecretsFile = ../../secrets/users-" mattiaUserModule;
assert !(hasSource "../../secrets/ssh-" adminUserModule);
assert !(hasSource "../../secrets/ssh-" vickyUserModule);
assert !(hasSource "../../secrets/ssh-" mattiaUserModule);
assert hasSource "hostSecretsFile = ../../secrets/hosts-solanine.yaml;" solanineSecretsModule;
assert hasSource "hostSecretsFile = ../../secrets/hosts-firelink.yaml;" firelinkSecretsModule;
assert !(hasSource "../../secrets/solanine.yaml" solanineSecretsModule);
assert !(hasSource "../../secrets/firelink.yaml" firelinkSecretsModule);
assert hasSource "firefox-backup/" solanineSecretsModule;
assert hasSource "/age-identity" solanineSecretsModule;
assert hasSource "firefox-backup/" firelinkSecretsModule;
assert hasSource "/age-identity" firelinkSecretsModule;
assert hasSource ''key = "firefox-backup-age-identity";'' solanineSecretsModule;
assert hasSource ''key = "firefox-backup-age-identity";'' firelinkSecretsModule;
assert !(hasSource "firefox-backup-age-recipients" solanineSecretsModule);
assert !(hasSource "firefox-backup-age-recipients" firelinkSecretsModule);
assert hasSource "firefox-backup-" firefoxBackupModule;
assert hasSource "-age-identity" firefoxBackupModule;
assert !(hasSource "-age-recipients" firefoxBackupModule);
assert !(hasSource "age_args=(" firefoxBackupModule);
assert !(hasSource "age_args[@]" firefoxBackupModule);
assert lib.elem "users/admin/password-hash" solanineSecretNames;
assert lib.elem "users/vicky/password-hash" solanineSecretNames;
assert lib.elem "users/admin/password-hash" firelinkSecretNames;
assert lib.elem "users/mattia/password-hash" firelinkSecretNames;
pkgs.runCommand "secret-file-boundary" { } ''
  touch "$out"
''
