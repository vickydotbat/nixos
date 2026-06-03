{ config, lib, ... }:
# TODO: Networkmanager is an opinionated default but most systems need internet. Rethink this for host-to-host configuration and allow different options.
# TODO: Also add declarative wifi/networks on either the host side or the user side, whichever is deemed more flexible. Example: letting me specify my home wifi on all my systems so it always knows where it is and connects automatically without entering a password (because we save the password in sops secrets, maybe?)
let
  cfg = config.theorem.nixos.base.networking;
in
{
  options.theorem.nixos.base.networking.enable = lib.mkEnableOption "base networking configuration";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
  };
}
