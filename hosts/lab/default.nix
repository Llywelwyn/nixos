{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../common
    ./foundry.nix
    ./dokuwiki.nix
  ];

  networking.hostName = "lab";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  users.users.lew = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6KI06F0tHIurNFFRJRlHMeLb7dnUEk8jtSmdsdkfPPoDY0HL1A0QJwqsppFbjHSsJoQ/WZGIj09Evmk9RRGjR5uNEtDMWfxEoeJQoJ6Bwdit+BPa3TfgyyoLM107/D5JriFoZW9k0JVNkgAIFnHp6VAjFyrg4298yKzy2dZchDO4u5HfFi+HBwn2haP7IC0JNgq6GO8K+yw4UK2635/3B/xNLhhLobbT4sThcghBtBhvb8pSXJ0wLupwuGWN9uuONs0UYEOlb8BhedXR4ShJUsQERIPFByAvMaq5vbsVIojF5s4P4dAlpsRQpXhQa7E4wzwGy5bYVP3MNmtYwxZel ssh-key-2025-12-11"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers.backend = "podman";

  services.caddy.enable = true;

  system.stateVersion = "23.11";
}
