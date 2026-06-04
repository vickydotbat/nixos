{
  inputs,
  pkgs,
}:

let
  inherit (pkgs) lib;
  solanine = inputs.self.nixosConfigurations.solanine.config;
  firelink = inputs.self.nixosConfigurations.firelink.config;

  solanineAccounts = solanine.theorem.nixos.base.users.accounts;
  firelinkAccounts = firelink.theorem.nixos.base.users.accounts;

  authorizedKeysPath = "/run/ssh-authorized-keys/%u";
in
assert solanine.services.openssh.enable;
assert firelink.services.openssh.enable;
assert lib.elem authorizedKeysPath solanine.services.openssh.authorizedKeysFiles;
assert lib.elem authorizedKeysPath firelink.services.openssh.authorizedKeysFiles;
assert solanineAccounts.admin.sshAuthorizedKeyFiles == [ "/run/secrets/ssh-admin-id_ed25519.pub" ];
assert firelinkAccounts.admin.sshAuthorizedKeyFiles == [ "/run/secrets/ssh-admin-id_ed25519.pub" ];
assert
  solanineAccounts.vicky.sshAuthorizedKeyFiles == [
    "/run/secrets/ssh-vicky-id_ed25519.pub"
    "/run/secrets/ssh-mattia-id_ed25519.pub"
  ];
assert
  firelinkAccounts.mattia.sshAuthorizedKeyFiles == [
    "/run/secrets/ssh-mattia-id_ed25519.pub"
    "/run/secrets/ssh-vicky-id_ed25519.pub"
  ];
assert lib.elem "ssh/mattia/id_ed25519.pub" (builtins.attrNames solanine.sops.secrets);
assert lib.elem "ssh/vicky/id_ed25519.pub" (builtins.attrNames firelink.sops.secrets);
pkgs.runCommand "ssh-approved-hosts-boundary" { } ''
  touch "$out"
''
