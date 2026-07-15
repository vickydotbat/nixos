{
  config,
  lib,
  options,
  pkgs,
  ...
}:

# ComfyUI, run as a rootless Podman container rather than a Nix package.
# ComfyUI and its custom-node ecosystem move too fast to package durably,
# and nixpkgs carries no derivation for it. The container keeps that churn
# out of the system closure; the only host requirements are Podman and
# readable /dev/kfd + /dev/dri render nodes (world-rw on our AMD hosts).
#
# Deliberately no systemd unit and no activation hook: image pulls are
# heavyweight and this is an on-demand tool. Start it by hand with
# `comfyui`, stop it with Ctrl+C. See NEVER_DO_THIS.md.

let
  cfg = config.theorem.home.agents.comfyui;
  hasHomePersistence = options.home ? persistence;

  launcher = pkgs.writeShellApplication {
    name = "comfyui";
    text = ''
      mkdir -p "$HOME/${cfg.dataDir}"
      exec podman run --rm -it \
        --name comfyui \
        --device /dev/kfd \
        --device /dev/dri \
        --group-add keep-groups \
        --security-opt seccomp=unconfined \
        -e HSA_OVERRIDE_GFX_VERSION=${cfg.hsaOverride} \
        -e CLI_ARGS="${cfg.cliArgs}" \
        -p ${toString cfg.port}:8188 \
        -v "$HOME/${cfg.dataDir}":/root \
        ${cfg.image} "$@"
    '';
  };
in
{
  options.theorem.home.agents.comfyui = {
    enable = lib.mkEnableOption "ComfyUI (rootless Podman, ROCm)";

    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/yanwk/comfyui-boot:rocm";
      description = ''
        Container image to run. The default is the maintained ROCm build of
        comfyui-boot; it stores everything (ComfyUI tree, models, outputs)
        under the volume mounted at /root.
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "ComfyUI";
      description = ''
        Directory under $HOME mounted at /root inside the container.
        Models live in <dataDir>/ComfyUI/models, outputs in
        <dataDir>/ComfyUI/output. Expect tens of gigabytes once models land.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8188;
      description = "Host port for the ComfyUI web interface.";
    };

    hsaOverride = lib.mkOption {
      type = lib.types.str;
      default = "11.0.0";
      description = ''
        HSA_OVERRIDE_GFX_VERSION handed to ROCm. RDNA3 consumer cards
        (RX 7600, gfx1102) sometimes ship ahead of the ROCm support matrix;
        11.0.0 makes them report as gfx1100, which works. Set to the real
        version if a future ROCm supports the card natively.
      '';
    };

    cliArgs = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "--lowvram";
      description = ''
        Extra arguments passed to ComfyUI inside the container. Reach for
        --lowvram if 8 GB of VRAM proves too tight for a chosen model.
      '';
    };

    persist = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Persist the data directory when home.persistence is available.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [ launcher ];
    })

    (lib.mkIf (cfg.enable && cfg.persist && hasHomePersistence) {
      home.persistence."/nix/persist" = {
        directories = [
          cfg.dataDir
        ];
      };
    })
  ];
}
