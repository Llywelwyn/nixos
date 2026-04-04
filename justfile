set shell := ["sudo", "bash", "-c"]

[private]
default:
    @just --list

[doc("Build and activate the new configuration immediately")]
deploy:
    nixos-rebuild switch --flake /etc/nixos#lab

[doc("Build the configuration without activating it")]
check:
    nixos-rebuild dry-build --flake /etc/nixos#lab

[doc("Pull latest from Forgejo, then build and activate")]
update:
    git pull
    nixos-rebuild switch --flake /etc/nixos#lab
