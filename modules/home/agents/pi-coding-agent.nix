{
  config,
  lib,
  options,
  ...
}:

let
  cfg = config.theorem.home.agents.pi;
  hasHomePersistence = options.home ? persistence;
in
{
  options.theorem.home.agents.pi = {
    enable = lib.mkEnableOption "Pi Coding Agent";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.pi.coding-agent = {
        enable = true;
      };
    })

    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = {
        directories = [
          ".pi"
        ];
      };
    })
  ];
}
