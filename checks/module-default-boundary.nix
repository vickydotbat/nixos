{
  inputs,
  pkgs,
}:

pkgs.runCommand "module-default-boundary"
  {
    nativeBuildInputs = [ pkgs.ripgrep ];
    src = inputs.self;
  }
  ''
    cd "$src"

    if rg -n --glob '*.nix' '\blib\.mkDefault\s*\{' modules users hosts lib checks flake.nix; then
      cat >&2 <<'EOF'
    Whole-attrset defaults are too easy to lose when another module sets one
    child value. Use lib.mkMerge with lib.mkDefault on the leaves instead.
    EOF
      exit 1
    fi

    touch "$out"
  ''
