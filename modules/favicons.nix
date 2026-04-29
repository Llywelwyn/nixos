{ ... }:
let
  faviconRoot = ../assets/favicons;
in
{
  services.caddy.extraConfig = ''
    (favicons) {
      @favicon path /favicon.ico /favicon.svg /favicon.png /apple-touch-icon.png /apple-touch-icon-precomposed.png
      handle @favicon {
        root * ${faviconRoot}
        @needs_png path /favicon.ico /apple-touch-icon.png /apple-touch-icon-precomposed.png
        rewrite @needs_png /favicon.png
        header Cache-Control "public, max-age=86400"
        file_server
      }
    }
  '';
}
