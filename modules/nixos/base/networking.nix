{ config, lib, ... }:
# TODO: Networkmanager is an opinionated default but most systems need internet. Rethink this for host-to-host configuration and allow different options.
let
  cfg = config.theorem.nixos.base.networking;
in
{
  options.theorem.nixos.base.networking.enable = lib.mkEnableOption "base networking configuration";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
  };
}
