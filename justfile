[private]
default:
    @just --list

[doc("Build and activate the new configuration immediately")]
deploy:
    sudo nixos-rebuild switch --flake .#vm0

[doc("Validate the flake and all host configs without building")]
check:
    nix flake check

[doc("Pull latest from Forgejo, then build and activate")]
update:
    git pull
    sudo nixos-rebuild switch --flake .#vm0

[doc("Deploy to the lab from another machine (builds on the lab)")]
deploy-remote:
    nix run --inputs-from . nixpkgs#nixos-rebuild -- switch --flake .#vm0 --target-host lab --build-host lab --use-remote-sudo

[doc("Lint nix files with statix and deadnix")]
lint:
    nix run nixpkgs#statix -- check .
    nix run nixpkgs#deadnix -- .
