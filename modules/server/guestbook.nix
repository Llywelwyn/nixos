{ inputs, ... }:
{
  flake.modules.nixos.server = { config, pkgs, ... }:
  {
    imports = [ inputs.guestbook.nixosModules.default ];

    sops.secrets.telegram_bot_token = {
      sopsFile = ../../secrets/guestbook.yaml;
      owner = "guestbook";
    };

    services = {
      telegram-alerts.units = [ "guestbook" ];
      uptime-page.probes.guestbook = { url = "https://ily.rs/guestbook"; order = 20; };

      guestbook = {
        enable = true;
        package = inputs.guestbook.packages.${pkgs.stdenv.hostPlatform.system}.default;
        port = 8123;
        dataDir = "/srv/guestbook/data";
        user = "guestbook";
        group = "guestbook";

        siteTitle = "ily guestbook";
        basePath = "/guestbook";
        dateFormat = "%d/%m/%y";

        submissions.enable = true;
        websites.enable = true;
        content.required = false;
        message.required = false;

        drawing = {
          enable = true;
          required = false;
        };

        voice = {
          enable = true;
          required = false;
        };

        telegram = {
          enable = true;
          chatId = 8669496383;
          botTokenFile = config.sops.secrets.telegram_bot_token.path;
        };

        security = {
          htmlInjection.enable = true;
          honeypot.enable = true;
          captcha.enable = false;
        };

        limits = {
          name.length = 0;
          message.length = 0;
          website.length = 0;
          drawing = {
            width = 300;
            height = 140;
          };
          voice.duration = 20;
        };

        styles = {
          templateFile = ./guestbook-templates/default.html;
          successTemplateFile = ./guestbook-templates/success.html;
          labels = {
            submit = "Submit";
            name = "Your name*";
            website = "Link a website (optional)";
            message = "Leave a message (optional)";
          };
          message = {
            width = 300;
            height = 100;
          };
        };
      };
    };
  };
}
