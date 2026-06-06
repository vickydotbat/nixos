{
  inputs,
  pkgs,
}:

let
  lib = pkgs.lib;

  hosts = inputs.self.nixosConfigurations;

  selectedGitUsers = [
    {
      host = "solanine";
      user = "admin";
      home = hosts.solanine.config.home-manager.users.admin;
    }
    {
      host = "solanine";
      user = "vicky";
      home = hosts.solanine.config.home-manager.users.vicky;
    }
    {
      host = "saturnine";
      user = "admin";
      home = hosts.saturnine.config.home-manager.users.admin;
    }
    {
      host = "saturnine";
      user = "vicky";
      home = hosts.saturnine.config.home-manager.users.vicky;
    }
    {
      host = "firelink";
      user = "admin";
      home = hosts.firelink.config.home-manager.users.admin;
    }
  ];

  assertSharedGitSafety =
    entry:
    let
      settings = entry.home.programs.git.settings;
    in
    assert settings.safe.directory == "/nix/nixos";
    assert settings.pull.ff == "only";
    assert settings.rebase.autoStash;
    assert settings.fetch.all;
    assert settings.fetch.prune;
    assert settings.fetch.pruneTags;
    assert settings.fetch.showForcedUpdates;
    assert settings.push.default == "simple";
    assert settings.push.autoSetupRemote == false;
    assert settings.push.followTags;
    assert settings.merge.conflictStyle == (if entry.user == "vicky" then "zdiff3" else "diff3");
    assert settings.core.untrackedCache;
    assert settings.core.fsmonitor;
    true;

  vickyEditorSettings =
    hosts.solanine.config.home-manager.users.vicky.programs.vscode.profiles.default.userSettings;

  sharedGitSafetyHolds = lib.all assertSharedGitSafety selectedGitUsers;
in
assert sharedGitSafetyHolds;
assert vickyEditorSettings."git.autofetch" == "all";
assert vickyEditorSettings."git.confirmSync";
assert vickyEditorSettings."git.rebaseWhenSync" == false;
assert vickyEditorSettings."git.enableSmartCommit" == false;
assert vickyEditorSettings."git.allowForcePush" == false;
assert vickyEditorSettings."git.confirmForcePush";
assert vickyEditorSettings."git.useForcePushWithLease";
assert vickyEditorSettings."git.openRepositoryInParentFolders" == "never";
pkgs.runCommand "git-safety-boundary" { } ''
  touch "$out"
''
