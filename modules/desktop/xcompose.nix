{
  flake.modules.homeManager.desktop = {
    programs.plasma.input.keyboard.options = [ "compose:caps" ];

    home.file.".XCompose".text = ''
      # https://tanukicomputing.neocities.org/posts/Compose_Key_Cheat_Sheet

      <Multi_key> <b> <a>         : "#!/usr/bin/env bash"
      <Multi_key> <at>            : "lewis@wynne.rs"
      <Multi_key> <minus>         : "—"
      <Multi_key> <space>         : " | "
      <Multi_key> <o> <r>         : " || "
      <Multi_key> <slash>         : "\\"
      <Multi_key> <t> <f>         : "🏳️‍⚧️"
    '';
  };
}
