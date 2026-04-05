{ pkgs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  users.users.lew = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6KI06F0tHIurNFFRJRlHMeLb7dnUEk8jtSmdsdkfPPoDY0HL1A0QJwqsppFbjHSsJoQ/WZGIj09Evmk9RRGjR5uNEtDMWfxEoeJQoJ6Bwdit+BPa3TfgyyoLM107/D5JriFoZW9k0JVNkgAIFnHp6VAjFyrg4298yKzy2dZchDO4u5HfFi+HBwn2haP7IC0JNgq6GO8K+yw4UK2635/3B/xNLhhLobbT4sThcghBtBhvb8pSXJ0wLupwuGWN9uuONs0UYEOlb8BhedXR4ShJUsQERIPFByAvMaq5vbsVIojF5s4P4dAlpsRQpXhQa7E4wzwGy5bYVP3MNmtYwxZel ssh-key-2025-12-11"
    ];
  };

  environment.systemPackages = with pkgs; [
    neovim
    git
    sops
    just
    htop
  ];
  ];
}
