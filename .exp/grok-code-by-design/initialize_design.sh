#!/bin/bash

# Script to first run .exp/grok-code-by-design/prompt1_v1.md and .exp/grok-code-by-design/prompt1b_v1.md in the same Grok session (using --continue)
# to generate/update project-overview.md and workflows.json from codebase analysis.
# Then, for each workflow in the updated workflows.json, adapt and run .exp/grok-code-by-design/prompt2_v2.md with Grok CLI,
# creating separate design-workflow-*.md documents for high-level designs.
# The preparatory prompts share one session for context sharing; each per-workflow run starts a new session.
# Uses --yolo mode for auto-approval of tool calls throughout.

set -euo pipefail

# Check dependencies
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Install with 'brew install jq' on macOS."
    exit 1
fi

if ! command -v grok &> /dev/null; then
    echo "Error: grok CLI is required. Install via npm or other method."
    exit 1
fi

# Check preparatory prompt files exist
if [[ ! -f .exp/grok-code-by-design/prompt1_v1.md ]]; then
    echo "Error: .exp/grok-code-by-design/prompt1_v1.md is required but not found."
    exit 1
fi
if [[ ! -f .exp/grok-code-by-design/prompt1b_v1.md ]]; then
    echo "Error: .exp/grok-code-by-design/prompt1b_v1.md is required but not found."
    exit 1
fi

echo "Running preparatory analysis prompts in the same Grok session..."

# Load prompt contents (preserving newlines)
prompt1_content=$(cat .exp/grok-code-by-design/prompt1_v1.md)
prompt1b_content=$(cat .exp/grok-code-by-design/prompt1b_v1.md)

# Run prompt1: Analyze the codebase
echo "Executing prompt1: Detailed codebase analysis and project overview..."
if grok --prompt "$prompt1_content" --yolo --single-turn --output-format plain; then
    echo "Prompt1 completed successfully."
    if [[ -f .exp/project-overview.md ]]; then
        echo ".exp/project-overview.md has been created/updated."
    else
        echo "Warning: .exp/project-overview.md was not found after prompt1 execution."
    fi
else
    echo "Error: prompt1 execution failed."
    exit 1
fi

# Continue the same session for prompt1b: Define workflows based on analysis
echo "Executing prompt1b (continuing the session): Understanding inputs/outputs and creating workflows.json..."
if grok --continue --prompt "$prompt1b_content" --yolo --single-turn --output-format plain; then
    echo "Prompt1b completed successfully."
    if [[ -f .exp/workflows.json ]]; then
        echo ".exp/workflows.json has been created/updated."
        # Validate JSON structure
        if echo "$(cat .exp/workflows.json)" | jq . > /dev/null 2>&1; then
            echo ".exp/workflows.json is valid JSON."
        else
            echo "Warning: .exp/workflows.json contains invalid JSON."
        fi
    else
        echo "Error: .exp/workflows.json was not found after prompt1b execution. Cannot proceed."
        exit 1
    fi
else
    echo "Error: prompt1b execution failed."
    exit 1
fi

# Read workflows.json
workflows_json=$(cat .exp/workflows.json | jq -c 'if type=="array" then . else .workflows end')

# Get number of workflows
num_workflows=$(echo "$workflows_json" | jq 'length')

echo "Found $num_workflows workflows to process."

for ((i = 1; i <= num_workflows; i++)); do
    idx=$((i - 1))
    wf=$(echo "$workflows_json" | jq -c ".[$idx]")
    name=$(echo "$wf" | jq -r '.name')
    
    # Slugify name for filename suggestion
    slug=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:][:punct:]' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    
    echo "Processing workflow #$i: '$name' (slug: $slug)"
    
    # Create modified prompt by replacing #x with specific reference
    # Note: sed processes multi-line, but we read whole file
    modified_prompt=$(sed "s/#x/#$i \\\"$name\\\" ($slug)/g" .exp/grok-code-by-design/prompt2_v2.md)
    
    # Run grok with the modified prompt as --single arg (preserves newlines)
    # Output to stdout, main output is the created design file

    design_file=".exp/design-workflow-${i}-${slug}.md"  # Expected output file from agent
    
    echo "Running Grok for workflow #$i..."
    if grok --prompt "$modified_prompt" --yolo --single-turn --output-format plain; then
        echo "Completed workflow #$i. Check $design_file (output above)"
        if [[ -f "$design_file" ]]; then
            echo "Design file created: $design_file"
        else
            echo "Warning: Design file not found, check output above"
        fi
    else
        echo "Error running Grok for workflow #$i, check output above"
    fi
done

echo "All workflows processed. Design files should be in current directory."
