{ inputs, ... }:
{
  flake.modules.nixos.desktop = { pkgs, ... }:
    let
      me3-unwrapped = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.me3;
      me3 = pkgs.symlinkJoin {
        name = "me3";
        paths = [ me3-unwrapped ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/me3 \
            --prefix LD_LIBRARY_PATH : ${pkgs.libglvnd}/lib:/run/opengl-driver/lib
        '';
      };
    in
    {
      environment.systemPackages = [ me3 ];
    };
}
