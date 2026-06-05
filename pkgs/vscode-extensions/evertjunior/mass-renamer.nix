{
  lib,
  vscode-utils,
}:

vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    publisher = "evertjunior";
    name = "mass-renamer";
    version = "0.0.7";
    hash = "sha256-TNz7Xe8F/vwNTOrHkI85yO2OXouYWeT0P+A7x+hW9NA=";
  };

  meta = {
    description = "Batch rename files and folders from the VS Code explorer";
    homepage = "https://marketplace.visualstudio.com/items?itemName=evertjunior.mass-renamer";
    license = lib.licenses.mit;
  };
}
