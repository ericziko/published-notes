---
transcription_date_utc: 2025-10-01T20:03:58Z
title: Obsidian plugins for ID-based filenames and flat-folder workflows
summary: |
  We discussed approaches in Obsidian for generating unique IDs as filenames and organizing notes in a single, flat folder. 
  We covered core capabilities like Unique Note Creator and Zettelkasten Prefixer, community plugins and workflows (Templater, QuickAdd, FileName Styler), 
  pros/cons of ID-first naming, and practical scripts for rapid capture. We also touched on caveats such as filename collisions, rigid folder assignment, 
  template limitations, and readability tradeoffs—closing with an offer to assemble a plug‑and‑play setup.
joke: "I gave every note an ID and threw them into one folder—it’s like speed dating for thoughts: no names, just numbers."
document-type: chat-gpt-transcription
ai-model: GPT-5 Thinking (2025-10-01)
tags:
  - -para/fleeting-thought
  - -para/resources/ai-transcript
created: 2025-10-01T13:21
updated: 2025-10-01T14:42
---
# obsidian-id-filenames-flat-folder-transcript

## obsidian-id-filenames-flat-folder

*I gave every note an ID and threw them into one folder—it’s like speed dating for thoughts: no names, just numbers.*

### Transcript

**User:** I am using Obsidian to arrange my notes

What can you tell me about plug-ins that create IDs as file names and put all the notes in the same folder?

**Assistant:** In Obsidian, there are a few community plug-ins designed to handle note organization by giving every file a unique ID and flattening the folder hierarchy. The idea is to avoid “where should I put this note?” paralysis by tossing everything into one big bucket, while still ensuring each file is findable by ID and searchable by links or tags. Here’s the lay of the land:  

### Common Approaches
1. **Zettelkasten-style plug-ins**  
   - Plug-ins like **Obsidian Zettelkasten Prefixer** or **Obsidian Zettelkasten Note** will automatically generate an ID (often a timestamp like `202509301845`) as the filename or as a prefix.  
   - This approach mirrors Niklas Luhmann’s original Zettelkasten system, where every note has a unique identifier, and hierarchy emerges through linking instead of folders.

2. **UUID or Hash-based IDs**  
   - Some plug-ins can generate longer random IDs (UUIDs or hashes).  
   - This ensures absolutely unique filenames, which can be helpful if you’re syncing across systems or integrating with other tools (like Zotero, Roam imports, or databases).

3. **Flat folder organization**  
   - Instead of a nested structure, you dump all notes into a single folder.  
   - This relies on backlinks, tags, and search rather than folder placement for context.  
   - Some people find this liberating; others find it chaotic without good naming conventions.

### Pros
- **Guaranteed uniqueness**: No filename collisions.  
- **Faster capture**: You don’t stop to think “where should this go?”  
- **Portable**: IDs work well if you integrate with other systems (citations, external scripts).  
- **Search + links become the main structure**, which matches how Obsidian is designed.

### Cons
- **Less human-readable filenames**: Seeing `202509301845.md` doesn’t tell you what the note is about without opening it.  
- **Requires discipline with titles, tags, or frontmatter** to make notes findable.  
- **Single folder sprawl**: A large vault can feel messy without good metadata.  
- **Can conflict with certain workflows** (like when exporting notes or collaborating with people who prefer semantic filenames).

### Hybrid Practices
Some people use both:  
- ID in the filename (as prefix or suffix), **plus a short title** (`202509301845 guitar-pedals.md`).  
- Flat folder for “inbox,” but curated folders (Projects, Resources, etc.) for more organized notes.  
- Plug-ins like **Templater** or **Periodic Notes** to automatically stamp IDs + titles.

---

Do you want me to point you toward specific Obsidian plug-ins that can generate IDs and enforce the flat structure, with installation links and usage quirks?

**User:** Yes

**Assistant:** Cool — I poked around. Here are a handful of Obsidian plugins (or “core features + plugins”) that let you generate IDs in filenames, flatten folder structure (or at least avoid deep nesting), and some tips + caveats. Use this list as a toolset—you may combine or tweak them to your taste.

  
---

## 🔧 Core / built-in support

These aren’t community plugins—these are features or “core plugins” that come (or may come) with Obsidian itself. They have advantages (stability, integration) and limitations.

