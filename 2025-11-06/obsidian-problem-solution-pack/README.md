
# Problem → Solution PKM Template Pack

This pack gives you ready-to-use Obsidian templates, a CSS snippet for visual cues, and Dataview examples — optimized for a "problem → solution → principle/experiment" workflow.

## What's inside

- `templates/Problem.md` — atomic problem-note template
- `templates/Solution.md` — atomic solution-note template (auto-prompts to link the Problem)
- `templates/Principle.md` — timeless heuristics you derive
- `templates/Experiment.md` — hypothesis-driven test harness
- `snippets/problem-solution.css` — visual badges for Problems/Solutions via `cssclass`
- `dataview-examples/queries.md` — useful Dataview queries to navigate your graph

## Quick setup

1. Copy the files into your vault:
   - Place everything in a folder such as `_pkm-templates/` (or anywhere you like).
   - Put the CSS file in `.obsidian/snippets/` (create the folder if needed).
2. In Obsidian:
   - **Settings → Appearance → CSS snippets**: enable `problem-solution.css`.
   - **Settings → Templates**: set your templates folder path (e.g., `_pkm-templates/templates`).
   - (Optional) Install **Templater** and enable it. These templates use Templater tags.
   - Create hotkeys for "Insert template" to speed up note creation.
3. Create notes:
   - Start with **Problem.md**. Then create a **Solution.md** — the template will prompt you to link the problem.
   - Use **Principle.md** for distilled heuristics and **Experiment.md** to validate approaches.

## Conventions

- `type:` field in frontmatter controls styling and querying.
- `cssclass:` enables the visual badges (`pkm-problem`, `pkm-solution`, etc.).
- Use tags like `#problem`, `#solution`, `#principle`, `#experiment` if you prefer tag-based filters (Dataview examples support both).

Have fun building a living decision tree of experience.
