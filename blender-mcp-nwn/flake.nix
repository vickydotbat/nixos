{
  description = "Local MCP server bridging Claude and Blender 4.0.2 for NWN:EE tileset work";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Reuse this machine's pinned Blender 4.0.2 + NWN toolchain via the repo's
    # overlay (blender-402-bin, neverwinter-nim, cleanmodels, ...) instead of
    # re-pinning them here. NWN modelling needs Blender 4.0.x — nixpkgs ships 5.x.
    theorem.url = "git+file:///nix/nixos";
  };

  outputs =
    {
      self,
      nixpkgs,
      theorem,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ theorem.overlays.default ];
      };

      blender = pkgs.blender-501-bin; # /bin/blender-5.0.1 (via lib.getExe)
      # bpy lives *inside* Blender; the host env only needs the MCP transport.
      # anthropic is here because you asked for it — the server doesn't import it.
      pyenv = pkgs.python3.withPackages (ps: [
        ps.mcp
        ps.anthropic
      ]);

      runtimeInputs = [
        blender
        pyenv
        pkgs.neverwinter-nim
        pkgs.cleanmodels
      ];

      server = pkgs.writeShellApplication {
        name = "blender-mcp-nwn";
        inherit runtimeInputs;
        text = ''
          export BLENDER_BIN=${pkgs.lib.getExe blender}
          exec ${pyenv}/bin/python ${./mcp_server.py} "$@"
        '';
      };
    in
    {
      packages.${system}.default = server;

      apps.${system}.default = {
        type = "app";
        program = "${server}/bin/blender-mcp-nwn";
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = runtimeInputs;
        shellHook = ''
          export BLENDER_BIN=${pkgs.lib.getExe blender}
          echo "blender-mcp-nwn dev shell — BLENDER_BIN=$BLENDER_BIN" >&2
        '';
      };
    };
}
