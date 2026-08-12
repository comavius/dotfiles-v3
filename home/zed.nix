/*
  This file is a derived work of https://github.com/ryan4yin/nix-config/blob
  /88e916b63e7b5f1af4ddb80fbef1b084d13816b0/home/base/gui/zed-editor.nix,
  which is distributed under the license below.

    MIT License

    Copyright (c) 2023 Ryan Yin

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

{ lib, ... }:
{

  programs.zed-editor = {
    enable = true;
    mutableUserSettings = false;

    userSettings = {
      # Language-specific settings
      languages = {
        Python = {
          formatter.language_server.name = "ruff";
          language_servers = [
            "ty"
            "ruff"
            "!basedpyright"
            "!pyrefly"
            "!pyright"
            "!pylsp"
          ];
        };
        Rust = {
          hard_tabs = false;
          formatter.language_server.name = "rust-analyzer";
          language_servers = [
            "rust-analyzer"
            "!rustc"
          ];
        };
        Go = {
          formatter.language_server.name = "gopls";
          language_servers = [
            "gopls"
            "!goimports"
          ];
        };
      };

      # Terminal
      terminal = {
        detect_venv = "off";
      };

      # Editor behavior
      auto_signature_help = true;
      autosave = "off";
      code_lens = "on";
      completion_menu_item_kind = "symbol";
      completions.lsp_fetch_timeout_ms = 2000;
      diagnostics.inline.enabled = true;
      document_folding_ranges = "off";
      inlay_hints.enabled = true;
      minimap.show = "auto";
      relative_line_numbers = "enabled";
      semantic_tokens = "combined";
      soft_wrap = "editor_width";
      vertical_scroll_margin = 5.0;
      which_key.enabled = true;
      indent_guides = {
        background_coloring = "indent_aware";
        coloring = "indent_aware";
      };

      # Search
      search.regex = true;
      use_smartcase_search = true;

      # Formatting
      prettier.allowed = true;

      # UI chrome
      tabs = {
        file_icons = true;
        git_status = true;
      };
      title_bar = {
        show_branch_status_icon = true;
        show_menus = false;
        show_user_menu = true;
      };

      # Git
      git.inline_blame.show_commit_summary = true;

      # Fonts
      ui_font_family = lib.mkDefault "LXGW WenKai Screen";
      ui_font_size = lib.mkDefault 16.0;
      buffer_font_family = lib.mkDefault "Maple Mono NF CN";
      buffer_font_size = lib.mkDefault 14.0;
      agent_ui_font_size = lib.mkDefault 16.0;
      agent_buffer_font_size = lib.mkDefault 15.0;

      # App behavior
      auto_update = false;
      cli_default_open_behavior = "existing_window";

      # AI/editor integrations
      agent.play_sound_when_agent_done = "when_hidden";
      agent_servers = {
        opencode.type = "registry";
        cursor.type = "registry";
        codex-acp.type = "registry";
        claude-acp.type = "registry";
      };

      # Privacy
      edit_predictions.allow_data_collection = "no";
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
    };

    extensions = [
      "catppuccin"
      "dockerfile"
      "just"
      "nix"
      "toml"
    ];
  };
}
