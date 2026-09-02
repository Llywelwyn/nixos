{ config, ... }:
let
  inherit (config.flake.meta) email;
in
{
  flake.modules.nixos.server =
    { config, pkgs, ... }:
    let
      domain = "vm0.ily.rs";
      maildir = "/var/mail/email-post";

      processScript = pkgs.writeText "email-post-process.py" ''
        import base64
        import email
        import email.utils
        import json
        import os
        import re
        import sys
        import urllib.error
        import urllib.request
        from datetime import datetime
        from email import policy
        from pathlib import Path

        maildir = Path(os.environ["MAILDIR"])
        api_base = os.environ["FORGEJO_API"]
        branch = os.environ["BRANCH"]
        allowed_sender = os.environ["ALLOWED_SENDER"].lower()
        recipient = Path(os.environ["RECIPIENT_FILE"]).read_text().strip().lower()
        token = Path(os.environ["TOKEN_FILE"]).read_text().strip()


        def api(method, path, payload=None):
            data = json.dumps(payload).encode() if payload is not None else None
            req = urllib.request.Request(
                api_base + path,
                data=data,
                method=method,
                headers={
                    "Authorization": "token " + token,
                    "Content-Type": "application/json",
                },
            )
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.load(resp)


        def addresses(msg, *headers):
            fields = []
            for header in headers:
                fields.extend(msg.get_all(header, []))
            return [addr.lower() for _, addr in email.utils.getaddresses(fields)]


        def body_text(msg):
            part = msg.get_body(preferencelist=("plain",))
            if part is None:
                return ""
            text = part.get_content().replace("\r\n", "\n")
            text = re.split(r"\n-- \n", text)[0]
            text = re.sub(r"\n*Sent (with|from) Proton Mail.*\Z", "", text, flags=re.S)
            return text.strip()


        def message_date(msg):
            try:
                return email.utils.parsedate_to_datetime(str(msg["date"]))
            except (TypeError, ValueError):
                return datetime.now()


        def publish_now(text, when):
            current = api("GET", "/contents/content/now.md?ref=" + branch)
            content = base64.b64decode(current["content"]).decode()
            marker = "<dl>\n"
            if marker not in content:
                raise RuntimeError("no <dl> marker in now.md")
            block = (
                '{% update(date="' + when.strftime("%d/%m/%y") + '") %}\n'
                + text
                + "\n{% end %}"
            )
            content = content.replace(marker, marker + "\n" + block + "\n", 1)
            api("PUT", "/contents/content/now.md", {
                "branch": branch,
                "sha": current["sha"],
                "message": "now: update via email",
                "content": base64.b64encode(content.encode()).decode(),
            })


        def publish_bookmark(url, text):
            current = api("GET", "/contents/content/links.md?ref=" + branch)
            content = base64.b64decode(current["content"]).decode()
            display = re.sub(r"^https?://", "", url, flags=re.I).rstrip("/")
            line = '<a href="' + url + '">' + display + "</a> - " + text + "<br>"
            content = content.rstrip("\n") + "\n" + line + "\n"
            api("PUT", "/contents/content/links.md", {
                "branch": branch,
                "sha": current["sha"],
                "message": "links: add " + display,
                "content": base64.b64encode(content.encode()).decode(),
            })
            return display


        def slugify(title):
            slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
            return slug or "untitled"


        def publish_blog(title, text, when, draft):
            front = [
                "+++",
                'title = "' + title.replace('"', '\\"') + '"',
                "date = " + when.strftime("%Y-%m-%d"),
            ]
            if draft:
                front.append("draft = true")
            front.append("+++")
            content = "\n".join(front) + "\n\n" + text + "\n"
            encoded = base64.b64encode(content.encode()).decode()
            slug = slugify(title)
            for candidate in [slug] + [slug + "-" + str(i) for i in range(2, 10)]:
                try:
                    api("POST", "/contents/content/blog/" + candidate + ".md", {
                        "branch": branch,
                        "message": "blog: " + title + " (via email)",
                        "content": encoded,
                    })
                    return candidate
                except urllib.error.HTTPError as err:
                    if err.code != 422:
                        raise
            raise RuntimeError("no free slug for " + slug)


        def process(path):
            with open(path, "rb") as f:
                msg = email.message_from_binary_file(f, policy=policy.default)
            if recipient not in addresses(
                msg, "to", "cc", "delivered-to", "x-original-to"
            ):
                return "rejected", "not addressed to the posting address"
            senders = addresses(msg, "from")
            if allowed_sender not in senders:
                return "rejected", "sender not allowed: " + ", ".join(senders)
            subject = re.sub(r"\s+", " ", str(msg["subject"] or "")).strip()
            text = body_text(msg)
            if not text:
                return "failed", "no plain-text body"
            when = message_date(msg)
            if subject.lower() in ("", "now"):
                publish_now(text, when)
                return "done", "now update"
            if re.fullmatch(r"https?://\S+", subject, flags=re.I):
                display = publish_bookmark(subject, re.sub(r"\s+", " ", text))
                return "done", "bookmark " + display
            draft = subject.lower().startswith("draft:")
            if draft:
                subject = subject[len("draft:"):].strip()
            slug = publish_blog(subject, text, when, draft)
            return "done", "blog post " + slug


        outcomes = []
        for path in sorted((maildir / "new").iterdir()):
            if not path.is_file():
                continue
            try:
                outcome, detail = process(path)
            except Exception as err:
                outcome, detail = "failed", repr(err)
            dest = {"done": "cur", "rejected": ".rejected", "failed": ".failed"}
            destdir = maildir / dest[outcome]
            destdir.mkdir(exist_ok=True)
            path.rename(destdir / (path.name + (":2,S" if outcome == "done" else "")))
            print(path.name + ": " + outcome + " (" + detail + ")", flush=True)
            outcomes.append(outcome)

        sys.exit(1 if "failed" in outcomes else 0)
      '';
    in
    {
      sops.secrets = {
        email-post-recipient = {
          sopsFile = ../../secrets/email-post.yaml;
          key = "recipient";
          owner = "email-post";
        };
        email-post-forgejo-token = {
          sopsFile = ../../secrets/email-post.yaml;
          key = "forgejo_token";
          owner = "email-post";
        };
      };

      networking.firewall.allowedTCPPorts = [ 25 ];

      services = {
        telegram-alerts.units = [
          "email-post-process"
          "opensmtpd"
        ];

        opensmtpd = {
          enable = true;
          setSendmail = false;
          serverConfiguration = ''
            table virtuals { "@" = "email-post" }
            listen on 0.0.0.0 port 25 hostname ${domain}
            listen on :: port 25 hostname ${domain}
            action "deliver" maildir "${maildir}" virtual <virtuals>
            match from any for domain "${domain}" action "deliver"
          '';
        };
      };

      users.users.email-post = {
        isSystemUser = true;
        group = "email-post";
        home = maildir;
      };
      users.groups.email-post = { };

      systemd = {
        tmpfiles.rules = [
          "d ${maildir} 0750 email-post email-post -"
          "d ${maildir}/new 0750 email-post email-post -"
          "d ${maildir}/cur 0750 email-post email-post -"
          "d ${maildir}/tmp 0750 email-post email-post -"
        ];

        services.email-post-process = {
          description = "Publish emailed posts to the website";
          after = [
            "network-online.target"
            "forgejo.service"
          ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            MAILDIR = maildir;
            FORGEJO_API = "https://git.ily.rs/api/v1/repos/l/website";
            BRANCH = "master";
            ALLOWED_SENDER = email;
            RECIPIENT_FILE = config.sops.secrets.email-post-recipient.path;
            TOKEN_FILE = config.sops.secrets.email-post-forgejo-token.path;
          };
          serviceConfig = {
            Type = "oneshot";
            User = "email-post";
            Group = "email-post";
            ExecStart = "${pkgs.python3}/bin/python3 ${processScript}";
          };
        };

        paths.email-post-trigger = {
          description = "Watch for newly delivered post emails";
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            DirectoryNotEmpty = "${maildir}/new";
            Unit = "email-post-process.service";
          };
        };
      };
    };
}
