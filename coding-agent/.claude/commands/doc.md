---
description: Generate documentation for a file, module, or directory
argument-hint: [path]
allowed-tools: Read, Write, Grep, Glob, Bash
---

Generate comprehensive documentation for @$1

Follow this process:

1. **Explore** the target path to understand its structure
2. **Identify** key components, functions, classes, and their relationships
3. **Create** mermaid diagrams for:
   - Architecture/component relationships (flowchart)
   - Data flows (sequence diagrams)
   - Database schemas (ERD) if applicable

4. **Document** with this structure:
   - Overview: Purpose and responsibility
   - Architecture: Visual diagram + explanation
   - Components: Detailed breakdown
   - API/Usage: How to use with examples
   - Configuration: Environment variables, options
   - Dependencies: What it requires

Output as well-formatted Markdown with inline mermaid diagrams.

If $ARGUMENTS is empty, document the current project's overall architecture.
