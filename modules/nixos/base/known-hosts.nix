{
  ...
}:

# Public host keys for the household machines, so outbound SSH can verify them
# without a human at the keyboard.
#
# `users/vicky/ssh-hosts.nix` deliberately leaves StrictHostKeyChecking at its
# default (`ask`) for these hosts: a changed key should be a question, not a
# silent accept. But `ask` needs a terminal, and the shared-folder sshfs unit
# has none, so every automated connection failed with "Host key verification
# failed" until these keys were declared somewhere ssh actually reads.
#
# This lands in /etc/ssh/ssh_known_hosts. OpenSSH consults that file in
# addition to UserKnownHostsFile, so the per-user persisted known_hosts in
# modules/home/base/ssh.nix keeps working for everything else.
#
# Host keys are public by definition; they are not secrets and do not belong in
# SOPS. Read them from a host with `cat /etc/ssh/ssh_host_ed25519_key.pub`.
#
# ponytail: a literal attrset beats generating this from the host registry
# while there are three machines and the keys only change on reinstall.
{
  programs.ssh.knownHosts = {
    solanine = {
      hostNames = [
        "solanine"
        "192.168.1.62"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILDW00onrzaSXiMnoFNgwFsORLoYj4IigneZej73PiYT";
    };

    saturnine = {
      hostNames = [
        "saturnine"
        "192.168.1.8"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7GDqrDiAZRXaf8tGGXaSKifo9VcJFIPsS1HU8mpnEC";
    };
  };
}
