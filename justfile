[private]
default:
    @just --list

[doc("Build and activate the new configuration immediately")]
deploy:
    sudo nixos-rebuild switch --flake /etc/nixos#lab

[doc("Build the configuration without activating it")]
check:
    sudo nixos-rebuild dry-build --flake /etc/nixos#lab

[doc("Pull latest from Forgejo, then build and activate")]
update:
    git pull
    sudo nixos-rebuild switch --flake /etc/nixos#lab
