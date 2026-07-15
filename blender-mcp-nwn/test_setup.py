#!/usr/bin/env python3
"""End-to-end check: builds a cube .blend, reads its metadata, exports for NWN.

Run inside the dev shell:  nix develop /nix/nixos/blender-mcp-nwn -c python test_setup.py
Exercises the real Blender binary via the same code paths the MCP tools use.
"""

import tempfile
from pathlib import Path

import mcp_server as srv


def main():
    d = Path(tempfile.mkdtemp(prefix="blender-mcp-test-"))
    blend = d / "cube.blend"

    # 1. run_blender_script: build an empty scene with one cube and save it.
    build = d / "build.py"
    build.write_text(
        "import bpy\n"
        "bpy.ops.wm.read_factory_settings(use_empty=True)\n"
        "bpy.ops.mesh.primitive_cube_add()\n"
        f"bpy.ops.wm.save_as_mainfile(filepath=r'{blend}')\n"
    )
    r = srv.run_blender_script(str(build))
    assert r["ok"], f"run_blender_script failed: {r}"
    assert blend.is_file(), "cube.blend was not written"

    # 2. read_blend_metadata: expect at least one MESH object.
    m = srv.read_blend_metadata(str(blend))
    assert m["ok"], f"read_blend_metadata failed: {m}"
    assert any(o["type"] == "MESH" for o in m["metadata"]["objects"]), m

    # 3. export_for_nwn: OBJ + mdl.json sidecar.
    out = d / "cube.obj"
    e = srv.export_for_nwn(str(blend), str(out))
    assert e["ok"], f"export_for_nwn failed: {e}"
    assert out.is_file(), "OBJ not written"
    assert Path(str(out) + ".mdl.json").is_file(), "mdl.json sidecar not written"

    print("ALL PASS —", d)


if __name__ == "__main__":
    main()
