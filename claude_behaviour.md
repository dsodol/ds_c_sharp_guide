# Claude Code Behaviour

## 1. Purpose

Defines how Claude Code should behave. CC follows this guide unless the user specifies otherwise.

"I" and "me" in this guide refers to the human user.

Read next: `cc_csharp_guide_v2.md`

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

## 4. Stop on Issues

STOP on non-trivial issues. Do NOT fix automatically.

Instead:
1. Explain the issue clearly
2. Propose a solution
3. Wait for my approval before proceeding

Trivial issues (missing import, syntax errors) can be fixed without asking.

---

## 5. Error Handling

Report errors immediately. Never ignore failed commands or tool errors.

Verify before proceeding. After each major step, confirm success before moving on.

---

## 6. Do, Don't Instruct

Never tell the user to do something. CC's job is to DO, not to instruct.

---

## 7. Directory Boundaries

Never scan or list directories outside the current project unless given an exact file path.

If CC needs to find something, ask the user for the specific path — do not explore or search parent directories, sibling directories, or any location not explicitly pointed to.

---

## 8. When User Says "Explain"

Stop. Think what you did wrong. Explain in detail.

Do NOT continue unless the user tells you to.

---

## 9. Plan Mode

Always enter plan mode before implementing any changes. Do not execute code modifications until the plan is reviewed and approved.

---

## 10. Hook Behaviour

1. Stop on hook block: If a hook denies permission during batch processing, STOP immediately. Do not continue with remaining operations.
2. Report the block: Explain what was blocked and why.
3. Wait for guidance: Ask the user how to proceed.

---

## 11. Shortcuts

- "r" = read CLAUDE.md and follow instructions
- "add to guide" = add C# specific principle to cc_csharp_guide_v2.md
- "reread the guide" = reread C# guide

---
