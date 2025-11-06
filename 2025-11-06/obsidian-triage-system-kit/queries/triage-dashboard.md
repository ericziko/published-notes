
# 🧭 Triage Dashboard

```dataview
table file.link as "Project", due, priority, status
from "Projects"
where !completed
sort due asc, priority desc
```

```tasks
not done
sort by priority
group by path
```
