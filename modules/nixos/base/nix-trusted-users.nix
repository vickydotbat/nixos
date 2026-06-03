{
  config,
  lib,
  repository,
  ...
}:

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
