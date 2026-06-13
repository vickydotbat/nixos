{
  config,
  repository,
  lib,
  ...
}:
let
  home = config.home.homeDirectory;
  trustedProjects = [
    "${home}/Projects/westgate/repositories"
    "${home}/Obsidian/Echo-Reliquary"
  ];
in
{
  theorem.home.shell = {
    bat.enable = true;

    codex = {
      enable = true;
      superpowers.enable = true;
      settings = {
        model = "gpt-5.5";
        model_reasoning_effort = "high";
        model_reasoning_summary = "concise";
        model_verbosity = "medium";

        approval_policy = "never";
        sandbox_mode = "danger-full-access";

        web_search = "cached";
        file_opener = "vscode";
        hide_agent_reasoning = true;

        history.persistence = "none";

        sandbox_workspace_write = {
          network_access = true;
          exclude_slash_tmp = false;
          exclude_tmpdir_env_var = false;
          writable_roots = [
            repository.path
            "/nix/var/nix/daemon-socket"
          ];
        };

        shell_environment_policy."inherit" = "core";

        projects = lib.genAttrs trustedProjects (_: {
          trust_level = "trusted";
        });
      };

      context = ''
        # AGENTS.md

        ## Scope

        Global home-dir instructions for my personal NixOS system.

        Project-local instructions override this file when present, especially:

        - `AGENTS.md`
        - `CLAUDE.md`
        - `README*`
        - `flake.nix`
        - `shell.nix`
        - `.envrc`
        - CI workflow files
        - nearby docs/code comments

        ## System Context

        - OS: NixOS
        - Desktop: KDE Plasma
        - Shell: Bash
        - Editor: VSCode
        - Obsidian vault: `~/Obsidian/Echo-Reliquary`

        Prefer declarative, reproducible, reviewable changes.

        Prefer small, targeted, reversible patches.

        Preserve existing style, structure, names, and conventions.

        ## Operating Model

        Work like an adaptive local agent, not a static script.

        Before editing:

        1. Inspect the relevant repo/files.
        2. Read project instructions and nearby docs.
        3. Infer the build system, test command, package manager, formatter, and runtime assumptions.
        4. Check existing conventions before adding new ones.
        5. Make the smallest useful change.
        6. Run the narrowest practical validation.
        7. If validation fails, read the error, update the diagnosis, and try the smallest correct fix.

        Do not blindly follow generic Linux instructions. This machine is NixOS.

        Do not guess when local docs, repo files, or my knowledge base can answer.

        ## Autonomy

        You may proceed without asking for confirmation for:

        - reading/searching files
        - inspecting git state
        - making small repo-local edits
        - adding docs for behavior you changed
        - running non-destructive validation commands
        - creating project-local dev shells when dependencies are clearly required

        Ask before:

        - deleting files
        - moving large directory trees
        - broad rewrites
        - changing architecture
        - changing persistence layout
        - changing system/Home Manager modules
        - restarting services
        - running rebuilds or switches
        - touching secrets, keys, tokens, credentials, or `.sops` data
        - introducing major dependencies
        - committing, force-pushing, or rewriting git history

        When a decision changes long-term project direction, stop and ask.

        ## Knowledge Base

        Use my Obsidian vault as durable memory.

        When working on something with prior context, search the vault before inventing a new plan.

        Relevant vault path:

        ```bash
        ~/Obsidian/Echo-Reliquary
        ```

        Use the vault for:

        - previous decisions
        - setup notes
        - troubleshooting outcomes
        - project architecture
        - recurring workflows
        - solved commands
        - non-obvious behavior

        Prefer existing notes over duplicates.

        Preserve folder structure, naming, tags, and links.

        If unsure where a note belongs, use an inbox/staging location rather than inventing a new taxonomy.

        When work creates durable knowledge, update the vault.

        Document:

        - decisions
        - setup steps
        - commands that worked
        - troubleshooting outcomes
        - non-obvious fixes
        - recurring workflows
        - project-specific conventions

        Do not document:

        - transient mistakes
        - useless failed guesses
        - secrets
        - credentials
        - sensitive personal data
        - temporary dead ends

        Keep notes concise, searchable, and linked when useful.

        Use this filename format for new notes:

        ```text
        {{year}}{{month}}{{day}}{{hour}}{{minute}}{{second}} {{title}}
        ```

        Add dates only when chronology matters.

        ## Decision Gates

        Verify key decisions with me before implementing them.

        A key decision includes:

        - choosing between competing architectures
        - adopting a new framework, service, database, or deployment model
        - changing NixOS/Home Manager structure
        - changing repo layout
        - changing persistence or backup behavior
        - replacing a toolchain
        - changing production services
        - changing public-facing behavior
        - adding long-term maintenance burden

        When asking, give:

        1. Recommended option.
        2. Alternatives considered.
        3. Tradeoffs.
        4. Exact files likely affected.

        Do not ask for confirmation on every minor implementation detail.

        ## NixOS Rules

        This is NixOS. Do not assume global FHS-style packages exist.

        Do not suggest or run:

        ```bash
        apt install
        dnf install
        pacman -S
        brew install
        sudo make install
        curl | sh
        npm install -g
        pip install --user
        ```

        Use Nix instead.

        For one-off tools:

        ```bash
        nix shell nixpkgs#<package> -c <command>
        ```

        Examples:

        ```bash
        nix shell nixpkgs#git -c git status
        nix shell nixpkgs#ripgrep -c rg TODO .
        nix shell nixpkgs#python3 -c python --version
        nix shell nixpkgs#nodejs_24 -c node --version
        ```

        For repeated project dependencies, prefer a project-local dev shell.

        Dependency escalation order:

        1. Existing `flake.nix` → `nix develop`
        2. Existing `shell.nix` → `nix-shell`
        3. One-off `nix shell nixpkgs#pkg -c command`
        4. Add/update minimal project `flake.nix` dev shell
        5. Suggest system/Home Manager config only for truly global tools

        Do not mutate the host system to solve project-local dependency problems.

        ## Flakes and Dev Shells

        If dependencies are missing and recurring, create or update a minimal project dev shell.

        Prefer `flake.nix` when the repo already uses flakes or needs repeatable tooling.

        Keep shells narrow. Do not create broad “kitchen sink” environments.

        Minimal default:

        ```nix
        {
          description = "Development shell";

          inputs = {
            nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
          };

          outputs = { self, nixpkgs }:
            let
              system = builtins.currentSystem;
              pkgs = import nixpkgs { inherit system; };
            in {
              devShells.''\${system}.default = pkgs.mkShell {
                packages = with pkgs; [
                  # Add only project-required tools.
                ];
              };
            };
        }
        ```

        If a project already has a flake, preserve its structure and style.

        ## NixOS / Home Manager Work

        Prefer NixOS/Home Manager options over ad-hoc scripts.

        Use `rg` for search.

        Format with the repo formatter, usually:

        ```bash
        nix fmt
        ```

        Validate when practical:

        ```bash
        nix flake check
        nixos-rebuild dry-build
        home-manager build
        ```

        Do not run:

        ```bash
        nixos-rebuild switch
        home-manager switch
        ```

        unless explicitly asked.

        Use repo-relative paths in repo docs.

        Use absolute paths only for local, personal, or machine-specific docs.

        ## Language Tooling

        ### Node.js

        Use the project lockfile:

        - `pnpm-lock.yaml` → `pnpm`
        - `package-lock.json` → `npm`
        - `yarn.lock` → `yarn`
        - `bun.lock` / `bun.lockb` → `bun`

        Do not install Node tools globally.

        Use Nix for Node and package-manager binaries when missing.

        ### Python

        Do not globally install Python packages.

        Prefer:

        - project virtualenvs
        - `uv`
        - `poetry`
        - Nix-provided Python/native libraries
        - project-local dev shells

        For quick scripts:

        ```bash
        nix shell nixpkgs#python3 -c python script.py
        ```

        ### Rust

        Respect `rust-toolchain.toml` when present.

        Use Nix for system libraries and build tools:

        ```bash
        nix shell nixpkgs#cargo nixpkgs#rustc nixpkgs#pkg-config nixpkgs#openssl -c cargo build
        ```

        ### Native Builds

        If headers, linkers, or libraries are missing, add the correct Nix packages to the dev shell.

        Common examples:

        ```nix
        pkg-config
        openssl
        zlib
        cmake
        gcc
        clang
        gnumake
        ```

        Do not assume `/usr/include`, `/usr/lib`, or `/usr/local` exist.

        ## FHS Compatibility

        If software assumes a traditional Linux filesystem layout, first try:

        1. proper Nix packages in the shell
        2. environment variables
        3. wrapper scripts
        4. small patches

        Use `buildFHSUserEnv` only when necessary.

        Explain why FHS emulation is needed before adding it.

        ## Git Rules

        Before broad edits:

        ```bash
        git status --short
        ```

        Do not overwrite user changes.

        Do not reformat unrelated files.

        Do not track generated files unless expected by the repo.

        Do not commit unless explicitly asked.

        Do not force-push unless explicitly asked.

        ## Safety Rules

        Do not run destructive commands unless explicitly asked.

        Avoid:

        ```bash
        rm -rf
        sudo
        chmod -R 777
        chown -R
        git reset --hard
        git clean -fdx
        docker system prune
        ```

        Before destructive actions, explain what will be affected.

        Do not touch secrets, credentials, keys, tokens, or `.sops` data.

        ## Documentation Rules

        Document new behavior, features, workflows, decisions, and non-obvious fixes.

        Keep docs accurate, organized, and human-readable.

        Do not add documentation noise.

        Do not duplicate existing docs.

        Update docs near the behavior when practical.

        Use repo-relative paths for repo docs.

        Use absolute paths only for local/personal/machine docs.

        ## External Research

        Research current external information when needed.

        Prefer official docs, source repositories, release notes, and primary sources.

        Do not use outdated assumptions for fast-moving tools, versions, APIs, package names, or platform behavior.

        When external information materially affects the answer, include the source or summarize where it came from.

        ## Reply Style

        Be succinct.

        Sacrifice grammar for concision when useful.

        After work, say:

        1. What changed.
        2. Why.
        3. Validation done.
        4. Validation skipped, if any.
        5. Remaining manual steps, if any.

        Include useful commands.

        Avoid long summaries unless requested.

        ## Core Bias

        Missing tools are not a blocker.

        On NixOS, solve missing tools with:

        ```bash
        nix shell nixpkgs#pkg -c command
        ```

        or for recurring project needs:

        ```bash
        nix develop
        ```

        or a minimal project `flake.nix`.

        Prefer reproducible shells over host mutation.

        Prefer project-local fixes over global machine changes.

        Prefer verified local context over guessing.
      '';
    };

    claude = {
      enable = true;
      # unrestricted = true;

      # settings = {
      #   model = "sonnet";
      #   viewMode = "focus";
      # };

      # context = ''
      #   Be extremely succinct. Sacrifice grammar for concision.
      #   Keep README.md and documentation human readable.
      # '';
    };

    # ghostty.enable = true;
    alacritty.enable = true;
    git.enable = true;
    nix-index = {
      enable = true;
      commandNotFound.enable = true;
    };
    ripgrep = {
      enable = true;
      arguments = [
        "--hidden"
        "--smart-case"
        "--max-columns=200"
        "--max-columns-preview"

        "--glob=!.git/"
        "--glob=!result"
        "--glob=!result-*"
        "--glob=!.direnv/"
        "--glob=!.devenv/"

        "--colors=line:style:bold"
      ];
    };
    shell.enable = true;
    starship.enable = true;
    zellij.enable = false;
  };
}
