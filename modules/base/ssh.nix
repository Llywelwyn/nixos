{
  flake.modules = {
    nixos.base = {
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };
    };

    nixos.server = {
      services.openssh.ports = [ 4200 ];
      networking.firewall.allowedTCPPorts = [ 4200 ];
    };

    homeManager.desktop = { config, ... }: {
      sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      sops.secrets.ssh_config = {
        sopsFile = ../../secrets/ssh.yaml;
        path = "${config.home.homeDirectory}/.ssh/config";
      };
    };
  };
}
