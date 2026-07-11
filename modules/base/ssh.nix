{
  flake.modules = {
    nixos.base = {
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };
    };

    nixos.server = {
      services.openssh.ports = [ 4200 ];
      networking.firewall.allowedTCPPorts = [ 4200 ];
    };

    homeManager.desktop = { config, ... }: {
      sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      sops.secrets.ssh_config = {
        sopsFile = ../../secrets/ssh.yaml;
        path = "${config.home.homeDirectory}/.ssh/config";
      };
    };
  };
}
