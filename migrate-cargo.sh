#!/usr/bin/env bash
# Anchor 0.29 → 0.30 Cargo.toml migration script
# ast-grep does not support TOML, so we handle Cargo.toml changes separately.
# Supports both macOS (BSD sed) and Linux (GNU sed).

set -euo pipefail

WITH_IDL_BUILD=0
CARGO_TARGET=""

usage() {
  cat <<'EOF'
Usage:
  migrate-cargo.sh [--with-idl-build] [Cargo.toml]

Options:
  --with-idl-build  Add "idl-build" to anchor-lang features.
                    Default behavior does NOT force this feature.
  -h, --help        Show this help message.

Examples:
  # Migrate all Cargo.toml files under current directory
  bash migrate-cargo.sh

  # Migrate one file
  bash migrate-cargo.sh programs/your-program/Cargo.toml

  # Migrate and force idl-build feature
  bash migrate-cargo.sh --with-idl-build programs/your-program/Cargo.toml
EOF
}

# Cross-platform sed: macOS uses -i '', Linux uses -i
if [[ "$OSTYPE" == darwin* ]]; then
  SED_I=(-i '')
else
  SED_I=(-i)
fi

migrate_one() {
  local CARGO_TOML="$1"

  if [ ! -f "$CARGO_TOML" ]; then
    echo "Error: $CARGO_TOML not found"
    return 1
  fi

  echo "Migrating $CARGO_TOML from Anchor 0.29 to 0.30..."

# 1. Update anchor-lang version (optionally add idl-build feature)

# Case: anchor-lang = "0.29.x" (simple string version)
  if grep -q 'anchor-lang = "0\.29\.' "$CARGO_TOML"; then
    if [ "$WITH_IDL_BUILD" -eq 1 ]; then
      sed "${SED_I[@]}" 's|anchor-lang = "0\.29\.[^"]*"|anchor-lang = { version = "0.30.1", features = ["idl-build"] }|g' "$CARGO_TOML"
      echo "  ✓ Updated anchor-lang to 0.30.1 with idl-build feature"
    else
      sed "${SED_I[@]}" 's|anchor-lang = "0\.29\.[^"]*"|anchor-lang = "0.30.1"|g' "$CARGO_TOML"
      echo "  ✓ Updated anchor-lang to 0.30.1"
    fi
  fi

# Case: anchor-lang = { version = "0.29.x", ... } (with space after {)
  if grep -q 'anchor-lang = { version = "0\.29\.' "$CARGO_TOML"; then
    # Replace version number in-place, preserving any other fields
    sed "${SED_I[@]}" 's|\(anchor-lang = { *version = \)"0\.29\.[^"]*"|\1"0.30.1"|g' "$CARGO_TOML"
    if [ "$WITH_IDL_BUILD" -eq 1 ]; then
      # Add idl-build to features if features array exists
      if grep -q 'anchor-lang = { version = "0\.30\.1", features = \[' "$CARGO_TOML"; then
        sed "${SED_I[@]}" 's|\(features = \[\)\([^]]*\)\(] *[,}]\)|\1\2, "idl-build"\3|g' "$CARGO_TOML"
      else
        sed "${SED_I[@]}" 's|\(anchor-lang = { version = "0\.30\.1"[^}]*\)\(}\)|\1, features = ["idl-build"] \2|g' "$CARGO_TOML"
      fi
    fi
    echo "  ✓ Updated anchor-lang to 0.30.1"
  fi

# Case: anchor-lang = {version = "0.29.x", ...} (no space after {)
  if grep -q 'anchor-lang = {version = "0\.29\.' "$CARGO_TOML"; then
    # Replace version number in-place, preserving any other fields
    sed "${SED_I[@]}" 's|\(anchor-lang = {version = \)"0\.29\.[^"]*"|\1"0.30.1"|g' "$CARGO_TOML"
    if [ "$WITH_IDL_BUILD" -eq 1 ]; then
      # Add idl-build to features if features array exists
      if grep -q 'anchor-lang = {version = "0\.30\.1", features = \[' "$CARGO_TOML"; then
        sed "${SED_I[@]}" 's|\(features = \[\)\([^]]*\)\(] *[,}]\)|\1\2, "idl-build"\3|g' "$CARGO_TOML"
      else
        sed "${SED_I[@]}" 's|\(anchor-lang = {version = "0\.30\.1"[^}]*\)\(}\)|\1, features = ["idl-build"] \2|g' "$CARGO_TOML"
      fi
    fi
    echo "  ✓ Updated anchor-lang to 0.30.1"
  fi

# 2. Update anchor-spl version
  if grep -q 'anchor-spl = "0\.29\.' "$CARGO_TOML"; then
    sed "${SED_I[@]}" 's|anchor-spl = "0\.29\.[^"]*"|anchor-spl = "0.30.1"|g' "$CARGO_TOML"
    echo "  ✓ Updated anchor-spl to 0.30.1"
  fi

# 3. Remove deprecated features only in anchor-lang / anchor-syn dependency lines
  # Handle middle, first, last, and sole positions in feature arrays
  sed "${SED_I[@]}" '/anchor-lang *=/s/, "idl-parse"//g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-lang *=/s/"idl-parse", //g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-lang *=/s/\["idl-parse"\]/[]/g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-lang *=/s/, "seeds"//g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-lang *=/s/"seeds", //g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-lang *=/s/\["seeds"\]/[]/g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-syn *=/s/, "idl-parse"//g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-syn *=/s/"idl-parse", //g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-syn *=/s/\["idl-parse"\]/[]/g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-syn *=/s/, "seeds"//g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-syn *=/s/"seeds", //g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-syn *=/s/\["seeds"\]/[]/g' "$CARGO_TOML"

# 4. Clean up empty feature arrays left after deprecated feature removal
  # Handle trailing space (end of inline table) and trailing comma (more fields follow)
  sed "${SED_I[@]}" '/anchor-lang *=/s/, features = \[\] / /g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-lang *=/s/, features = \[\], /, /g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-syn *=/s/, features = \[\] / /g' "$CARGO_TOML"
  sed "${SED_I[@]}" '/anchor-syn *=/s/, features = \[\], /, /g' "$CARGO_TOML"

# 5. Ensure [profile.release] has overflow-checks = true
  if ! grep -q '\[profile\.release\]' "$CARGO_TOML"; then
    printf '\n[profile.release]\noverflow-checks = true\n' >> "$CARGO_TOML"
    echo "  ✓ Added [profile.release] with overflow-checks = true"
  elif ! grep -q 'overflow-checks' "$CARGO_TOML"; then
    if [[ "$OSTYPE" == darwin* ]]; then
      sed -i '' '/\[profile\.release\]/a\
overflow-checks = true' "$CARGO_TOML"
    else
      sed -i '/\[profile\.release\]/a overflow-checks = true' "$CARGO_TOML"
    fi
    echo "  ✓ Added overflow-checks = true to [profile.release]"
  fi

  echo "Done! Review changes in $CARGO_TOML"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --with-idl-build)
      WITH_IDL_BUILD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: unknown option: $1"
      usage
      exit 1
      ;;
    *)
      if [ -n "$CARGO_TARGET" ]; then
        echo "Error: multiple Cargo.toml paths provided"
        usage
        exit 1
      fi
      CARGO_TARGET="$1"
      shift
      ;;
  esac
done

if [ -n "$CARGO_TARGET" ]; then
  migrate_one "$CARGO_TARGET"
  exit 0
fi

cargo_files=()
if command -v rg >/dev/null 2>&1; then
  while IFS= read -r f; do
    [ -n "$f" ] && cargo_files+=("$f")
  done < <(rg --files -g '**/Cargo.toml')
else
  while IFS= read -r f; do
    [ -n "$f" ] && cargo_files+=("$f")
  done < <(find . \( -path './target' -o -path './.git' \) -prune -o -name Cargo.toml -print)
fi

if [ "${#cargo_files[@]}" -eq 0 ]; then
  echo "Error: no Cargo.toml files found under current directory"
  exit 1
fi

for cargo_file in "${cargo_files[@]}"; do
  migrate_one "$cargo_file"
done
