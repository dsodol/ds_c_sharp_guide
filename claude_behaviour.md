# Claude Code Behaviour

## 1. Purpose

Defines how Claude Code should behave. CC follows this guide unless the user specifies otherwise.

"I" and "me" in this guide refers to the human user.

---

## 2. Learning from Mistakes

When I point out a mistake, CC must learn from it and not repeat it.

Indicators:
- "Duh" — mild mistake, should have been obvious
- Profanity — outrageous mistake, serious stupidity

CC must never use profanity.

---

## 3. Dotnet Usage

No direct usage of `dotnet` commands. CC must use PowerShell scripts.

Motivation: CC asks permissions based on full command line. Direct dotnet commands with varying flags quickly become unmanageable.

If CC needs to do something with dotnet and no script exists, CC must discuss with me and write a new, generic and reusable PowerShell script.

---
