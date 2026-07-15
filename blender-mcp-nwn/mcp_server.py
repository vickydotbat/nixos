#!/usr/bin/env python3
"""MCP server wrapping Blender 4.0.2 (headless) for NWN:EE tileset work.

Speaks MCP over stdio to Claude Desktop via the `mcp` package (FastMCP).
Blender is driven as `blender-4.0.2 --background [file.blend] --python <script>`;
`bpy` runs inside Blender's own interpreter, so this host process never imports it.
This server is called *by* Claude — it does not call the Anthropic API.
"""

import json
import os
import subprocess
import tempfile
from pathlib import Path

from mcp.server.fastmcp import FastMCP

BLENDER = os.environ.get("BLENDER_BIN", "blender-4.0.2")
TIMEOUT = int(os.environ.get("BLENDER_TIMEOUT", "300"))

# Markers to pull one JSON payload back out of Blender's noisy stdout.
BEGIN, END = "<<<NWN_JSON_BEGIN>>>", "<<<NWN_JSON_END>>>"

mcp = FastMCP("blender-nwn")


def _blender(blend_file=None, script=None, argv=None):
    cmd = [BLENDER, "--background"]
    if blend_file:
        cmd.append(str(blend_file))
    if script:
        # exit non-zero if the script raises, so returncode is meaningful.
        cmd += ["--python", str(script), "--python-exit-code", "1"]
    if argv:
        cmd += ["--", *map(str, argv)]  # everything after -- reaches the script's sys.argv
    return subprocess.run(cmd, capture_output=True, text=True, timeout=TIMEOUT)


def _extract_json(stdout):
    if BEGIN in stdout and END in stdout:
        return json.loads(stdout.split(BEGIN, 1)[1].split(END, 1)[0])
    return None


def _run_temp_script(text, blend_file=None, argv=None):
    """Write `text` to a temp .py, run it in Blender, return (proc, parsed_json)."""
    with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False) as f:
        f.write(text)
        script = f.name
    try:
        proc = _blender(blend_file=blend_file, script=script, argv=argv)
    finally:
        os.unlink(script)
    return proc, _extract_json(proc.stdout)


# --- Blender-side scripts (run in Blender's bundled Python, not this one) -----

_META_SCRIPT = f"""
import bpy, json
d = {{"objects": [], "meshes": [], "materials": []}}
for o in bpy.data.objects:
    d["objects"].append({{"name": o.name, "type": o.type, "dimensions": list(o.dimensions)}})
for m in bpy.data.meshes:
    d["meshes"].append({{"name": m.name, "vertices": len(m.vertices),
                         "polygons": len(m.polygons),
                         "materials": [x.name for x in m.materials if x]}})
for mt in bpy.data.materials:
    d["materials"].append({{"name": mt.name}})
print("{BEGIN}" + json.dumps(d) + "{END}")
"""


def _export_script(fmt):
    if fmt == "fbx":
        export = (
            "bpy.ops.export_scene.fbx(filepath=out, axis_forward='Y', axis_up='Z', "
            "apply_unit_scale=True, mesh_smooth_type='FACE')\n"
        )
    else:  # obj — NWN wants Z-up / Y-forward, triangulated, modifiers applied
        export = (
            "bpy.ops.wm.obj_export(filepath=out, forward_axis='Y', up_axis='Z', "
            "apply_modifiers=True, export_materials=True, export_triangulated_mesh=True)\n"
        )
    return f"""
import bpy, sys, json
out = sys.argv[sys.argv.index("--") + 1:][0]
bpy.context.scene.unit_settings.system = 'METRIC'
{export}
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
cfg = {{
    "source": bpy.data.filepath,
    "export": out,
    "nwn": {{"classification": "Tile", "scale": 1.0, "up_axis": "Z", "forward_axis": "Y"}},
    # ponytail: sensible per-mesh MDL defaults; hand-edit this sidecar or feed it to
    # neverblender/cleanmodels. True MDL emit needs the neverblender addon (see README).
    "objects": [{{"name": o.name, "render": True, "shadow": True, "tilefade": 0}} for o in meshes],
}}
open(out + ".mdl.json", "w").write(json.dumps(cfg, indent=2))
print("{BEGIN}" + json.dumps({{"export": out, "config": out + ".mdl.json",
                               "meshes": len(meshes)}}) + "{END}")
"""


# --- MCP tools ----------------------------------------------------------------


@mcp.tool()
def run_blender_script(script_path: str, blend_file: str | None = None) -> dict:
    """Execute a Python script inside Blender 4.0.2 (headless, using its `bpy` API).

    script_path: path to a .py file. blend_file: optional .blend to open first.
    Returns exit code, stdout and stderr.
    """
    p = Path(script_path).expanduser()
    if not p.is_file():
        return {"ok": False, "error": f"script not found: {p}"}
    proc = _blender(blend_file=blend_file, script=p)
    return {
        "ok": proc.returncode == 0,
        "returncode": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
    }


@mcp.tool()
def read_blend_metadata(file_path: str) -> dict:
    """Extract geometry/material info from a .blend: objects, meshes (vert/poly
    counts, materials) and material names."""
    p = Path(file_path).expanduser()
    if not p.is_file():
        return {"ok": False, "error": f"blend not found: {p}"}
    proc, meta = _run_temp_script(_META_SCRIPT, blend_file=p)
    if meta is None:
        return {"ok": False, "returncode": proc.returncode, "stderr": proc.stderr[-2000:]}
    return {"ok": True, "metadata": meta}


@mcp.tool()
def export_for_nwn(blend_file: str, output_path: str) -> dict:
    """Export a .blend with NWN-friendly settings (Z-up/Y-forward, metric,
    triangulated). Format is chosen by extension (.fbx else .obj). Also writes a
    `<output>.mdl.json` MDL export-config sidecar."""
    p = Path(blend_file).expanduser()
    if not p.is_file():
        return {"ok": False, "error": f"blend not found: {p}"}
    fmt = "fbx" if output_path.lower().endswith(".fbx") else "obj"
    proc, res = _run_temp_script(_export_script(fmt), blend_file=p, argv=[output_path])
    if res is None or proc.returncode != 0:
        return {"ok": False, "returncode": proc.returncode, "stderr": proc.stderr[-2000:]}
    return {"ok": True, **res}


if __name__ == "__main__":
    mcp.run()  # stdio transport
