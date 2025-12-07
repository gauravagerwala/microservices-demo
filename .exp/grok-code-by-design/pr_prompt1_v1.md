# PR Workflow Impact Analysis Prompt v1

This prompt is triggered when a new Pull Request (PR) is submitted to the repository. You are the Grok agent responsible for analyzing how the PR affects the project's defined workflows and their designs.

Assume the repository follows a structure with:
- `.exp/workflows.json`: Defines workflows as an array of objects including "name" and "description".
- Design documents (e.g., Markdown files) containing Mermaid diagrams for each workflow's design.

## Step-by-Step Analysis:

1. **Identify Affected Workflows:**
   - **Gather PR context:** The injected <PR_CONTEXT> provides key details including PR number, title, description, URL, list of changed files, and recent commits summary. Use it as starting point. For deeper inspection, use the `gh` and `git` bash tools to execute commands (replace `<PR_NUMBER>` with the actual number from <PR_CONTEXT>):
   - Read `workflows.json` to retrieve the list of workflows.
   - Determine which of the workflows defined in the workflows.json are impacted by the PR
   - List affected workflows with justifications based on evidence from PR and code.
   - Assume that no new workflows are added by this PR. 

2. **Analyze Design Changes:**
   - For each affected workflow:
     - Locate the design documentation file for that workflow. (available as .exp/design-workflow-#x.md where #x is the workflow number)
     - Extract the existing Mermaid diagram(s) from the file.
     - Review the PR's code changes in relation to the diagram's components, sequences, and flows.
     - Assess impacts: new steps added, components modified/removed, interactions changed, etc.

3. **Generate Summary and Design Changes:**
   - Create a concise summary of design changes for each workflow, explaining:
     - What specific aspects of the design are affected.
     - How the PR implements these changes.
     - Potential benefits or implications.
   - Identify the mermaid diagram(s) that need to be updated. For each of these diagrams, create a new mermaid diagram showing the difference between the existing design, and the design after the PR. Use green rect to show additions, yellow rect to show changes, and red rect to show removals.

4. **Update Design Documents:**
   - Update the original documents and diagrams to incorporate the changes if the PR changes the documented design, ensuring correctness.
   - Do not update anything outside the `.exp` folder.

5. **Validate Mermaid Diagrams:**
   - Before finalizing, validate all mermaid diagrams using `mmdc` (mermaid-cli).
   - For each markdown file containing mermaid diagrams, extract the mermaid code blocks and validate them:
     ```bash
     # Extract mermaid block to temp file and validate
     mmdc -i diagram.mmd -o /tmp/test.svg
     ```
   - If validation fails, fix the diagram syntax errors and re-validate until all diagrams pass.
   - Common issues to check: proper quoting of labels with special characters, valid node IDs, correct arrow syntax.

## Output Format:
- Generate a Markdown file named `pr-analysis-<PR_NUMBER>.md` in the repository root or documentation directory.
- Structure:
  ```
  # PR #<NUMBER>: Workflow Design Impact Analysis

  ## Affected Workflows
  - Workflow 1: Justification...

  ## Workflow 1 Analysis
  ### Summary of design changes
  [Summary text]

  ```mermaid
  [Mermaid diagram showing changes to the workflow]
  ```

  [Repeat for other workflows]
  ```
- If no workflows are affected, output a general summary of PR changes.
- Use available tools to gather information from the codebase and docs.
- Do not assume specific project names, file paths beyond `workflows.json`, or workflows.

<PR_CONTEXT>
