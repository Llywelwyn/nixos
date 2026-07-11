{ lib, flake-parts-lib, ... }:
{
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    meta = lib.mkOption {
      type = lib.types.submodule {
        options.username = lib.mkOption {
          type = lib.types.str;
          description = "Primary user account name.";
        };
        options.email = lib.mkOption {
          type = lib.types.str;
          description = "Primary contact email.";
        };
      };
    };
  };

  config.flake.meta = {
    username = "l";
    email = "l@ily.rs";
  };
}
