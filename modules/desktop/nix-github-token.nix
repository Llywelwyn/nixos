{ config, ... }:
let
  inherit (config.flake.meta) username;
in
{
  flake.modules.nixos.desktop = { config, ... }: {
    sops.secrets.github-token = {
      sopsFile = ../../secrets/nix.yaml;
      key = "github_token";
    };

    sops.templates."nix-access-tokens.conf" = {
      content = "access-tokens = github.com=${config.sops.placeholder.github-token}";
      owner = username;
      mode = "0400";
    };

    nix.extraOptions = "!include ${config.sops.templates."nix-access-tokens.conf".path}";
  };
}
