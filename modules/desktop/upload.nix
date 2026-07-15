{ config, ... }:
{
  flake.modules.nixos.desktop = {
    sops.secrets.rustypaste-delete-token = {
      sopsFile = ../../secrets/rustypaste.yaml;
      key = "delete_token";
      owner = config.flake.meta.username;
      mode = "0400";
    };
  };

  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = [
      (pkgs.writeShellScriptBin "upload" (builtins.readFile ./_scripts/upload))
    ];
  };
}
