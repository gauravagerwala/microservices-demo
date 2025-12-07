Analyze the codebase to identify distinct workflows. Create a JSON file '.exp/workflows.json' containing a JSON object with a key "workflows" that holds the list of workflows.
Each workflow object should have:
- `name`: A concise name for the workflow.
- `description`: A brief description of what it does.
- `input`: The inputs required (e.g., CLI arguments, environment variables).
- `output`: The expected outputs (e.g., files, stdout).
- `entry_point`: The specific file or function that initiates this workflow.
- `relevant_files`: A list of key files involved in this workflow.
- `doc`: A link to the document that describes the workflow (.exp/design-workflow-#x.md where x is the workflow number)