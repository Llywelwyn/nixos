{ config, ... }:
{
  sops.secrets.discord-irc-token = {
    sopsFile = ../../secrets/discord-irc.yaml;
  };

  sops.templates."discord-irc-config.json" = {
    owner = "podman";
    content = builtins.toJSON {
      nickname = "d";
      format = {
        ircText = "<{$displayUsername}> {$text}";
        urlAttachment = "<{$displayUsername}> {$attachmentURL}";
      };
      server = "127.0.0.1";
      port = 6667;
      tls = false;
      discordToken = config.sops.placeholder.discord-irc-token;
      webhooks = true;
      ircStatusNotices = true;
      channelMapping = {
        "1507821989300273307" = "#grey-mc";
        "1462196901209440374" = "#grey-dnd";
        "832733970068144221" = "#grey";
        "384092190068047880" = "#icon";
        "462370232712036355" = "#laiken";
        "1401241161225732240" = "#laiken-osrs";
        "1449354793687584880" = "#laiken-osrs-loot";
      };
    };
  };

  virtualisation.oci-containers.containers.discord-irc = {
    image = "ghcr.io/aronson/discord-irc:3.1.0";
    podman.user = "podman";
    extraOptions = [ "--network=host" ];
    volumes = [
      "${config.sops.templates."discord-irc-config.json".path}:/app/config.json:ro"
    ];
  };

  systemd.services.podman-discord-irc = {
    after = [ "ergochat.service" ];
    wants = [ "ergochat.service" ];
  };
}
