{ guestbook, config, ... }:
{
  sops.secrets.guestbook-telegram-token = {
    sopsFile = ../../secrets/guestbook.yaml;
    key = "telegram_bot_token";
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
    caddy = {
      enable = true;
      domain = "g.ily.rs";
    };

    features = {
      submissions.enable = false;
      websites.enable = false;
      drawing = {
        enable = false;
        canvasWidth = 400;
        canvasHeight = 200;
      };
      voiceNote = {
        enable = false;
        maxDuration = 20;
      };
      telegram = {
        enable = true;
        botTokenFile = config.sops.secrets.guestbook-telegram-token.path;
        chatId = 8669496383;
      };
      security = {
        htmlInjection.enable = true;
        honeypot.enable = true;
        captcha.enable = false;
      };
    };

    limits = {
      name = 0;
      message = 0;
      website = 0;
    };

    styles = {
      separator = "-----------";
      labels = {
        submit = "Submit";
        name = "Your name*:";
        website = "Your website:";
        message = "Your message*:";
      };
      message = {
        width = 400;
        height = 150;
      };
    };
  };
}
