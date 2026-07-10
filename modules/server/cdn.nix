{
  flake.modules.nixos.server = {
    services.caddy.virtualHosts."cdn.ily.rs" = {
      extraConfig = ''
        header Access-Control-Allow-Origin "*"
        header Cache-Control "public, max-age=86400"
        root * ${./cdn}
        file_server
        encode zstd gzip
      '';
    };
  };
}
