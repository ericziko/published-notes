---
title: "Solution: <% tp.file.title %>"
type: solution
cssclass: pkm-solution
status: draft
created: <% tp.date.now("YYYY-MM-DD") %>
updated: <% tp.date.now("YYYY-MM-DD") %>
solves: <%* 
// Prompt for a problem to link. Accepts [[wikilink]] or plain text (auto-wikilinked).
const input = await tp.system.prompt("Link to the Problem (paste [[wikilink]] or type exact note title)");
tR += (input && input.includes("[[")) ? input : `[[${input||"Problem: (fill me)"}]]`; %>
core_idea: ""
tradeoffs: []
verification: ""
sources: []
related: []
tags: [solution]
---

# <% tp.file.title %>

> Solves: <%* tR = "" %><%* 
// Render the solves link again inside the body for clarity.
const input2 = tp.frontmatter.solves; 
tR += input2; %>

## Core Idea / Mechanism
- The conceptual heart of the fix.

## Implementation
- Steps, examples, or code.
```csharp
// Example placeholder
```
- Operational checklist:
  - [ ] Pre-conditions
  - [ ] Steps executed
  - [ ] Post-conditions

## Trade-offs / When *not* to use
- Costs, failure modes, scalability limits.

## Verification
- Tests run, metrics gathered, acceptance criteria.

## Sources / Inspirations
- Links to docs, articles, your experiments.

## Evolution / Follow-ons
- New problems created by this solution:
  -

## Status
- draft / verified / archived
