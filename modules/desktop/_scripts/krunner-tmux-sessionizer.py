"""KRunner DBus runner: type a project name, open or focus its tmux session."""

import subprocess
import time

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

BUS_NAME = "rs.ily.tmuxsessionizer"
OBJECT_PATH = "/runner"
IFACE = "org.kde.krunner1"
CACHE_TTL = 3  # seconds; krunner calls Match on every keystroke


class Runner(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(dbus.service.BusName(BUS_NAME, bus), OBJECT_PATH)
        self._cached_at = 0.0
        self._entries = []

    def _list(self):
        now = time.monotonic()
        if now - self._cached_at > CACHE_TTL:
            out = subprocess.run(
                ["tmux-sessionizer", "--list"], capture_output=True, text=True
            ).stdout
            self._entries = []
            for line in out.splitlines():
                key, _, display = line.partition("\t")
                if key:
                    self._entries.append((key, display or key))
            self._cached_at = now
        return self._entries

    @dbus.service.method(IFACE, in_signature="s", out_signature="a(sssida{sv})")
    def Match(self, query):
        q = query.strip().lower()
        if len(q) < 2:
            return []
        tokens = q.split()
        matches = []
        for key, display in self._list():
            if not all(t in display.lower() for t in tokens):
                continue
            session = key.startswith("SESSION:")
            name = key.removeprefix("SESSION:") if session else key.rsplit("/", 1)[-1]
            name = name.lower()
            if name == q:
                mtype, relevance = 100, 1.0
            elif name.startswith(q):
                mtype, relevance = 30, 0.8
            else:
                mtype, relevance = 30, 0.6
            if session:
                relevance = min(1.0, relevance + 0.1)
            subtext = "tmux session" if session else "project"
            matches.append(
                (key, display, "utilities-terminal", mtype, relevance, {"subtext": subtext})
            )
        matches.sort(key=lambda m: m[4], reverse=True)
        return matches[:8]

    @dbus.service.method(IFACE, out_signature="a(sss)")
    def Actions(self):
        return []

    @dbus.service.method(IFACE, in_signature="ss")
    def Run(self, match_id, action_id):
        subprocess.Popen(["tmux-sessionizer", "--open", match_id])


def main():
    DBusGMainLoop(set_as_default=True)
    Runner(dbus.SessionBus())
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
