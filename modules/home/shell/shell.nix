{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.shell.shell;
in
{
  options.theorem.home.shell.shell.enable = lib.mkEnableOption "interactive shell";

  config = lib.mkIf cfg.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;

      historyFile = "$HOME/.bash_history";
      historySize = 100000;
      historyFileSize = 100000;
      historyControl = [
        "ignoreboth"
        "erasedups"
      ];
      historyIgnore = [
        "bg"
        "cd"
        "exit"
        "fg"
        "history"
        "jobs"
        "ls"
        "pwd"
        "ll"
      ];

      shellOptions = [
        "histappend"
        "cmdhist"
        "lithist"
        "checkjobs"
        "checkwinsize"
        "autocd"
        "cdspell"
        "dirspell"
        "extglob"
        "globstar"
      ];

      sessionVariables = {
        PAGER = "less";
        LESS = "-FR";
        LESSHISTFILE = "-";
      };

      shellAliases = {
        cp = "cp -i";
        df = "df -h";
        du = "du -h";
        grep = "grep --color=auto";
        mkdir = "mkdir -p";
        mv = "mv -i";
        rm = "rm -I";

        ls = "eza";
        ll = "eza -lah --git";
        la = "eza -a";
        tree = "eza --tree";

        ns = "nh os switch $NIXOS_CONFIG_FLAKE";
        nb = "nh os boot $NIXOS_CONFIG_FLAKE";
        nt = "nh os test $NIXOS_CONFIG_FLAKE";
        nd = "nh os dry $NIXOS_CONFIG_FLAKE";

        # Pretty please?
        please = "sudo $(fc -ln -1)";
      };

      initExtra = ''
        _bash_history_sync() {
          history -a
          history -n
        }

        case ";$PROMPT_COMMAND;" in
          *";_bash_history_sync;"*) ;;
          *) PROMPT_COMMAND="_bash_history_sync''${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
        esac

        bind 'set completion-ignore-case on'
        bind 'set completion-map-case on'
        bind 'set mark-symlinked-directories on'
        bind 'set show-all-if-ambiguous on'
        bind 'set colored-stats on'
        bind 'set visible-stats on'

        # Prefix-aware history search:
        # Type "nix", press Up, and Bash searches previous commands starting with "nix".
        bind '"\e[A": history-search-backward'
        bind '"\e[B": history-search-forward'
        bind '"\e[1;5A": history-search-backward'
        bind '"\e[1;5B": history-search-forward'
      '';
    };

    programs.jq = {
      enable = true;
    };

    programs.fastfetch = {
      enable = true;
    };

    programs.atuin = {
      enable = true;
      enableBashIntegration = true;

      # Keeps normal up-arrow history behavior.
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

      # Remove this if Atuin owns history:
      # historyWidgetOptions = [
      #   "--sort"
      #   "--exact"
      # ];
    };

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      options = [ "--cmd cd" ];
    };

    programs.lazygit = {
      enable = true;
      enableBashIntegration = true;
    };

    # See: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/nano.nix
    xdg.configFile."nano/nanorc".text = ''
      include "${pkgs.nano}/share/nano/*.nanorc"

      set atblanks
      set autoindent
      set constantshow
      set guidestripe 100
      set indicator
      set linenumbers
      set mouse
      set smarthome
      set softwrap
      set tabsize 4
      set zap
    '';
    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        ".local/share/atuin"
        ".local/share/zoxide"
      ];

      files = [
        ".bash_history"
      ];
    };
  };
}
