{
  config,
  lib,
  repository,
  ...
}:

# Derive Nix daemon trusted users from repository stewardship. Anyone trusted to
# maintain `/nix/nixos` may need to build, substitute, and repair the theorem;
# outside accounts should not gain daemon trust merely by existing on the host.
let
  repositoryGroup = repository.group or "nixcfg";

  hasRepositoryGroup =
    _name: user:
    (user.group or null) == repositoryGroup || lib.elem repositoryGroup (user.extraGroups or [ ]);

  repositoryUsers = lib.attrNames (lib.filterAttrs hasRepositoryGroup config.users.users);
  repositoryGroupMembers = config.users.groups.${repositoryGroup}.members or [ ];
in
{
  config = {
    nix.settings.trusted-users = lib.mkAfter (lib.unique (repositoryUsers ++ repositoryGroupMembers));
  };
}
