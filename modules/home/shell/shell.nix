{
  config,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:

/*
  TODO:

  Ble.sh was used in the past for zsh-like inline suggestions but broke numerous
  shell integrations. We could consider implementing it again but it would need
  to be done carefully.

  Alternatively: lightweight completion suggestions and command highlighting
  would go a long way.
*/

# Interactive shell substrate. This module owns broadly useful Bash behavior and
# command-line tools, while exposing aliases as options so user profiles can
# keep personal shorthand out of the reusable layer. NixOS repair aliases only
# appear when Home Manager is evaluated with an `osConfig`.
let
  cfg = config.theorem.home.shell.shell;
  hasOsConfig = osConfig != null;
  run0Enabled = hasOsConfig && (osConfig.theorem.nixos.security.run0-sudo.enable or false);
  sudoEnabled = hasOsConfig && (osConfig.theorem.nixos.security.sudo.enable or false);

  defaultElevationCommand =
    if run0Enabled then
      "run0"
    else if sudoEnabled then
      "sudo"
    else
      "sudo";

  defaultAliases = {
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
  };
in
{
  options.theorem.home.shell.shell = {
    enable = lib.mkEnableOption "interactive shell"; # FIXME: Should be enabled by default.

    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = defaultAliases;
      description = ''
        Base shell aliases provided by the reusable shell theorem. Keep this set
        unsurprising; personal shortcuts and project-specific habits belong in
        user profiles through `extraAliases`.
      '';
    };

    extraAliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "User or host aliases appended to the reusable shell aliases.";
    };

    nixosAliases = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = hasOsConfig; # FIXME: This should also depend on whether `nh` is enabled. Not just when the system exists.
        defaultText = lib.literalExpression "osConfig != null";
        description = ''
          Install short NixOS repair aliases. Defaults on only when this Home
          profile is evaluated as part of a NixOS system, so standalone personal
          Home flakes do not receive aliases that depend on host state.
        '';
      };

      flake = lib.mkOption {
        type = lib.types.str;
        default = "$NIXOS_CONFIG_FLAKE"; # FIXME: Use the repo path where able. There is no guarantee this variable will be set.
        description = "Flake reference used by the short NixOS repair aliases.";
      };
    };

    elevationAlias = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install `please` as a retry alias for the active elevation command.";
      };

      command = lib.mkOption {
        type = lib.types.str;
        default = defaultElevationCommand;
        defaultText = lib.literalExpression ''
          if osConfig.theorem.nixos.security.run0-sudo.enable then "run0"
          else if osConfig.theorem.nixos.security.sudo.enable then "sudo"
          else "sudo"
        '';
        description = ''
          Elevation command used by the `please` alias. It follows the active
          NixOS elevation theorem when available and remains overrideable for
          standalone Home profiles.
        '';
      };
    };
  };

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

      shellAliases =
        cfg.aliases
        // lib.optionalAttrs cfg.nixosAliases.enable {
          ns = "nh os switch ${cfg.nixosAliases.flake}";
          nb = "nh os boot ${cfg.nixosAliases.flake}";
          nt = "nh os test ${cfg.nixosAliases.flake}";
          nd = "nh os dry ${cfg.nixosAliases.flake}";
          # TODO: Add convenience aliases for the other "nh" possible commands.
        }
        // lib.optionalAttrs cfg.elevationAlias.enable {
          please = "${cfg.elevationAlias.command} $(fc -ln -1)"; # FIXME: Does this trick work for run0? It works for sudo. It essentially re-runs the last command with sudo, I think.
        }
        // cfg.extraAliases;

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
        ".bash_history" # TODO: Make sure this is persisting correctly.
      ];
    };
  };
}
