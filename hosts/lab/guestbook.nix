{ config, guestbook, ... }:
{
  sops.secrets.telegram_bot_token = {
    sopsFile = ../../secrets/guestbook.yaml;
    owner = "guestbook";
  };

  services.guestbook = {
    enable = true;
    package = guestbook.packages.aarch64-linux.default;
    port = 8123;
    dataDir = "/srv/guestbook/data";
    user = "guestbook";
    group = "guestbook";

    siteTitle = "ily [dot] rs";
    basePath = "/guestbook";

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
      templateFile = ./templates/default.html;
      successTemplateFile = ./templates/success.html;
      labels = {
        submit = "Submit";
        name = "Your name*:";
        website = "Your website:";
        message = "Your message*:";
      };
      message = {
        width = 300;
        height = 100;
      };
    };
  };
}
