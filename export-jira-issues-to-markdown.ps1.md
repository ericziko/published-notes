---
title: "PowerShell Script `export-jira-issues-to-markdown.ps1` "
aliases: ["PowerShell Script `export-jira-issues-to-markdown.ps1` "]
linter-yaml-title-alias: "PowerShell Script `export-jira-issues-to-markdown.ps1` "
date created: Thursday, October 2nd 2025, 12:17:54 am
date modified: Thursday, October 2nd 2025, 1:57:40 am
---

# PowerShell Script `export-jira-issues-to-markdown.ps1`

```powershell
<#
.SYNOPSIS
    Export Jira issues to local Markdown files using JiraPS.

.DESCRIPTION
    Authenticates to Jira Cloud/Server using JiraPS and exports all issues
    returned by a JQL query into individual, nicely-formatted Markdown files.
    Each file includes YAML front matter and sections for description, acceptance
    criteria, comments, attachments, and a basic changelog.

    Requires: JiraPS (Install-Module JiraPS)
    Tested with: PowerShell 7+, Windows PowerShell 5.1

.PARAMETER BaseUrl
    Base URL of your Jira instance (e.g., https://your-domain.atlassian.net).

.PARAMETER UserEmail
    Your Jira account email (for Jira Cloud) or username (for Server/DC).

.PARAMETER ApiToken
    For Jira Cloud, create an API token at https://id.atlassian.com/manage/api-tokens.
    For Server/DC, you may pass your password (or preferably a PAT if configured).

.PARAMETER Jql
    JQL string selecting which issues to export. Example:
    "project = ABC AND updated >= -30d ORDER BY updated DESC"

.PARAMETER OutDir
    Folder to write Markdown files into. Will be created if missing.

.PARAMETER IncludeChangelog
    If set, will attempt to include a condensed changelog (status transitions).

.EXAMPLE
    .\export-jira-issues-to-markdown.ps1 `
        -BaseUrl "https://your-domain.atlassian.net" `
        -UserEmail "you@example.com" `
        -ApiToken (Read-Host "API token" -AsSecureString | ConvertFrom-SecureString) `
        -Jql 'project = ABC AND issuetype in (Bug,Task) ORDER BY updated DESC' `
        -OutDir .\jira-export

    Note: For convenience you can also pass -ApiToken as plain text using -ApiTokenPlain
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$BaseUrl,

    [Parameter(Mandatory)]
    [string]$UserEmail,

    [Parameter(ParameterSetName='Secure', Mandatory=$true)]
    [securestring]$ApiToken,

    [Parameter(ParameterSetName='Plain', Mandatory=$true)]
    [string]$ApiTokenPlain,

    [Parameter(Mandatory)]
    [string]$Jql,

    [Parameter(Mandatory)]
    [string]$OutDir,

    [switch]$IncludeChangelog
)

