{
  programs.git.settings = {
    user = {
      name = "admin";
      email = "admin@solanine.local";
      signingkey = "~/.ssh/id_ed25519";
    };

    gpg.format = "ssh";
    commit.gpgsign = true;
  };
}
