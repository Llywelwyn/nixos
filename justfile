[private]
default:
    @just --list

[doc("Deploy a host: locally if it matches this machine, otherwise over ssh")]
deploy host=`uname -n`:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{host}}" = "$(uname -n)" ]; then
        nixos-rebuild build --flake .#{{host}}
        nix run --inputs-from . nixpkgs#nvd -- diff /run/current-system ./result
        sudo nixos-rebuild switch --flake .#{{host}}
        rm result
    else
        nix run --inputs-from . nixpkgs#nixos-rebuild -- switch --flake .#{{host}} --target-host {{host}} --build-host {{host}} --sudo
        ssh {{host}} 'nvd diff "$(ls -dv /nix/var/nix/profiles/system-*-link | tail -n 2 | head -n 1)" /run/current-system'
    fi

[doc("Update all flake inputs")]
update:
    nix flake update

[doc("Validate the flake and all host configs without building")]
check:
    nix flake check

[doc("Format nix files")]
fmt:
    nix fmt

[doc("Lint nix files with statix and deadnix")]
lint:
    nix run --inputs-from . nixpkgs#statix -- check .
    nix run --inputs-from . nixpkgs#deadnix -- .
