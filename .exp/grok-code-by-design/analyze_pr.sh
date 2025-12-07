#!/bin/bash

# Script to run the PR workflow impact analysis prompt from .exp/grok-code-by-design/pr_prompt1_v1.md using Grok CLI.
# It takes a GitHub PR number as input, uses gh and git CLI to fetch PR details (title, body, changed files, commits),
# injects them into the <PR_CONTEXT> placeholder, and runs a single-turn yolo analysis.
# Requirements: gh CLI installed and authenticated to the repo, git configured with 'origin' remote.
# Usage: ./run_pr_prompt1_v1.sh <PR_NUMBER>
# Output: Grok's analysis response in plain text to stdout.
# Temp files in /tmp are created and cleaned up.

set -euo pipefail

PR_NUMBER="${1?Error: PR number required. Usage: ${0} <PR_NUMBER>}"
echo "Starting analysis for PR #$PR_NUMBER..."

# Fetch the PR branch reference
git fetch origin "refs/pull/$PR_NUMBER/head:refs/remotes/origin/pr/$PR_NUMBER" || { echo "Failed to fetch PR branch for #$PR_NUMBER"; exit 1; }

# Get base reference
BASE_REF=$(gh pr view "$PR_NUMBER" --json baseRefName -q .baseRefName 2>/dev/null || { echo "Failed to get base ref, defaulting to 'main'"; echo "main"; })

# Ensure base ref is fetched
git fetch origin "$BASE_REF":refs/remotes/origin/"$BASE_REF" 2>/dev/null || true

# Retrieve PR details
TITLE=$(gh pr view "$PR_NUMBER" --json title -q .title 2>/dev/null || echo "Untitled PR")
BODY=$(gh pr view "$PR_NUMBER" --json body -q .body 2>/dev/null || "")
URL=$(gh pr view "$PR_NUMBER" --json url -q .url 2>/dev/null || echo "No URL available")

# Changed files list (multiline)
CHANGED_LIST=$(git diff --name-only "origin/$BASE_REF...origin/pr/$PR_NUMBER" 2>/dev/null | sort -u || echo "Unable to determine changed files")

# Commits summary (up to 20 lines)
COMMITS=$(git log --oneline "origin/$BASE_REF..origin/pr/$PR_NUMBER" --no-merges 2>/dev/null | head -20 || echo "Unable to fetch commits")

# Create temporary PR context file
TEMP_CONTEXT="/tmp/pr_context_$PR_NUMBER.md"
cat > "$TEMP_CONTEXT" << EOF
# PR Context for #$PR_NUMBER

## Metadata
- **Title:** $TITLE
- **URL:** $URL

## Description
\`\`\`
$BODY
\`\`\`

## Changed Files
\`\`\`
$CHANGED_LIST
\`\`\`

## Recent Commits (up to 20)
\`\`\`
$COMMITS
\`\`\`
EOF

# Create updated prompt: insert context after <PR_CONTEXT> line and delete the placeholder
TEMP_PROMPT="/tmp/updated_prompt_$PR_NUMBER.md"
sed "/<PR_CONTEXT>/r $TEMP_CONTEXT" .exp/grok-code-by-design/pr_prompt1_v1.md | sed '/<PR_CONTEXT>/d' > "$TEMP_PROMPT"

# Load updated prompt
prompt_content=$(cat "$TEMP_PROMPT")

# Execute Grok analysis
grok --prompt "$prompt_content" --yolo --single-turn --output-format plain

# Cleanup
rm -f "$TEMP_CONTEXT" "$TEMP_PROMPT"

echo "Analysis for PR #$PR_NUMBER completed. Check the Grok output above for details."