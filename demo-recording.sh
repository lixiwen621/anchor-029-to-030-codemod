#!/usr/bin/env bash
# Video recording demo for hackathon / local smoke test.
#
# Usage:
#   bash demo-recording.sh              # interactive pauses (Press Enter)
#   bash demo-recording.sh --quick      # no pauses
#
# Optional: full Codemod workflow dry-run needs a real Anchor project root
# (with Anchor.toml + programs). test-fixtures/ has no Cargo.toml — do not
# use it as workflow target.
#   export DEMO_ANCHOR_ROOT="/Users/you/web3/anchor-examples/quickstart"
#   bash demo-recording.sh
#
# Environment:
#   DEMO_QUICK=1          same as --quick
#   DEMO_ANCHOR_ROOT=... enable Step 6 workflow dry-run

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

WORKFLOW="$SCRIPT_DIR/workflow.yaml"
FIXTURE_DIR="$SCRIPT_DIR/test-fixtures"

if [[ "${1:-}" == "--quick" ]] || [[ "${DEMO_QUICK:-}" == "1" ]]; then
  QUICK=1
else
  QUICK=0
fi

pause() {
  if [[ "$QUICK" -eq 1 ]]; then
    return 0
  fi
  echo ""
  echo ">>> [Press Enter to continue...]"
  read -r
  echo ""
  echo "─────────────────────────────────────────────────────"
  echo ""
}

echo "========================================================"
echo "  Anchor v0.29 → v0.30 Codemod — Demo Recording Script"
echo "========================================================"
echo ""

# Step 1
echo "Step 1: Project overview"
echo ""
echo "Repository: $SCRIPT_DIR"
echo ""
tree -L 2 --noreport 2>/dev/null || find . -maxdepth 2 -not -path './.git/*' -not -path './target/*' | head -40

pause

# Step 2
echo "Step 2: ast-grep rule files"
echo ""
ls -la rules/
echo ""
echo "Rule id count (grep ^id:):"
awk '/^id:/{c++} END{print "  " c+0 " rules"}' rules/*.yml

pause

# Step 3
echo "Step 3: sg scan — Rust fixture"
echo ""

export PATH="$HOME/.cargo/bin:$PATH"
sg scan --config "$SCRIPT_DIR/sgconfig.yml" "$FIXTURE_DIR/old_program.rs"

pause

# Step 4
echo "Step 4: sg scan — TypeScript fixture"
echo ""

sg scan --config "$SCRIPT_DIR/sgconfig.yml" "$FIXTURE_DIR/old_program.ts"

pause

# Step 5
echo "Step 5: npx codemod workflow validate"
echo ""

npx codemod workflow validate -w "$WORKFLOW"

pause

# Step 6
echo "Step 6: npx codemod workflow run (dry-run)"
echo ""

ANCHOR_ROOT="${DEMO_ANCHOR_ROOT:-}"
if [[ -n "$ANCHOR_ROOT" && -f "$ANCHOR_ROOT/Anchor.toml" ]]; then
  echo "Using DEMO_ANCHOR_ROOT=$ANCHOR_ROOT"
  echo ""
  npx codemod workflow run \
    -w "$WORKFLOW" \
    -t "$ANCHOR_ROOT" \
    --param "target=$ANCHOR_ROOT" \
    --dry-run --no-interactive \
    --allow-dirty --allow-fs --allow-child-process
else
  echo "Skipped: no valid Anchor workspace."
  echo "  This step needs a directory that contains Anchor.toml (e.g. quickstart)."
  echo "  Example:"
  echo "    export DEMO_ANCHOR_ROOT=\"/Users/you/web3/anchor-examples/quickstart\""
  echo "    bash demo-recording.sh"
  echo ""
  echo "  (test-fixtures/ is not an Anchor project — migrate-cargo would fail.)"
fi

pause

# Step 7
echo "Step 7: migrate-cargo.sh --help"
echo ""

bash "$SCRIPT_DIR/migrate-cargo.sh" --help

pause

# Step 8
echo "Step 8: coverage summary (see README — buckets overlap with changelog)"
echo ""
echo "  Anchor 0.30.0 breaking bullets: 22/22 mapped in docs"
echo "  Auto-fixed:        6 classes (ast-grep + migrate-cargo.sh)"
echo "  Auto-detected:     8 rules (markers + .accounts resolvers; AI cleans)"
echo "  AI-assisted:       7 classes"
echo "  CLI / separate:    4 reminders + 2 separate (e.g. IDL v0→v1)"
echo "  Real-world notes:  2 business repos in README (post-migration steps doc'd)"
echo ""
echo "========================================================"
echo "  Demo complete"
echo "========================================================"
