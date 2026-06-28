{
  lib,
  vscode-utils,
}:

vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    publisher = "selfagency";
    name = "opilot";
    version = "1.8.2";
    hash = "sha256-Se17cIVt4iFOZoAuBmWBjAU5HmfdTH7tkmJfDnpJqlo=";
  };

  meta = {
    description = "Run Ollama models with full tool and vision support in GitHub Copilot Chat.";
    homepage = "https://marketplace.visualstudio.com/items?itemName=selfagency.opilot";
    license = lib.licenses.mit;
  };
}
