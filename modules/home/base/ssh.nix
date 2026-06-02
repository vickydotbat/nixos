{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.base.ssh;
in
{
  options.theorem.home.base.ssh.enable = lib.mkEnableOption "SSH client configuration";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/ssh.nix args);
}
