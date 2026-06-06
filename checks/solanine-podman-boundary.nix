{
  inputs,
  pkgs,
}:

let
  inherit (pkgs) lib;
  config = inputs.self.nixosConfigurations.solanine.config;

  expectedRangeForUid = uid: {
    startUid = 100000 + ((uid - 1000) * 65536);
    count = 65536;
  };

  expectedGroupRangeForUid = uid: {
    startGid = 100000 + ((uid - 1000) * 65536);
    count = 65536;
  };

  hasExpectedRanges =
    name:
    let
      user = config.users.users.${name};
    in
    user.subUidRanges == [ (expectedRangeForUid user.uid) ]
    && user.subGidRanges == [ (expectedGroupRangeForUid user.uid) ];
in
assert config.theorem.nixos.virtualisation.podman.enable;
assert config.theorem.nixos.security.run0-sudo.enable;
assert config.virtualisation.podman.enable;
assert config.security.shadow.enable;
assert hasExpectedRanges "admin";
assert hasExpectedRanges "vicky";
assert config.security.wrappers.newuidmap.setuid;
assert config.security.wrappers.newgidmap.setuid;
assert lib.elem pkgs.podman-compose config.virtualisation.podman.extraPackages;
assert !(lib.elem "podman" (config.users.users.admin.extraGroups or [ ]));
assert !(lib.elem "podman" (config.users.users.vicky.extraGroups or [ ]));
pkgs.runCommand "solanine-podman-boundary" { } ''
  touch "$out"
''
