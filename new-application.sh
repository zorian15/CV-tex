#!/usr/bin/env bash
#
# Scaffold a tailored CV for a specific job application.
#
# Each application lives in its own folder under applications/, which is
# gitignored, so spin-offs never get tracked alongside the master CVs.
#
# Usage:
#   ./new-application.sh <slug> [base]
#
#   <slug>   short name for the job, e.g. "acme-ml-scientist"
#   [base]   "academic" (default), "industry", or a path to any .tex file to
#            fork, so a well-tuned application can seed the next one
#
# Examples:
#   ./new-application.sh acme-ml-scientist industry
#   ./new-application.sh stanford-postdoc academic
#   ./new-application.sh acme-ml-scientist applications/ai2-cellolmo/cv_industry.tex
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="$REPO_ROOT/applications"

slug="${1:-}"
base="${2:-academic}"

if [[ -z "$slug" ]]; then
  echo "usage: ./new-application.sh <slug> [academic|industry]" >&2
  exit 1
fi

case "$base" in
  academic) src="$REPO_ROOT/cv.tex" ;;
  industry) src="$REPO_ROOT/cv_industry.tex" ;;
  *.tex)
    # Fork an existing tailored CV. Accept either an absolute path or one
    # relative to the repo root, so the caller's cwd does not matter.
    if [[ -f "$base" ]]; then
      src="$(cd "$(dirname "$base")" && pwd)/$(basename "$base")"
    elif [[ -f "$REPO_ROOT/$base" ]]; then
      src="$REPO_ROOT/$base"
    else
      echo "error: base file not found: $base" >&2
      exit 1
    fi
    ;;
  *)
    echo "error: base must be 'academic', 'industry', or a path to a .tex file (got '$base')" >&2
    exit 1
    ;;
esac

dest="$APPS_DIR/$slug"
if [[ -e "$dest" ]]; then
  echo "error: $dest already exists" >&2
  exit 1
fi

mkdir -p "$dest"
cp "$src" "$dest/cv.tex"
# Symlink the class file so styling stays in sync with the master copy.
ln -s "../../resume.cls" "$dest/resume.cls"

# Drop a note recording where this application came from.
# Name the base by the file actually copied, relative to the repo root.
cat > "$dest/NOTES.md" <<EOF
# $slug

- Base: ${src#"$REPO_ROOT/"}
- Created: $(date +%Y-%m-%d)
- Job posting:
- Deadline:

## Tailoring notes
-
EOF

echo "Created $dest"
echo "  edit:  \$EDITOR $dest/cv.tex"
echo "  build: (cd $dest && latexmk -pdf cv.tex)"
