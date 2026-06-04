{
  config,
  lib,
  repository,
  selectedUsers,
  ...
}:
# Base NetworkManager posture. Enabling the module starts NetworkManager and
# grants its control group only to selected repository stewards, so network
# repair remains available to maintainers without turning every local account
# into a network operator.
let
  cfg = config.theorem.nixos.base.networking;
  repositoryGroup = repository.group or "nixcfg";

  isRepositoryUser =
    _name: user:
    (user.group or null) == repositoryGroup || lib.elem repositoryGroup (user.extraGroups or [ ]);

  # Network control is an installed-system usability group. By doctrine, grant
  # it to repository stewards, including admin, and not to guest accounts unless
  # a host makes that broader access explicit elsewhere.
  networkManagerUsers = lib.attrNames (lib.filterAttrs isRepositoryUser selectedUsers);
in
{
  options.theorem.nixos.base.networking.enable =
    lib.mkEnableOption "base NetworkManager configuration";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;

    users.users = lib.genAttrs networkManagerUsers (_: {
      extraGroups = lib.mkAfter [ "networkmanager" ];
    });
  };
}
