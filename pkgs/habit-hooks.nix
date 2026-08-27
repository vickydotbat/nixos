{
  lib,
  python3Packages,
  fetchFromGitHub,
  git,
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

  deps = [
    python3Packages.jinja2
    python3Packages.pathspec
    python3Packages.attrs
    (plugin "generic")
  ]
  ++ map plugin languages;
in

assert lib.assertMsg (lib.subtractLists known languages == [ ])
  "habit-hooks: unknown language plugin(s) ${lib.concatStringsSep ", " (lib.subtractLists known languages)}; known: ${lib.concatStringsSep ", " known}";

python3Packages.buildPythonApplication {
  pname = "habit-hooks";
  inherit version src;
  pyproject = true;

  build-system = [ python3Packages.hatchling ];

  dependencies = deps;

  # Both snooze transformers re-enter as `${python} -m habit_hooks.snooze`, a
  # fresh subprocess of `sys.executable`. Nix's console scripts add their site
  # directories inside the script, so that child starts with none of them and
  # dies on `No module named 'habit_hooks'` — which breaks every default run,
  # since `transformers` defaults to `["snooze"]`.
  #
  # Point them at this build's own console script instead. Upstream avoided the
  # script because a bare name needs the bin directory on PATH; an absolute
  # store path has no such requirement. The alternative — exporting PYTHONPATH
  # from the wrappers — would leak these packages into every detector the run
  # spawns, including a project's own `.venv` tools.
  postPatch = ''
    substituteInPlace src/habit_hooks/transformers/snooze.toml \
      src/habit_hooks/transformers/snooze-until-changed.toml \
      --replace-fail '"''${python} -m habit_hooks.snooze' "\"$out/bin/habit-snooze"
  '';

  # Upstream's own suite is not run: it drives real detectors (ruff, eslint,
  # jscpd, php, pmd) over git checkouts it makes itself, none of which exist in
  # the build sandbox. This replaces it with one whole run over a one-file
  # project, which fails if the transformer patch above is wrong — the snooze
  # step runs as its own process, and `--version` would pass without it.
  #
  # The run names `generic`, the one plugin every `languages` value installs, so
  # the check is the same whichever languages this build carries.
  #
  # A Python build has no check phase: `mk-python-derivation.nix` moves
  # `checkPhase` to `installCheckPhase` and takes `doInstallCheck` from
  # `doCheck`, so this has to be written as a check to run at all, and it needs
  # `$out`, which only a phase this late has.
  #
  # `env -u PYTHONPATH` matters as much as the run does. The build environment
  # exports PYTHONPATH for every phase, so the subprocess would find these
  # packages here and nowhere else — the check would pass on a build that breaks
  # the moment someone runs it.
  doCheck = true;
  nativeCheckInputs = [ git ];

  checkPhase = ''
    runHook preCheck

    "$out/bin/habit-hooks" --version

    project=$(mktemp -d)
    mkdir -p "$project/.habit-hooks"
    cat > "$project/.habit-hooks/config.toml" <<'TOML'
    plugins = ["generic"]
    files = ["**/*.py"]

    # jscpd is an npm package, so it is never in the sandbox. The line counter
    # is built in and enough to make this a real run.
    [sensors.jscpd]
    disabled = true
    TOML
    echo 'x = 1' > "$project/clean.py"
    git -C "$project" init -q
    git -C "$project" add -A

    run=$(cd "$project" && env -u PYTHONPATH "$out/bin/habit-hooks" --all 2>&1) || true
    echo "$run"
    case $run in
      *incomplete-run* | *ModuleNotFoundError*)
        echo "habit-hooks: the run did not complete" >&2
        exit 1
        ;;
    esac

    runHook postCheck
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