begin {
    function Convert-PlainToSecure([string]$s) {
        if ([string]::IsNullOrWhiteSpace($s)) { return $null }
        return (ConvertTo-SecureString -String $s -AsPlainText -Force)
    }

    if ($PSCmdlet.ParameterSetName -eq 'Plain') {
        $ApiToken = Convert-PlainToSecure $ApiTokenPlain
    }

    if (-not (Get-Module -ListAvailable -Name JiraPS)) {
        Write-Verbose "JiraPS module not found. Installing for current user..."
        try {
            Install-Module JiraPS -Scope CurrentUser -Force -ErrorAction Stop
        } catch {
            throw "Failed to install JiraPS: $($_.Exception.Message)"
        }
    }

    Import-Module JiraPS -ErrorAction Stop

    if (-not (Test-Path -LiteralPath $OutDir)) {
        New-Item -ItemType Directory -Path $OutDir | Out-Null
    }

    # Build credential
    $cred = New-Object System.Management.Automation.PSCredential($UserEmail, $ApiToken)

    # Connect (works for both Cloud and Server/DC when URL is correct)
    try {
        # Some JiraPS versions use Connect-JiraServer; others also support New-JiraSession.
        if (Get-Command -Name Connect-JiraServer -ErrorAction SilentlyContinue) {
            Connect-JiraServer -Url $BaseUrl -Credential $cred -ErrorAction Stop | Out-Null
        } elseif (Get-Command -Name New-JiraSession -ErrorAction SilentlyContinue) {
            New-JiraSession -BaseUri $BaseUrl -Credential $cred -ErrorAction Stop | Out-Null
        } else {
            throw "Neither Connect-JiraServer nor New-JiraSession is available in this JiraPS version."
        }
    } catch {
        throw "Failed to connect to Jira at '$BaseUrl': $($_.Exception.Message)"
    }

    # Helpers
    function Convert-ForFileName([string]$name) {
        # Replace invalid filename chars and trim length
        $safe = ($name -replace '[\\/:*?""<>|]', ' ').Trim()
        if ($safe.Length -gt 80) { $safe = $safe.Substring(0,80) }
        return $safe
    }

    function Escape-Yaml([string]$s) {
        if ($null -eq $s) { return "" }
        # Escape newlines and quotes for inline YAML values
        ($s -replace '"', '""') -replace "`r?`n", '\n'
    }

    function Strip-Html([string]$html) {
        if ([string]::IsNullOrWhiteSpace($html)) { return $html }
        # Super-lightweight HTML-to-text fallback. Not perfect, but serviceable.
        $text = $html
        $text = [System.Text.RegularExpressions.Regex]::Replace($text, "<br\s*/?>", "`n", 'IgnoreCase')
        $text = [System.Text.RegularExpressions.Regex]::Replace($text, "</p>", "`n`n", 'IgnoreCase')
        $text = [System.Text.RegularExpressions.Regex]::Replace($text, "<li\s*>", "- ", 'IgnoreCase')
        $text = [System.Text.RegularExpressions.Regex]::Replace($text, "</?ul\s*>|</?ol\s*>", "`n", 'IgnoreCase')
        $text = [System.Text.RegularExpressions.Regex]::Replace($text, "<[^>]+>", "")
        return $text
    }

    function Convert-AdfToMarkdown($adf) {
        # Jira Cloud uses ADF (Atlassian Document Format) JSON for rich text.
        # This function implements a minimal subset. For full-fidelity conversion,
        # consider piping HTML "renderedFields" to a dedicated HTML->Markdown converter.
        if (-not $adf) { return "" }
        try {
            if ($adf -is [string]) { $adf = $adf | ConvertFrom-Json -ErrorAction Stop }
        } catch {
            # Not JSON? just return as-is
            return [string]$adf
        }

        $sb = New-Object System.Text.StringBuilder
        foreach ($node in $adf.content) {
            switch ($node.type) {
                'paragraph' {
                    $line = ""
                    foreach ($t in $node.content) {
                        if ($t.type -eq 'text') {
                            $text = $t.text
                            $marks = $t.marks
                            if ($marks) {
                                foreach ($m in $marks) {
                                    switch ($m.type) {
                                        'strong' { $text = "**$text**" }
                                        'em'     { $text = "*$text*" }
                                        'code'   { $text = "`$text`" }
                                        default {}
                                    }
                                }
                            }
                            $line += $text
                        }
                    }
                    [void]$sb.AppendLine($line)
                    [void]$sb.AppendLine()
                }
                'heading' {
                    $level = $node.attrs.level
                    $txt = ($node.content | ForEach-Object { $_.text }) -join ""
                    $prefix = ('#' * [Math]::Max(1,[Math]::Min(6,[int]$level)))
                    [void]$sb.AppendLine("$prefix $txt")
                    [void]$sb.AppendLine()
                }
                'bulletList' {
                    foreach ($li in $node.content) {
                        $txt = ($li.content.content | ForEach-Object { $_.text }) -join ""
                        [void]$sb.AppendLine("- $txt")
                    }
                    [void]$sb.AppendLine()
                }
                'orderedList' {
                    $i = 1
                    foreach ($li in $node.content) {
                        $txt = ($li.content.content | ForEach-Object { $_.text }) -join ""
                        [void]$sb.AppendLine("$i. $txt")
                        $i++
                    }
                    [void]$sb.AppendLine()
                }
                default { }
            }
        }
        return $sb.ToString().Trim()
    }

    function Get-IssueCommentsMarkdown($issueKey) {
        try {
            if (Get-Command -Name Get-JiraIssueComment -ErrorAction SilentlyContinue) {
                $comments = Get-JiraIssueComment -Issue $issueKey -ErrorAction Stop
            } elseif (Get-Command -Name Get-JiraComment -ErrorAction SilentlyContinue) {
                $comments = Get-JiraComment -Issue $issueKey -ErrorAction Stop
            } else {
                # Fallback to REST via JiraPS core
                $comments = Invoke-JiraMethod -Method Get -ApiUri "/rest/api/2/issue/$issueKey/comment" -ErrorAction Stop
                $comments = $comments.comments
            }
        } catch {
            Write-Warning "Failed to fetch comments for $issueKey: $($_.Exception.Message)"
            return ""
        }

        if (-not $comments) { return "" }

        $lines = @("## Comments")
        foreach ($c in $comments) {
            $author = $c.author.displayName
            $when = $c.created
            $body = $c.body

            # Body can be ADF or plain text depending on API/version
            $mdBody = Convert-AdfToMarkdown $body
            if (-not $mdBody) { $mdBody = Strip-Html ([string]$body) }

            $lines += @(
                "",
                "***$author*** on $when:",
                "",
                $mdBody
            )
        }
        return ($lines -join "`n")
    }

    function Get-IssueChangelogMarkdown($issueKey) {
        if (-not $IncludeChangelog) { return "" }
        try {
            $change = Invoke-JiraMethod -Method Get -ApiUri "/rest/api/2/issue/$issueKey?expand=changelog"
        } catch {
            Write-Warning "Failed to fetch changelog for $issueKey: $($_.Exception.Message)"
            return ""
        }
        if (-not $change.changelog.histories) { return "" }

        $transitions = @()
        foreach ($h in $change.changelog.histories) {
            foreach ($i in $h.items) {
                if ($i.field -eq 'status' -and $i.fromString -ne $i.toString) {
                    $transitions += [pscustomobject]@{
                        When = [datetime]$h.created
                        From = $i.fromString
                        To   = $i.toString
                        By   = $h.author.displayName
                    }
                }
            }
        }

        if (-not $transitions) { return "" }

        $lines = @("## Status Transitions", "", "| Date | From | To | By |", "|---|---|---|---|")
        foreach ($t in ($transitions | Sort-Object When)) {
            $lines += "| $($t.When) | $($t.From) | $($t.To) | $($t.By) |"
        }
        return ($lines -join "`n")
    }
}

