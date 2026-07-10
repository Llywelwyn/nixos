{
  flake.modules.nixos.server = {
    services.caddy.extraConfig = ''
      (favicons) {
        @favicon path /favicon.ico /favicon.svg /favicon.png /apple-touch-icon.png /apple-touch-icon-precomposed.png
        handle @favicon {
          root * ${./favicons}
          @needs_png path /favicon.ico
          rewrite @needs_png /favicon.png
          @needs_touch path /apple-touch-icon-precomposed.png
          rewrite @needs_touch /apple-touch-icon.png
          header Cache-Control "public, max-age=86400"
          file_server
        }
      }
    '';
  };
}
