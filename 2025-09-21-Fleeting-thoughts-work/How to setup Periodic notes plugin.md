---
created: 2025-09-21T17:03
updated: 2025-09-21T18:16
title: How to setup Periodic notes plugin
date created: Monday, September 22nd 2025, 12:03:47 am
date modified: Monday, September 22nd 2025, 1:16:16 am
tags:
  - Obsidian/Plugins/periodic-notes
---

# How to setup Periodic notes plugin
## Reference
- [[Periodic Notes plugin]]


## Daily Notes
### Daily notes format
```
YYYY/MM/YYYY-MM-DD/YYYY-MM-DD
```

### Daily Notes Template

**See:** [[Daily-Note-Template]]

```
Templates/Daily-Note-Template.md
```

#### Daily-Note-Template.md

**Notes:** Makes daily note a **Folder Note**

```markdown
# {{date:YYYY-MM-DD}}
***
## Events
***

## Files
***
%% Begin Waypoint %%


%% End Waypoint %%
***
## Notes
***

```

## Weekly notes
### Weekly notes format

**Notes:** Makes weekly note a **Folder Note**

```
gggg-[W]ww/gggg-[W]ww
```

### Weekly notes template
**See:** [[Weekly-Notes-Template]]

```
Templates/Weekly-Notes-Template.md
```

#### `Weekly-Notes-Template.md`

**Notes:** Makes weekly note a **Folder Note**

```markdown
## Weekly Notes todo 
  
- [ ] (Friday) Weekly review  
- [ ] Write a summary of this past week in this document  
- [ ] Add meeting notes to the _Meeting notes_ section of this document  
- [ ] Choose tasks for next week  
  
## Summary of this week
*Summary of stuff I got done this week*
### Specific tasks
- [ ] *I did....*

##  Tasks for next weekly
- [ ] Todo - add tasks here

## Meeting notes

```


## Monthly notes

### Monthly notes format
**Notes:** Makes monthly note a **Folder Note**
```
YYYY-MM/YYYY-MM
```

### Monthly notes folder
`/src/MonthlyNotes`

### `Templates/Monthly-Notes-Template.md`
**See:** [[Monthly-Notes-Template]]

```
# Monthly-Notes-Template

## Monthly Notes todo 
  
- [ ] Monthly Notes review
- [ ] Write a summary of this past week in this document  
- [ ] Add meeting notes to the _Meeting notes_ section of this document  
- [ ] Choose tasks for next week  
  
## Landmark
%% Begin Landmark %%


%% End Landmark %%

## Summary of this week
*Summary of stuff I got done this week*
### Specific tasks
- [ ] *I did....*

##  Tasks for next month 
- [ ] Todo - add tasks here

## Meeting notes

```

## `.obsidian/plugins/periodic-notes/data.json`

```json
  "daily": {
    "format": "YYYY/MM/YYYY-MM-DD/YYYY-MM-DD",
    "template": "Templates/Daily-Note-Template.md",
    "folder": "src/DailyNotes",
    "enabled": true
  },
  "weekly": {
    "format": "gggg-[W]ww/gggg-[W]ww",
    "template": "Templates/Weekly-Notes-Template.md",
    "folder": "src/WeeklyNotes",
    "enabled": true
  },
  "monthly": {
    "format": "YYYY-MM/YYYY-MM",
    "template": "Templates/Monthly-Notes-Template.md",
    "folder": "src/MonthlyNotes",
    "enabled": true
  },
```
