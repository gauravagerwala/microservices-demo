#!/bin/bash

# Script to analyze all open PRs by fetching them with gh CLI,
# executing analyze_pr.sh for each one, and committing the results
# to a new branch for each PR.
# Usage: ./analyze_all_prs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Fetching all open PRs..."

# Get all open PR numbers
PR_NUMBERS=$(gh pr list --state open --json number -q '.[].number')

if [ -z "$PR_NUMBERS" ]; then
    echo "No open PRs found."
    exit 0
fi

# Count total PRs
TOTAL=$(echo "$PR_NUMBERS" | wc -l | tr -d ' ')
echo "Found $TOTAL open PR(s) to analyze."
echo ""

# Process each PR
COUNT=0
for PR_NUM in $PR_NUMBERS; do
    COUNT=$((COUNT + 1))
    BRANCH_NAME="pr-analysis/$PR_NUM"
    
    echo "========================================"
    echo "[$COUNT/$TOTAL] Analyzing PR #$PR_NUM..."
    echo "========================================"
    
    # Create or switch to the analysis branch
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo "Branch '$BRANCH_NAME' already exists. Checking out..."
        git checkout "$BRANCH_NAME"
    else
        echo "Creating new branch '$BRANCH_NAME'..."
        git checkout -b "$BRANCH_NAME"
    fi
    
    # Get PR metadata for commit message
    PR_TITLE=$(gh pr view "$PR_NUM" --json title -q .title 2>/dev/null || echo "PR #$PR_NUM")
    
    # Run analysis (this will update design files)
    echo "Running analysis..."
    "$SCRIPT_DIR/analyze_pr.sh" "$PR_NUM"
    
    # Stage and commit all changes
    git add -A
    git commit -m "Update design for PR #$PR_NUM: $PR_TITLE" || echo "No changes to commit"
    
    echo "Changes committed to branch '$BRANCH_NAME'"
    
    # Return to original branch for next iteration
    git checkout "$ORIGINAL_BRANCH"
    
    echo ""
done

echo "========================================"
echo "Completed analysis of all $TOTAL open PR(s)."
echo "Each PR analysis is on its own branch: pr-analysis/<PR_NUMBER>"
echo "========================================"
