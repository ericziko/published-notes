# Dataview Queries

> These work with either `type:` in frontmatter or `#problem/#solution` tags.

## Open Problems
```dataview
TABLE status, context, desired_outcome, file.mtime as "Updated"
FROM ""
WHERE (type = "problem" OR contains(file.tags, "problem"))
AND (status = "open" OR status = "exploring")
SORT file.mtime DESC
```

## Solutions by Problem
```dataview
TABLE
  file.link as Solution,
  solves as Problem,
  status,
  verification
FROM ""
WHERE (type = "solution" OR contains(file.tags, "solution"))
FLATTEN solves
GROUP BY solves
```

## Orphan Problems (no linked solutions yet)
```dataview
LIST FROM ""
WHERE (type = "problem" OR contains(file.tags, "problem"))
AND !any(contains(file.inlinks.type, "solution"))
```

## Principles
```dataview
TABLE applies_to, contrasts_with, file.mtime as "Updated"
FROM ""
WHERE (type = "principle" OR contains(file.tags, "principle"))
SORT file.mtime DESC
```
