{ lib, ... }:
{
  modules.cli = {
    options.neovim = {
      enable = lib.mkEnableOption "Neovim";
      vimAlias = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      viAlias = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      defaultEditor = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      colorscheme = lib.mkOption {
        type = lib.types.str;
        default = "everforest";
      };
      background = lib.mkOption {
        type = lib.types.str;
        default = "soft";
      };
      transparent = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable transparent background";
      };
      lsp = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        servers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "gopls"
            "rust_analyzer"
            "nil_ls"
            "clangd"
            "ruff"
          ];
        };
      };
      tabWidth = lib.mkOption {
        type = lib.types.int;
        default = 2;
      };
      extraPlugins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
      };
    };

    module =
      {
        node,
        pkgs,
        lib,
        ...
      }:
      lib.mkIf node.cli.neovim.enable (
        let
          cfg = node.cli.neovim;

          basePlugins = with pkgs.vimPlugins; [
            everforest
            vim-lastplace
            editorconfig-nvim
          ];

          lspPlugins = with pkgs.vimPlugins; [
            nvim-lspconfig
            nvim-cmp
            cmp-nvim-lsp
            luasnip
          ];

          uiPlugins = with pkgs.vimPlugins; [
            mini-nvim
            which-key-nvim
            leap-nvim
          ];

          extraPluginPkgs = map (p: pkgs.vimPlugins.${p}) cfg.extraPlugins;

          allPlugins =
            basePlugins ++ (lib.optionals cfg.lsp.enable lspPlugins) ++ uiPlugins ++ extraPluginPkgs;

          lspServersLua = "{" + lib.concatMapStringsSep ", " (s: ''"${s}"'') cfg.lsp.servers + "}";

          luaConfig = ''
            vim.opt.background = "dark"
            vim.opt.number = true
            vim.opt.termguicolors = true
            vim.opt.tabstop = ${toString cfg.tabWidth}
            vim.opt.shiftwidth = ${toString cfg.tabWidth}
            vim.opt.expandtab = true
            vim.opt.smarttab = true
            vim.opt.timeoutlen = 500
            vim.opt.scrolloff = 5

            -- 自动缩进
            vim.opt.autoindent = true
            vim.opt.smartindent = true
            vim.opt.cindent = true

            vim.g.everforest_background = "${cfg.background}"
            ${lib.optionalString cfg.transparent ''vim.g.everforest_transparent_background = 1''}
            vim.cmd.colorscheme("${cfg.colorscheme}")

            ${lib.optionalString cfg.transparent ''
              vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
              vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
              vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
              vim.api.nvim_set_hl(0, "LineNr", { bg = "NONE" })
            ''}

            ${lib.optionalString cfg.lsp.enable ''
              local capabilities = require("cmp_nvim_lsp").default_capabilities()
              local servers = ${lspServersLua}
              for _, lsp in pairs(servers) do
                vim.lsp.enable(lsp)
                vim.lsp.config(lsp, {
                  capabilities = capabilities,
                  settings = {
                    ["nil"] = {
                      formatting = {
                        command = { "nixfmt" }
                      }
                    },
                  }
                })
              end

              vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
              vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
              vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
              vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

              vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(ev)
                  vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
                  local opts = { buffer = ev.buf }
                  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
                  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
                  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
                  vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
                  vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
                  vim.keymap.set("n", "<space>wl", function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                  end, opts)
                  vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
                  vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
                  vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
                  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                  vim.keymap.set("n", "<space>f", function()
                    vim.lsp.buf.format { async = true }
                  end, opts)
                end,
              })

              local luasnip = require("luasnip")
              local cmp = require("cmp")
              cmp.setup {
                snippet = {
                  expand = function(args)
                    luasnip.lsp_expand(args.body)
                  end,
                },
                mapping = cmp.mapping.preset.insert({
                  ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                  ["<C-f>"] = cmp.mapping.scroll_docs(4),
                  ["<C-Space>"] = cmp.mapping.complete(),
                  ["<CR>"] = cmp.mapping.confirm {
                    behavior = cmp.ConfirmBehavior.Replace,
                    select = true,
                  },
                  ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                      cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                      luasnip.expand_or_jump()
                    else
                      fallback()
                    end
                  end, { "i", "s" }),
                  ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                      cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then
                      luasnip.jump(-1)
                    else
                      fallback()
                    end
                  end, { "i", "s" }),
                }),
                sources = {
                  { name = "nvim_lsp" },
                  { name = "luasnip" },
                },
              }

              vim.diagnostic.config({ virtual_text = true })
            ''}

            require("mini.statusline").setup()
            require("which-key").setup {}

            vim.keymap.set({"n", "x", "o"}, "s", "<Plug>(leap)")
            vim.keymap.set("n", "S", "<Plug>(leap-from-window)")

            ${cfg.extraConfig}
          '';

          customNeovim = pkgs.wrapNeovim pkgs.neovim-unwrapped {
            viAlias = cfg.viAlias;
            vimAlias = cfg.vimAlias;
            configure = {
              packages.nixBundle.start = allPlugins;
              customRC = ''
                lua << EOF
                ${luaConfig}
                EOF
              '';
            };
          };
        in
        {
          environment.systemPackages = [ customNeovim ];
          environment.variables = lib.mkIf cfg.defaultEditor {
            EDITOR = "nvim";
          };
        }
      );
  };
}
