# blender-mcp-nwn

Local MCP server that lets Claude drive **Blender 4.0.2** (your `blender-402-bin`
pin, reused via the repo overlay) for NWN:EE tileset work. Blender runs headless;
scripts execute in Blender's own `bpy` interpreter.

## Tools

| Tool | Purpose |
|------|---------|
| `run_blender_script(script_path, blend_file?)` | Run a `bpy` Python script (optionally opening a `.blend` first). |
| `read_blend_metadata(file_path)` | Objects, meshes (vert/poly counts, materials), materials. |
| `export_for_nwn(blend_file, output_path)` | Export Z-up/Y-forward, metric, triangulated (`.obj` or `.fbx`) + a `<output>.mdl.json` MDL config sidecar. |

## Build & test

```sh
nix build /nix/nixos/blender-mcp-nwn            # realise the server + Blender 4.0.2
nix develop /nix/nixos/blender-mcp-nwn -c python /nix/nixos/blender-mcp-nwn/test_setup.py
```

The test builds a cube, reads its metadata, and exports it — proving the whole path.

## Claude Desktop config

Linux config lives at `~/.config/Claude/claude_desktop_config.json`. Point it at
the built binary (most robust — no eval/network at Claude startup):

```json
{
  "mcpServers": {
    "blender-nwn": {
      "command": "/nix/nixos/blender-mcp-nwn/result/bin/blender-mcp-nwn"
    }
  }
}
```

Alternative (rebuilds on demand, needs `nix` on Claude's PATH + flakes enabled):

```json
{
  "mcpServers": {
    "blender-nwn": {
      "command": "nix",
      "args": ["run", "/nix/nixos/blender-mcp-nwn"]
    }
  }
}
```

Restart Claude Desktop after editing. Override `BLENDER_BIN` / `BLENDER_TIMEOUT`
via an `"env": { ... }` block if needed.

## Notes / limits

- **MDL export**: `export_for_nwn` writes NWN-friendly geometry + an MDL *config*
  sidecar, not a binary `.mdl`. True Blender→MDL needs the
  [neverblender](https://github.com/Neverblender/neverblender) addon installed
  into this Blender 4.0. Once installed, extend `_export_script` to call its
  `export_scene.nwn_mdl` operator. For ASCII-MDL post-processing you already have
  `cleanmodels` and `neverwinter-nim` on PATH in the dev shell.
- Blender **4.0.2**, not nixpkgs' 5.x — neverblender/NWN tooling tracks 4.0.
- The host Python env has no `bpy` (it lives inside Blender); it has `mcp` and,
  because it was requested, `anthropic` (unused by the server itself).
