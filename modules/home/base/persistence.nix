{
  config,
  lib,
  options,
  osConfig ? null,
  ...
}:
# Home Manager persistence baseline for impermanent hosts. It follows the
# system persistence substrate by default, but individual users can opt out when
# their home should stay ephemeral. The volatile Downloads service keeps casual
# downloads boot-scoped while preserving the declared working directories.
let
  cfg = config.theorem.home.base.persistence;
  hasHomePersistence = options.home ? persistence;

  systemPersistenceEnabled =
    if osConfig == null then false else osConfig.theorem.nixos.base.persistence.enable or false;
in
{
  options.theorem.home.base.persistence = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = systemPersistenceEnabled;
      defaultText = lib.literalExpression ''
        if osConfig == null
        then false
        else osConfig.theorem.nixos.base.persistence.enable or false
      '';
      description = ''
        Enable Home Manager persistence. Defaults to the system persistence
        theorem so user bind mounts are only declared when the persistence
        substrate exists.
      '';
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.enable || hasHomePersistence;
          message = ''
            theorem.home.base.persistence.enable requires the Home persistence
            option provider. Import the Impermanence Home Manager module through
            the NixOS persistence substrate before enabling this theorem.
          '';
        }
      ];
    }
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf cfg.enable {
        directories = [
          ".local/share/systemd/timers"
          ".local/share/nix"

          # XDG Directories
          "Documents"
          "Pictures"
          "Videos"
          "Projects"
          "Music"
          "Templates"
          "Public"
          "Desktop"

          # Additional global directories
          "Games"
          "Applications"
          "Backups"
          "Repositories"
        ];
      };

    })
  ];
}
