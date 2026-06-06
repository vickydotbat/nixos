{
  inputs,
  pkgs,
}:

let
  lib = inputs.nixpkgs.lib;
  solanine = inputs.self.nixosConfigurations.solanine;
  config = solanine.config;
  home = config.home-manager.users.vicky;
  extensions = home.programs.vscode.profiles.default.extensions;
  settings = home.programs.vscode.profiles.default.userSettings;

  hasPname =
    name: packages:
    builtins.any (pkg: (pkg.pname or "") == name || lib.hasPrefix "${name}-" (pkg.name or "")) packages;

  prettierTwoSpaceLanguages = [
    "[javascript]"
    "[javascriptreact]"
    "[typescript]"
    "[typescriptreact]"
    "[json]"
    "[jsonc]"
    "[html]"
    "[css]"
    "[scss]"
    "[less]"
    "[vue]"
    "[svelte]"
    "[graphql]"
    "[yaml]"
    "[markdown]"
    "[mdx]"
  ];

  languageUsesPrettierTwoSpaces =
    language:
    let
      languageSettings = settings.${language};
    in
    languageSettings."editor.defaultFormatter" == "esbenp.prettier-vscode"
    && languageSettings."editor.insertSpaces"
    && languageSettings."editor.tabSize" == 2
    && languageSettings."prettier.tabWidth" == 2;
in
assert hasPname "vscode-extension-esbenp-prettier-vscode" extensions;
assert hasPname "prettier" home.home.packages;
assert settings."editor.defaultFormatter" == "esbenp.prettier-vscode";
assert settings."editor.insertSpaces";
assert settings."editor.tabSize" == 4;
assert settings."editor.detectIndentation" == false;
assert settings."prettier.enable";
assert settings."prettier.requireConfig" == false;
assert settings."prettier.useEditorConfig";
assert settings."prettier.useTabs" == false;
assert settings."prettier.tabWidth" == 4;
assert lib.all languageUsesPrettierTwoSpaces prettierTwoSpaceLanguages;
assert settings."[nix]"."editor.defaultFormatter" == "jnoortheen.nix-ide";
assert settings."[nix]"."editor.formatOnSave";
assert settings."[nix]"."editor.insertSpaces";
assert settings."[nix]"."editor.tabSize" == 2;
assert settings."nix.formatterPath" == "nixfmt";
assert settings."nix.serverSettings".nixd.formatting.command == [ "nixfmt" ];
pkgs.runCommand "vicky-vscode-format-boundary" { } ''
  touch "$out"
''
