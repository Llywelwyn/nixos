{ ... }:
{
  imports = [
    ../ssh.nix
    ../git.nix
    ../ghostty.nix
  ];

  home.stateVersion = "26.05";
}
