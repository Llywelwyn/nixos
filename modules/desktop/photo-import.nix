{ config, ... }:
{
  flake.modules.nixos.desktop = {
    sops.secrets.immich-api-key = {
      sopsFile = ../../secrets/immich.yaml;
      key = "api_key";
      owner = config.flake.meta.username;
      mode = "0400";
    };
  };

  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = [
      pkgs.android-file-transfer
      pkgs.exiftool
      pkgs.immich-go
      (pkgs.writeShellScriptBin "photo-import" (builtins.readFile ./_scripts/photo-import))
      (pkgs.writeShellScriptBin "photo-publish" (builtins.readFile ./_scripts/photo-publish))
    ];
  };
}
