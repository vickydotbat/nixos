{
  lib,
  python3Packages,
  fetchFromGitHub,
  # Language plugins to build into the environment. Upstream ships them as pip
  # extras (`habit-hooks[python,typescript]`); here they are separate Python
  # distributions from the same tree, found at run time through the
  # `habit_hooks.plugins` entry point. `generic` is part of every install.
  languages ? [
    "python"
    "typescript"
  ],
}:

let
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "habit-hooks";
    repo = "habit-hooks";
    rev = "v${version}";
    hash = "sha256-7Y33Gz65Sl8Dr8x1wPe404Ejqd9jgEdwz3Ff6B/AapA=";
  };

  known = [
    "python"
    "typescript"
    "php"
    "java"
  ];

  # plugins/<name> is a complete Python distribution with no dependencies of its
  # own; the detectors it drives (ruff, eslint, ...) are spawned from PATH.
  plugin =
    name:
    python3Packages.buildPythonPackage {
      pname = "habit-hooks-${name}";
      inherit version src;
      sourceRoot = "${src.name}/plugins/${name}";
      pyproject = true;
      build-system = [ python3Packages.hatchling ];
      doCheck = false;
      pythonImportsCheck = [ "habit_hooks_${builtins.replaceStrings [ "-" ] [ "_" ] name}" ];
      meta.description = "The ${name} Habit Hooks plugin";
    };
in

assert lib.assertMsg (lib.subtractLists known languages == [ ])
  "habit-hooks: unknown language plugin(s) ${lib.concatStringsSep ", " (lib.subtractLists known languages)}; known: ${lib.concatStringsSep ", " known}";

python3Packages.buildPythonApplication {
  pname = "habit-hooks";
  inherit version src;
  pyproject = true;

  build-system = [ python3Packages.hatchling ];

  dependencies = [
    python3Packages.jinja2
    python3Packages.pathspec
    python3Packages.attrs
    (plugin "generic")
  ]
  ++ map plugin languages;

  # The suite drives real detectors (ruff, eslint, jscpd, php, pmd) over git
  # checkouts it makes itself, none of which exist in the build sandbox.
  doCheck = false;

  doInstallCheck = true;
  installCheckPhase = ''
    "$out/bin/habit-hooks" --version
    "$out/bin/habit-sensors" --version
  '';

  passthru.skills = "${src}/skills";

  meta = {
    description = "Turns linter findings into coaching guides an AI coding agent can act on";
    homepage = "https://github.com/habit-hooks/habit-hooks";
    changelog = "https://github.com/habit-hooks/habit-hooks/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "habit-hooks";
    platforms = lib.platforms.unix;
  };
}
