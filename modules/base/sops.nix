{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.sops-nix.nixosModules.sops ];
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
