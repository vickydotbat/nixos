{
  programs.git.settings = {
    user = {
      name = "vickydotbat";
      email = "vickydotbat@tutamail.com";
      signingkey = "~/.ssh/id_ed25519";
    };

    gpg.format = "ssh";
    commit.gpgsign = true;
  };
}
