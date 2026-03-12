#!/bin/sh
# Installs git pre-commit hook for SecureAuth.
# Run once after cloning: ./scripts/setup-hooks.sh

HOOK_DIR="$(git rev-parse --git-dir)/hooks"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cat > "$HOOK_DIR/pre-commit" << 'HOOK'
#!/bin/sh
# SecureAuth pre-commit hook: format check + static analysis

set -e

echo "Running pre-commit checks..."

# 1. Check Dart formatting
echo "  Checking formatting..."
if ! dart format --set-exit-if-changed --output=none lib/ test/ 2>/dev/null; then
  echo ""
  echo "Formatting issues found. Run: dart format lib/ test/"
  echo "Then stage the changes and try again."
  exit 1
fi

# 2. Static analysis
echo "  Running static analysis..."
if ! dart analyze lib/ 2>/dev/null; then
  echo ""
  echo "Analysis issues found. Fix them before committing."
  exit 1
fi

echo "Pre-commit checks passed."
HOOK

chmod +x "$HOOK_DIR/pre-commit"
echo "Pre-commit hook installed successfully."
