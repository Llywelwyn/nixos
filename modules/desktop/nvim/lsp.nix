{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      programs.nixvim = {
        plugins.lsp = {
          enable = true;
          servers = {
            astro.enable = true;
            clangd.enable = true;
            gopls.enable = true;
            lua_ls.enable = true;
            nixd.enable = true;
            rust_analyzer = {
              enable = true;
              installCargo = true;
              installRustc = true;
            };
          };
        };

        plugins.lazydev = {
          enable = true;
          settings.library = [
            {
              path = "\${3rd}/luv/library";
              words = [ "vim%.uv" ];
            }
          ];
        };

        extraPlugins = [ pkgs.vimPlugins.roslyn-nvim ];
        extraPackages = [ pkgs.roslyn-ls ];
        extraConfigLua = ''
          vim.lsp.config("roslyn", {
            settings = {
              ["csharp|inlay_hints"] = {
                csharp_enable_inlay_hints_for_implicit_object_creation = true,
                csharp_enable_inlay_hints_for_implicit_variable_types = true,
              },
              ["csharp|code_lens"] = {
                dotnet_enable_references_code_lens = true,
              },
            },
          })
          require("roslyn").setup({})
        '';
      };
    };
}
