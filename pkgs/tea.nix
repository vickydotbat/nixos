# tea, the Gitea CLI. Overrides nixpkgs' 0.14.0 through the flake overlay.
#
# Why the override: 0.14.0 cannot apply org-level labels to an issue or pull
# request, so `tea issues create --labels "Kind/Bug"` silently applies nothing
# in the ShadowsOverWestgate org, where every label is defined once at org
# level. 0.15 fixed that. Drop this file when nixpkgs ships 0.15 or later.
#
# The recipe is nixpkgs' own, with the version, hashes, and SDK stamp moved
# forward.
#
# The binary is wrapped. Run without a terminal on stdout (every agent shell),
# tea gets a hard timeout. A `tea comment` there has been seen to post, then
# stall while it renders the reply, so the shell hung with no sign whether the
# comment landed. A stdin read with no EOF hangs the same way. Agents were told
# both in prose and kept tripping, so the guard now lives in the tool.
{
  lib,
  buildGoModule,
  coreutils,
  fetchFromGitea,
  git,
  installShellFiles,
  runtimeShell,
  stdenv,
  writableTmpDirAsHomeHook,
}:

buildGoModule (finalAttrs: {
  pname = "tea";
  version = "0.15.1";

  src = fetchFromGitea {
    domain = "gitea.com";
    owner = "gitea";
    repo = "tea";
    rev = "v${finalAttrs.version}";
    hash = "sha256-b0Tzw9feSv/7lp67dzBoNV1l97t/AanUOo910Na6RQo=";
  };

  vendorHash = "sha256-tnA14lDGvEdUnOM1/f4d40PBYY7nXkUOTFzxzvzgJvY=";

  # 0.15 renamed the Go module from code.gitea.io/tea to gitea.dev/tea, so the
  # version stamp moved with it. Stamped against gitea.dev/sdk, the SDK 0.15
  # builds on.
  ldflags = [
    "-s"
    "-w"
    "-X gitea.dev/tea/modules/version.Version=${finalAttrs.version}"
    "-X gitea.dev/tea/modules/version.Tags=nixpkgs"
    "-X gitea.dev/tea/modules/version.SDK=1.2.0"
  ];

  checkFlags = [
    # requires a git repository
    "-skip=TestRepoFromPath_Worktree"
  ];

  nativeBuildInputs = [ installShellFiles ];

  # 0.15's cmd tests shell out to git for repository discovery.
  nativeCheckInputs = [
    git
    writableTmpDirAsHomeHook
  ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd tea \
      --bash <($out/bin/tea completion bash) \
      --fish <($out/bin/tea completion fish) \
      --zsh <($out/bin/tea completion zsh)

    mkdir $out/share/powershell/ -p
    $out/bin/tea completion pwsh > $out/share/powershell/tea.Completion.ps1

    $out/bin/tea man --out $out/share/man/man1/tea.1
  ''
  # ponytail: 60 s covers every issue and PR call. A slow `tea clone` or a
  # large `tea api` download can outrun it; raise TEA_TIMEOUT for that run.
  + ''
    mv $out/bin/tea $out/bin/.tea-real
    cat > $out/bin/tea <<EOF
    #!${runtimeShell}
    [ -t 1 ] && exec $out/bin/.tea-real "\$@"
    ${coreutils}/bin/timeout "\''${TEA_TIMEOUT:-60}" $out/bin/.tea-real "\$@"
    rc=\$?
    if [ \$rc -eq 124 ]; then
      echo "tea: timed out after \''${TEA_TIMEOUT:-60}s. A write may have landed anyway." >&2
      echo "tea: read the thread (tea issues <n> --comments) before you retry." >&2
    fi
    exit \$rc
    EOF
    chmod +x $out/bin/tea
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    "$out/bin/tea" --version | grep -q "${finalAttrs.version}"
  '';

  meta = {
    description = "Gitea official CLI client";
    homepage = "https://gitea.com/gitea/tea";
    license = lib.licenses.mit;
    mainProgram = "tea";
    platforms = lib.platforms.unix;
  };
})
