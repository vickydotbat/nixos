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

  # The pre-shared key never appears in the store: sops renders an environment
  # file at runtime and NetworkManager expands `$HOME_WIFI_PSK` from it while
  # writing the keyfile.
  wifi = cfg.homeWifi;
  wifiSecretName = "wifi/home-env";
in
{
  options.theorem.nixos.base.networking = {
    enable = lib.mkEnableOption "base NetworkManager configuration";

    homeWifi = {
      ssid = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          SSID of the household wireless network. When set, the host joins it
          automatically without anyone typing the password after a reinstall.
          No interface is named, so the profile survives a NIC swap or a USB
          dongle landing on a different port.
        '';
      };

      sopsFile = lib.mkOption {
        type = lib.types.path;
        default = ../../../secrets/wifi-home.yaml;
        description = ''
          SOPS file holding `home-wifi-env`, whose plaintext is a single
          `HOME_WIFI_PSK=<passphrase>` line.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;

    sops.secrets = lib.mkIf (wifi.ssid != null) {
      ${wifiSecretName} = {
        sopsFile = wifi.sopsFile;
        key = "home-wifi-env";
        path = "/run/secrets/wifi-home-env";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

    networking.networkmanager.ensureProfiles = lib.mkIf (wifi.ssid != null) {
      environmentFiles = [ config.sops.secrets.${wifiSecretName}.path ];
      profiles.home-wifi = {
        connection = {
          id = wifi.ssid;
          type = "wifi";
          autoconnect = true;
        };
        wifi = {
          mode = "infrastructure";
          ssid = wifi.ssid;
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$HOME_WIFI_PSK";
        };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };

    users.users = lib.genAttrs networkManagerUsers (_: {
      extraGroups = lib.mkAfter [ "networkmanager" ];
    });
  };
}
