
# 🗓 Daily Triage — <% tp.date.now("YYYY-MM-DD, ddd") %>

## Capture Inbox
- [ ] 

## 🎯 Top 3 Priorities
1. [ ] 
2. [ ] 
3. [ ] 

## 🧩 Notes & Ideas
> Quick notes, fleeting thoughts, links to explore

## 🔄 Review / Wrap-Up
- [ ] Process inbox items into Projects or Areas
- [ ] Reflect on progress and note blockers
- [ ] Prepare tomorrow’s focus

---
### Dataview Query: Pending Tasks Today
```dataview
TASK
FROM "Projects"
WHERE !completed AND due = date(today)
SORT priority DESC, due ASC
```
