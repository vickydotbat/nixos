{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

# MCP server that drives a live Blender session through the companion addon
# (addon.py, exposed via passthru.addon). One server process per Blender
# instance; the port is picked with the BLENDER_PORT environment variable and
# must match the port set in the addon's N-panel before connecting.
python3Packages.buildPythonApplication rec {
  pname = "blender-mcp";
  version = "1.8.0-unstable-2026-08-05";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ahujasid";
    repo = "blender-mcp";
    rev = "3ab892510cc0e5435ba5e611c01fb1021fbde8de";
    hash = "sha256-B3nzFIEwMU6ki/eGHtoOv116zTUxh9m9kD1iyfFo80Q=";
  };

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    mcp
    httpx
  ];

  pythonImportsCheck = [ "blender_mcp" ];

  passthru.addon = "${src}/addon.py";

  meta = {
    description = "Blender integration through the Model Context Protocol";
    homepage = "https://github.com/ahujasid/blender-mcp";
    license = lib.licenses.mit;
    mainProgram = "blender-mcp";
  };
}
