---
transcription_date_utc: 2025-10-01T20:01:44.090624
title: git-precommit-markdown-frontmatter
summary: |
  "The user requested a Git pre-commit hook written in PowerShell that verifies whether Markdown files being committed include required YAML frontmatter properties such as 'title', 'description', and 'created'. The hook scans all staged .md files, parses their frontmatter, and blocks the commit if any required keys are missing. The assistant also explains how to install and customize the hook."
joke: "*Why did the Markdown file get rejected from the Git commit party? Because it forgot its ID at the YAML gate!*"
document-type: chat-gpt-transcription
ai-model: gpt-4o-2024-06-13
tags:
  - -para/fleeting-thought
  - -para/resources/ai-transcript
created: 2025-10-01T13:21
updated: 2025-10-01T13:22
date created: Wednesday, October 1st 2025, 8:21:14 pm
date modified: Wednesday, October 1st 2025, 8:22:36 pm
---

# git-precommit-markdown-frontmatter

## git-precommit-markdown-frontmatter

*Why did the Markdown file get rejected from the Git commit party? Because it forgot its ID at the YAML gate!*

### **User:**  
Can you write me a pre-Commit hook in power shell for GIT that checks to make sure the markdown that's getting committed has certain frontmatter properties present in its markdown

### **Assistant:**  
Sure! Here's a **PowerShell-based Git `pre-commit` hook** that ensures **Markdown files being committed** include specific **YAML frontmatter properties** (e.g. `title`, `description`, `created`, etc.).

#### ✅ Requirements Covered

- Only checks `.md` files being committed
- Validates the presence of required frontmatter keys
- Blocks the commit with a clear error if any are missing

#### 📜 Sample `pre-commit` PowerShell Hook

Save this as `.git/hooks/pre-commit` (no file extension!) and make it executable:

```powershell
#!/usr/bin/env pwsh

# Required frontmatter keys
$requiredKeys = @("title", "description", "created")

# Get staged Markdown files
$mdFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '\.md$' }

if (-not $mdFiles) {
    exit 0  # Nothing to check
}

$hasError = $false

foreach ($file in $mdFiles) {
    if (-not (Test-Path $file)) {
        continue  # File might be deleted or renamed
    }

    $lines = Get-Content $file
    if ($lines[0] -ne "---") {
        Write-Host "❌ $file is missing frontmatter opening '---'" -ForegroundColor Red
        $hasError = $true
        continue
    }

    $frontmatterLines = $lines | Select-Object -Skip 1
    $endIndex = $frontmatterLines.IndexOf("---")

    if ($endIndex -eq -1) {
        Write-Host "❌ $file is missing frontmatter closing '---'" -ForegroundColor Red
        $hasError = $true
        continue
    }

    $frontmatterContent = $frontmatterLines[0..($endIndex - 1)]

    foreach ($key in $requiredKeys) {
        if (-not ($frontmatterContent -match "^\s*$key\s*:\s*.+")) {
            Write-Host "❌ $file is missing required frontmatter key: '$key'" -ForegroundColor Red
            $hasError = $true
        }
    }
}

if ($hasError) {
    Write-Host "`n🚫 Commit aborted due to missing frontmatter keys." -ForegroundColor Red
    exit 1
}

exit 0
```

#### 🔐 Installation Instructions

1. Save the script as `.git/hooks/pre-commit` (no `.ps1` extension)
2. Make sure it is executable:
   ```bash
   chmod +x .git/hooks/pre-commit
   ```
3. Ensure your environment uses PowerShell Core (`pwsh`) or modify the shebang to match your system

#### 🧪 Example Markdown to Pass Check

```markdown
---
title: my-awesome-post
description: A guide on setting up a pre-commit hook
created: 2025-09-30
---

# My Awesome Post

Content goes here.
```

#### 🧩 Want to Customize?

Let me know if you want to:
- Auto-fix missing keys
- Check specific file patterns
- Use `.markdownlint.json`
- Extract frontmatter with a YAML parser
- Output results as JSON

Just say the word — happy to extend it.