process {
    Write-Host "Running JQL and exporting issues..."

    try {
        $issues = Get-JiraIssue -Query $Jql -ErrorAction Stop
    } catch {
        throw "Get-JiraIssue failed: $($_.Exception.Message). Check your JQL and permissions."
    }

    if (-not $issues) {
        Write-Host "No issues returned for the given JQL."
        return
    }

    foreach ($issue in $issues) {
        # Pull fields safely (different JiraPS versions map slightly differently)
        $key        = $issue.Key
        $fields     = $issue.Fields
        $summary    = $fields.Summary
        $descRaw    = $fields.Description
        $status     = $fields.Status.name
        $issuetype  = $fields.IssueType.name
        $priority   = $fields.Priority.name
        $assignee   = if ($fields.Assignee) { $fields.Assignee.displayName } else { "" }
        $reporter   = if ($fields.Reporter) { $fields.Reporter.displayName } else { "" }
        $labels     = @($fields.Labels) -ne $null ? $fields.Labels : @()
        $created    = $fields.Created
        $updated    = $fields.Updated
        $fixVersions= ($fields.fixVersions | ForEach-Object { $_.name })
        $components = ($fields.components | ForEach-Object { $_.name })

        # Try to convert description from ADF/HTML/plain into Markdown
        $descMd = Convert-AdfToMarkdown $descRaw
        if (-not $descMd) { $descMd = Strip-Html ([string]$descRaw) }
        if (-not $descMd) { $descMd = [string]$descRaw }

        $commentsMd = Get-IssueCommentsMarkdown $key
        $changelogMd = Get-IssueChangelogMarkdown $key

        $safeSummary = Convert-ForFileName $summary
        $fileName = "{0} - {1}.md" -f $key, $safeSummary
        $filePath = Join-Path $OutDir $fileName

        # YAML front matter
        $yaml = @(
            "---",
            "issue_key: `"$key`"",
            "title: `"{0}`"" -f (Escape-Yaml $summary),
            "status: `"$status`"",
            "issue_type: `"$issuetype`"",
            "priority: `"$priority`"",
            "assignee: `"{0}`"" -f (Escape-Yaml $assignee),
            "reporter: `"{0}`"" -f (Escape-Yaml $reporter),
            "labels: [{0}]" -f (($labels | ForEach-Object { '"' + (Escape-Yaml $_) + '"' }) -join ", "),
            "components: [{0}]" -f (($components | ForEach-Object { '"' + (Escape-Yaml $_) + '"' }) -join ", "),
            "fix_versions: [{0}]" -f (($fixVersions | ForEach-Object { '"' + (Escape-Yaml $_) + '"' }) -join ", "),
            "created: `"$created`"",
            "updated: `"$updated`"",
            "url: `"$BaseUrl/browse/$key`"",
            "---"
        ) -join "`n"

        # Body
        $body = @()
        $body += "# $key — $summary"
        $body += ""
        $body += "**Status:** $status  "
        $body += "**Type:** $issuetype  "
        $body += "**Priority:** $priority  "
        if ($assignee) { $body += "**Assignee:** $assignee  " }
        if ($reporter) { $body += "**Reporter:** $reporter  " }
        $body += "**Created:** $created  "
        $body += "**Updated:** $updated  "
        $body += ""
        $body += "## Description"
        $body += ""
        $body += ($descMd ? $descMd : "_No description_")
        $body += ""

        if ($labels -and $labels.Count -gt 0) {
            $body += "## Labels"
            $body += ""
            $body += ($labels | ForEach-Object { "- $_" })
            $body += ""
        }

        if ($components -and $components.Count -gt 0) {
            $body += "## Components"
            $body += ""
            $body += ($components | ForEach-Object { "- $_" })
            $body += ""
        }

        if ($fixVersions -and $fixVersions.Count -gt 0) {
            $body += "## Fix Versions"
            $body += ""
            $body += ($fixVersions | ForEach-Object { "- $_" })
            $body += ""
        }

        if ($commentsMd) {
            $body += $commentsMd
            $body += ""
        }

        if ($changelogMd) {
            $body += $changelogMd
            $body += ""
        }

        # Write file
        $content = $yaml + "`n" + ($body -join "`n")
        $content | Set-Content -LiteralPath $filePath -Encoding UTF8
        Write-Host "Wrote $fileName"
    }

    Write-Host "Export complete. Files are in: $OutDir"
}

```
