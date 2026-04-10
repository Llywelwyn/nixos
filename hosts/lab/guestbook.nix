{ guestbook, ... }:
{
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
      forwardAuth = {
      	enable = true;
	address = "localhost:3002";
	uri = "/api/auth/caddy";
	copyHeaders = [ "Remote-User" "Remote-Name" "Remote-Email" "Remote-Groups" ];
      };
    };

    features = {
      submissions.enable = true;
      websites.enable = true;
      drawing = {
        enable = true;
        canvasWidth = 300;
        canvasHeight = 140;
      };
      voiceNote = {
        enable = true;
        maxDuration = 20;
      };
      telegram = {
        enable = false;
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
