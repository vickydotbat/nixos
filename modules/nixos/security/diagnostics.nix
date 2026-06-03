{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.theorem.nixos.security.diagnostics;

  packageNames = {
    systemAudit = [ "lynis" ];
    kernelAudit = [ "kernel-hardening-checker" ];
    fileIntegrity = [ "aide" ];
    malwareScan = [ "clamav" ];
    vulnerabilityScan = [
      "sbomnix"
      "grype"
    ];
  };

  packageFor = name: lib.attrByPath [ name ] null pkgs;
  packageExists = name: packageFor name != null;
  packagesFor = names: map packageFor (lib.filter packageExists names);

  selectedPackageNames =
    lib.optionals cfg.systemAudit.enable packageNames.systemAudit
    ++ lib.optionals cfg.kernelAudit.enable packageNames.kernelAudit
    ++ lib.optionals cfg.fileIntegrity.enable packageNames.fileIntegrity
    ++ lib.optionals cfg.malwareScan.enable packageNames.malwareScan
    ++ lib.optionals cfg.vulnerabilityScan.enable packageNames.vulnerabilityScan;

  missingPackageNames = lib.filter (name: !packageExists name) selectedPackageNames;
in
{
  options.theorem.nixos.security.diagnostics = {
    enable = lib.mkEnableOption "optional hardening diagnostics tool profile";

    systemAudit.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install general host audit tooling such as Lynis when diagnostics are
        enabled. This is a manual inspection aid, not a daemon and not a proof
        that the host is hardened.
      '';
    };

    kernelAudit.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install kernel-hardening-checker for manual comparison of kernel config,
        command-line parameters, and sysctl posture. This is an inspection tool,
        not an automatic hardening mechanism.
      '';
    };

    fileIntegrity.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install AIDE tooling for file-integrity experiments. Enabling the tool
        does not initialize a database or schedule checks; those rites need a
        separate module once persistence and update handling are designed.
      '';
    };

    malwareScan.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install ClamAV command-line tooling for manual scans. This deliberately
        does not enable the ClamAV daemon, updater, or scheduled scans.
      '';
    };

    vulnerabilityScan.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install SBOM and vulnerability scan tooling, when available in nixpkgs.
        These tools are for maintenance runs against a selected closure such as
        `/run/current-system`.
      '';
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        Additional diagnostics packages to install with this profile. Use this
        for host-local probes while keeping the common profile small.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = packagesFor selectedPackageNames ++ cfg.extraPackages;

    warnings = lib.optionals (missingPackageNames != [ ]) [
      ''
        theorem.nixos.security.diagnostics requested packages unavailable in
        this nixpkgs: ${lib.concatStringsSep ", " missingPackageNames}
      ''
    ];
  };
}
