{ config, lib, ... }:
# Polkit is an authorization substrate, not a general desktop decoration.
# Plasma needs it for ordinary privileged desktop actions, while run0 enables
# it separately for administrative elevation. Keep new dependencies explicit so
# this service does not become ambient privilege by accident.
let
  cfg = config.theorem.nixos.security.polkit;
in
{
  options.theorem.nixos.security.polkit.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.theorem.nixos.desktop.plasma.enable;
    defaultText = lib.literalExpression "theorem.nixos.desktop.plasma.enable";
    description = "Enable Polkit authorization support with the Plasma desktop profile by default.";
  };

  config = lib.mkIf cfg.enable {
    security.polkit.enable = true;
  };
}
