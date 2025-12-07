Read '.exp/project-overview.md' and '.exp/workflows.json'

For workflow #x, analyze the codebase thoroughly (the codebase is in the parent directory of .exp) and create a document that describes the high level design of the workflow. Use mermaid to create sequence diagrams showing the flow of information.

Before saving, validate all mermaid diagrams using `mmdc` (mermaid-cli). Extract each mermaid code block to a temp .mmd file and run `mmdc -i temp.mmd -o /tmp/test.svg`. If validation fails, fix the syntax errors (e.g., quote labels with special characters, use valid node IDs) and re-validate until all diagrams pass.

Save the document as `.exp/design-workflow-#x.md`, where #x is replaced by the workflow number followed by a slugified version of the workflow name (e.g., design-workflow-1-configuration-setup.md). Ensure the file contains sections for overview, components, sequence diagram in mermaid code block, and any other relevant high-level design aspects.