| Feature / Core Plugin | What it does | How to configure | Pros & gotchas |
|---|---|---|---|
| **Unique Note Creator** (core) | Creates a new note whose filename is a timestamp or other unique pattern (e.g. `YYYYMMDDHHmm`) | Go to *Settings → Core plugins → Unique Note Creator*. You can set a “template file location” (so new notes get boilerplate) and a *new file location* (folder) and a *unique prefix format*. ([help.obsidian.md](https://help.obsidian.md/plugins/unique-note?utm_source=chatgpt.com)) | This gives you auto‑ID filenames. However, the “new file location” is fixed in settings, so you can’t change folder per use. ([reddit.com](https://www.reddit.com/r/ObsidianMD/comments/199xug1/any_good_way_to_create_notes_with_unique/?utm_source=chatgpt.com)) Also, some users report that if you include invalid characters in the prefix (like `:`), the plugin becomes nonfunctional. ([forum.obsidian.md](https://forum.obsidian.md/t/when-i-click-on-unique-note-creator-icon-nothing-happens/39202?utm_source=chatgpt.com)) |
| **Zettelkasten Prefixer** (core) | Similar idea: when you hit “Create new Zettelkasten note,” it prefixes file names with a timestamp / ID. | Enable it in *Core Plugins*. Then configure: “New file location,” “Template file location,” and “Zettel ID format.” ([publish.obsidian.md](https://publish.obsidian.md/hub/05%2B-%2BConcepts/Obsidian%2BCore%2BPlugins?utm_source=chatgpt.com)) | Many users use this as the “ID + title” approach. But there are known bugs: sometimes the prefix logic misincrements, or interprets collisions poorly. ([forum.obsidian.md](https://forum.obsidian.md/t/zettelkasten-prefixer-core-plugin-creates-files-with-incorrect-date-incorrect-see-if-the-file-name-already-exists-check/20360?utm_source=chatgpt.com)) Also, by default it may require you to pick a folder, and sometimes users report it doesn’t always allow “root / vault top level” cleanly. ([forum.obsidian.md](https://forum.obsidian.md/t/zettelkasten-prefixer-not-working-for-me/14471?utm_source=chatgpt.com)) |

  
**Usage tip:** If your goal is *all notes in one folder*, set the “new file location” (in Unique Note Creator or ZK Prefixer) to the root of your vault (or a designated “flat” folder). That way, when you invoke “new unique note,” it defaults there.  
If you ever want a subfolder for special cases, you’ll need a workaround (templater script, move commands, or a community plugin).

---

## 🧩 Community / third‑party (“plugin store / external”) options

Because the built‑in ones are solid but a bit rigid, many people lean on community plugins or scripting to flex their workflows. Here are a few.

| Plugin / Tool | What it gives you | Strengths & caveats / how to use |
|---|---|---|
| **FileName Styler** | Doesn’t *create* IDs, but helps with *display* of filenames (e.g. hide the ID portion in the sidebar, reformat it, etc.) | This is great if you *are* using ID-based filenames but want your UI to look nicer. It doesn’t change the actual filenames. ([obsidianstats.com](https://www.obsidianstats.com/plugins/filename-styler?utm_source=chatgpt.com)) |
| **Note Auto Creator** | A plugin (from GitHub) for automating note creation (with some patterns) | You can install it as a community plugin. It can help in workflows where you want “create note with pattern if link doesn’t exist, etc.” ([github.com](https://github.com/SimonTC/obsidian-note-autocreation?utm_source=chatgpt.com)) |
| **Templater (community plugin)** + custom scripts | You can write a little snippet that, when triggered (via hotkey or command), creates a new note with a timestamp-based name *in the folder you’re currently in*, or moves it, or uses a template. | Many people use Templater for this exact gap: combining auto-ID + dynamic folder logic. For example, there’s a user script (shared in forums) that lets you “create new unique note in the current folder” using Templater. ([forum.obsidian.md](https://forum.obsidian.md/t/is-there-a-way-to-create-a-new-unique-note-in-the-current-folder/70469?utm_source=chatgpt.com)) Also, you can combine Templater with the Unique Note Creator or ZK prefixer: e.g. create a note via Unique Note Creator + then automatically move/rename via script. |
| **QuickAdd** (community) | Helps orchestrate multistep workflows: “New unique note + insert link + move file + apply template” | This is often used in tandem with Unique Note Creator or templater. For example, someone suggested using QuickAdd to “create a new unique note and insert a link to it from the current note.” ([forum.obsidian.md](https://forum.obsidian.md/t/create-unique-note-inserting-link-here/59190?utm_source=chatgpt.com)) |

---

## 🛠 Example setup (from the trenches)

Here’s a sample workflow you could try (you can tweak all parts):

1. **Enable Unique Note Creator (or ZK Prefixer).**  
   In settings, set the “new file location” to your vault root (or a folder you reserve for “flat notes”).  
   Pick a timestamp format you like (e.g. `YYYYMMDDHHmm`).  
   Optionally, choose a template file so each new note has frontmatter or boilerplate.

2. **Use Templater + a/scripted helper**  
   Write a small script like:

```js
// Pseudocode Templater snippet
let now = tp.date.now("YYYYMMDDHHmm");
let fname = now;
await app.vault.create(fname + ".md", "");
// You could even prefill template, add frontmatter, etc.
```

   Bind that to a hotkey so you can “new note now” in whatever folder you’re seeing.

3. **Optional: Use QuickAdd to wrap the process**  
   Create a QuickAdd macro that says:  
   - Run “Unique Note Creator”  
   - Then “move file to root folder” (if needed)  
   - Then “insert link to new note in current note”  

   Then you press one hotkey and the whole thing flows.

4. **Use FileName Styler to hide or visually de-emphasize the ID**  
   You may prefer not to see `202509301200` in the sidebar but just the “real” title or alias. FileName Styler lets you do that, without messing up the actual filename.  

5. **Maintain metadata / title inside the note**  
   Because the filename is not human-friendly (just an ID), put your “real title” in the frontmatter or first heading (e.g. `title: “My Notes on Quantum Gravity”`). That way, searches, graph view, and backlinks can show the more legible title.  

---

## ⚠️ Caveats, pitfalls & tradeoffs

- **Filename collisions & increment logic bugs**  
  Some users report that ZK Prefixer (or Unique Note logic) misbehaves when a note with a certain prefix exists — it may increment the date or shift the name unexpectedly. ([forum.obsidian.md](https://forum.obsidian.md/t/zettelkasten-prefixer-plugin-wrong-date-and-incrementing-date/25364?utm_source=chatgpt.com))  
- **Rigid folder assignment**  
  Many built-in options force the note into one folder (set in settings). You lose flexibility per note unless you script or move manually.  
- **Template selection is limited**  
  Unique Note Creator only lets you pick *one* template path. You can’t (out of the box) choose from multiple templates at note creation. ([forum.obsidian.md](https://forum.obsidian.md/t/select-from-list-of-templates-unique-note-creator/65978?utm_source=chatgpt.com))  
- **Linking to a not-yet-existing note with ID**  
  If you want to type a link in a note like `[[<some ID>]]` (where the note doesn’t exist yet) and have it auto-create, it’s trickier with ID-based filenames. Some plugin combinations (QuickAdd, templater) can help, but it’s more awkward than with human names. ([forum.obsidian.md](https://forum.obsidian.md/t/how-to-create-links-to-new-notes-with-zettelkasten-prefixer-addon/19952?utm_source=chatgpt.com))  
- **Readability tradeoff**  
  Pure numeric IDs look sterile. If you ever have to browse your file directory outside Obsidian (or via filesystem), the IDs won't tell you much—so you rely on metadata, search, aliases, etc.  
- **Path/Slash behavior in prefix format**  
  If your prefix format accidentally includes a slash (`/`), Obsidian will treat it as a folder path and create subfolders. (E.g. `YYYY/MMDD` might make a folder `YYYY`. ) Some users have tripped over this. ([forum.obsidian.md](https://forum.obsidian.md/t/behaviour-of-unique-note-creator-prefix-format-containing-a/72873?utm_source=chatgpt.com))  

---

If you like, I can build a custom plug‑and‑play configuration (with templates and scripts) tailored to your preferred ID style (timestamp, UUID, etc.) and folder layout, and send you a config file you can drop into Obsidian. Want me to do that for you?
