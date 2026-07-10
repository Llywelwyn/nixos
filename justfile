[private]
default:
    @just --list

[doc("Deploy a host: locally if it matches this machine, otherwise over ssh")]
deploy host=`uname -n`:
    #!/usr/bin/env bash
    if [ "{{host}}" = "$(uname -n)" ]; then
        sudo nixos-rebuild switch --flake .#{{host}}
    else
        nix run --inputs-from . nixpkgs#nixos-rebuild -- switch --flake .#{{host}} --target-host {{host}} --build-host {{host}} --use-remote-sudo
    fi

[doc("Validate the flake and all host configs without building")]
check:
    nix flake check

[doc("Lint nix files with statix and deadnix")]
lint:
    nix run nixpkgs#statix -- check .
    nix run nixpkgs#deadnix -- .
