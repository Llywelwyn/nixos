{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      programs.nixvim = {
        plugins.treesitter = {
          enable = true;
          settings.highlight.enable = true;
        };
        plugins.treesitter-context.enable = true;

        plugins.mini = {
          enable = true;
          mockDevIcons = true;
          modules = {
            icons = { };
            pairs = { };
            diff = { };
            git = { };
          };
        };

        plugins.blink-cmp = {
          enable = true;
          settings = {
            keymap.preset = "super-tab";
            appearance.nerd_font_variant = "mono";
            completion.documentation = {
              auto_show = true;
              auto_show_delay_ms = 0;
            };
            sources.default = [
              "lsp"
              "path"
              "buffer"
            ];
            fuzzy.implementation = "prefer_rust_with_warning";
            cmdline = {
              keymap.preset = "inherit";
              completion.menu.auto_show = true;
            };
          };
        };

        plugins.fzf-lua = {
          enable = true;
          settings = {
            winopts.preview = {
              vertical = "down:65%";
              flip_columns = 120;
            };
            files.git_icons = true;
          };
        };

        plugins.which-key = {
          enable = true;
          settings = {
            preset = "helix";
            delay.__raw = "function(ctx) return ctx.plugin and 0 or 20 end";
            spec = [
              {
                __unkeyed-1 = "<leader>f";
                group = "find";
              }
              {
                __unkeyed-1 = "<leader>g";
                group = "git";
              }
              {
                __unkeyed-1 = "<leader>c";
                group = "lsp actions";
                icon.__raw = ''(require("mini.icons").get("lsp", "class"))'';
              }
            ];
          };
        };

        plugins.leap = {
          enable = true;
          package = pkgs.vimUtils.buildVimPlugin {
            pname = "leap.nvim";
            version = "2026-05-09";
            src = pkgs.fetchgit {
              url = "https://codeberg.org/andyg/leap.nvim";
              rev = "940bc5e716a8cde63bd47e1b13f30fd9075ec0c8";
              hash = "sha256-bwyZzOq0OGYMqJks3ijEWD3wgdbTNhUwNT96tWUNXK4=";
            };
          };
        };

        plugins.oil = {
          enable = true;
          settings = {
            use_default_keymaps = false;
            view_options.show_hidden = true;
            keymaps = {
              "g?" = {
                __unkeyed-1 = "actions.show_help";
                mode = "n";
              };
              "<CR>" = "actions.select";
              "<leader><leader>" = "actions.preview";
              "-" = {
                __unkeyed-1 = "actions.parent";
                mode = "n";
              };
              "=" = {
                __unkeyed-1 = "actions.open_cwd";
                mode = "n";
              };
              "+" = {
                __unkeyed-1 = "actions.cd";
                mode = "n";
              };
              "<leader>;" = {
                __unkeyed-1 = "actions.select";
                opts.vertical = true;
              };
              "<leader>-" = {
                __unkeyed-1 = "actions.select";
                opts.horizontal = true;
              };
              "<leader>x" = "actions.open_external";
              "g." = {
                __unkeyed-1 = "actions.toggle_hidden";
                mode = "n";
              };
            };
            float = {
              padding = 2;
              max_width = 0;
              max_height = 0;
              preview_split = "auto";
            };
          };
        };

        plugins.sleuth.enable = true;
        plugins.conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = {
              lua = [ "stylua" ];
              python = [
                "isort"
                "black"
              ];
              javascript = {
                __unkeyed-1 = "prettierd";
                __unkeyed-2 = "prettier";
                stop_after_first = true;
              };
            };
            default_format_opts.lsp_format = "fallback";
            format_on_save.timeout_ms = 500;
            formatters.shfmt.append_args = [
              "-i"
              "2"
            ];
          };
        };

        plugins.yanky = {
          enable = true;
          settings.preserve_cursor_position.enabled = true;
        };

        plugins.neoscroll = {
          enable = true;
          settings.duration_multiplier = 0.1;
        };

        extraPlugins = [ pkgs.vimPlugins.tmux-nvim ];

        extraConfigLua = ''
          require("tmux").setup({
            copy_sync = { enable = true, sync_clipboard = false },
            resize = { resize_step_x = 5, resize_step_y = 3 },
          })

          require("leap").opts.preview = function(ch0, ch1, ch2)
            return not (
              ch1:match("%s")
              or (ch0:match("%a") and ch1:match("%a") and ch2:match("%a"))
            )
          end
          require("leap").opts.on_beacons = function(targets, _, _)
            for _, t in ipairs(targets) do
              if t.label and t.beacon then
                t.beacon[1] = 0
              end
            end
          end
          vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
          require("leap").opts.equivalence_classes = {
            " \t\r\n",
            "([{",
            ")]}",
            "'\"`",
          }
          vim.keymap.set({ "n", "x", "o" }, "s", function()
            require("leap").leap({ target_windows = vim.api.nvim_list_wins() })
            if vim.fn.mode() == "v" then
              vim.cmd("normal! iw")
            end
          end)
          vim.keymap.set({ "n", "o" }, "gs", function()
            require("leap.remote").action({
              input = vim.fn.mode(true):match("o") and "" or "v",
            })
          end)
          vim.api.nvim_create_autocmd("User", {
            pattern = "RemoteOperationDone",
            group = vim.api.nvim_create_augroup("LeapRemote", {}),
            callback = function(event)
              if vim.v.operator == "y" and event.data.register == '"' then
                vim.cmd("normal! p")
              end
            end,
          })
        '';

        extraPackages = with pkgs; [
          black
          fd
          isort
          prettier
          prettierd
          ripgrep
          shfmt
          stylua
        ];
      };
    };
}
