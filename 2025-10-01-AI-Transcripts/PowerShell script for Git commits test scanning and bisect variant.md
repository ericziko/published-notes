---
transcription_date_utc: 2025-10-01T20:30:00Z
title: PowerShell script for Git commits test scanning and bisect variant
transcription-prompt-version: 2025-10-01-1
summary: |
  "The conversation covered writing a PowerShell script that iterates over a range of Git commits, checks out each one, runs .NET unit tests, and logs the number of failed tests. We then extended this into a bisect-driven variant that integrates with `git bisect run` to automatically classify commits as good, bad, or skipped based on test outcomes. Both scripts include logging, handling of TRX test result files, and preservation of the user's original repo state."
joke: "*Looks like we taught Git how to judge our code’s character — it now knows who’s good, who’s bad, and who just needs to be skipped for attitude problems.*"
document-type: chat-gpt-transcription
ai-model: gpt-5
tags:
  - -para/fleeting-thought
  - -para/resources/ai-transcript
created: 2025-10-01T13:56
updated: 2025-10-01T13:58
date created: Wednesday, October 1st 2025, 8:56:35 pm
date modified: Wednesday, October 1st 2025, 8:58:46 pm
---

# PowerShell script for Git commits test scanning and bisect variant

## powershell-git-test-scan-and-bisect

*Looks like we taught Git how to judge our code's character — it now knows who's good, who's bad, and who just needs to be skipped for attitude problems.*

---

### 🙋 question: script to step through commits and run tests
> Write me a script in PowerShell that steps through a range of commits in Git, checks each one out, and for each commit, it runs the .NET unit tests for my project and reports the number of failed tests to a log file.

### ℹ️ AI response : PowerShell script to scan commits
> Here's a robust PowerShell script that walks a Git commit range, checks each one out, runs your .NET tests, and logs results (including failed test count) to a CSV.  
> It restores your branch and stashes local changes so nothing is lost.
> 
> ```powershell
> # ... full script shown here ...
> ```
> 
> The response explained how to run it, how to tune parameters like `--filter`, and even hinted at a `git bisect` variant for pinpointing when failures began.

---

### 🙋 question: bisect driven variant
> Yes, please give me a bisect driven variant

### ℹ️ AI response : git bisect integrated script
> A full PowerShell script was provided that integrates with `git bisect`.  
> It works in two modes: controller mode (initiates bisect with given good/bad commits) and probe mode (used by `git bisect run` to classify commits).  
> It parses TRX test results and returns exit codes Git expects (0 = good, 1 = bad, 125 = skip).
> 
> ```powershell
> # ... full Bisect-DotnetTests.ps1 script here ...
> ```
> 
> Instructions for usage were given (start with known good/bad commits, run the script, let bisect auto-narrow the bad commit).  
> The script logs detailed test outcomes in CSV format and supports options like `-ThresholdFailed`, `-TestFilter`, and `-DotNetArgs`.
