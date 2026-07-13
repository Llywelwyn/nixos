{
  flake.modules.nixos.desktop = { lib, ... }: {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "steam"
      "steam-unwrapped"
      "slack"
      "proton-authenticator"
      "claude-code"
    ];
  };
}
