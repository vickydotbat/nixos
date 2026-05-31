{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    historyControl = [
      "ignoreboth"
      "erasedups"
    ];
    historyFileSize = 200000;
    historyIgnore = [
      "bg"
      "cd"
      "exit"
      "fg"
      "history"
      "jobs"
      "ls"
      "pwd"
    ];
    historySize = 50000;

    shellOptions = [
      "histappend"
      "cmdhist"
      "checkjobs"
      "checkwinsize"
      "autocd"
      "cdspell"
      "dirspell"
      "extglob"
      "globstar"
    ];

    sessionVariables = {
      BAT_PAGER = "less -FR";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      PAGER = "less -FR";
    };

    shellAliases = {
      cat = "bat --paging=never";
      cp = "cp -i";
      df = "df -h";
      du = "du -h";
      grep = "grep --color=auto";
      mkdir = "mkdir -p";
      mv = "mv -i";
      rm = "rm -I";
    };

    initExtra = ''
      bind 'set completion-ignore-case on'
      bind 'set completion-map-case on'
      bind 'set mark-symlinked-directories on'
      bind 'set show-all-if-ambiguous on'
      bind 'set colored-stats on'
      bind 'set visible-stats on'

      if [[ -r "${pkgs.blesh}/share/blesh/ble.sh" && $TERM != "dumb" ]]; then
        source "${pkgs.blesh}/share/blesh/ble.sh" --attach=none
        ble-face -s auto_complete fg=242,bg=none
        ble-face -s syntax_error fg=203,bg=none
        ble-face -s syntax_varname fg=110,bg=none
        ble-bind -m auto_complete -f C-n auto_complete/insert-on-end
        ble-bind -m auto_complete -f C-p auto_complete/insert-on-end
        [[ ''${BLE_VERSION-} ]] && ble-attach
      fi
    '';
  };

  home.packages = [
    pkgs.blesh
    pkgs.jq
  ];

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = false;
      enter_accept = false;
      filter_mode_shell_up_key_binding = "session";
      search_mode = "fuzzy";
      style = "compact";
      update_check = false;
    };
  };

  programs.bat = {
    enable = true;
    config = {
      italic-text = "always";
      pager = "less -FR";
      style = "numbers,changes,header";
      theme = "TwoDark";
    };
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batgrep
      batman
      batwatch
    ];
  };

  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    ignoreCase = true;
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };

  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    colors = "auto";
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
    git = true;
    icons = "auto";
  };

  programs.fd = {
    enable = true;
    hidden = true;
    ignores = [
      ".cache/"
      ".git/"
      "node_modules/"
      "result"
    ];
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --level=2 --color=always --icons=auto {} | head -200'"
    ];
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
      "--cycle"
      "--bind=ctrl-u:preview-page-up,ctrl-d:preview-page-down"
    ];
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --style=numbers --color=always --line-range=:200 {}'"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--glob=!.git/*"
      "--hidden"
      "--max-columns=200"
      "--max-columns-preview"
      "--smart-case"
    ];
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
      directory = {
        truncation_length = 4;
        truncate_to_repo = false;
      };
      git_status = {
        ahead = "ahead ";
        behind = "behind ";
        conflicted = "conflicts ";
        deleted = "deleted ";
        diverged = "diverged ";
        modified = "modified ";
        renamed = "renamed ";
        staged = "staged ";
        stashed = "stashed ";
        untracked = "untracked ";
      };
      nix_shell = {
        format = "via [$symbol$state( \\($name\\))]($style) ";
        symbol = "nix ";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };
}
