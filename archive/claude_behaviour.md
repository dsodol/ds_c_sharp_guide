# Claude Behaviour

## 0. Additional directories outside of the project
These directories are separate git repos.

C:\Users\dsodo\project\built_with_ai\ds_c_sharp_guide

## 1. Reference Locations

1.1. Read C# Guide: C:\Users\dsodo\project\built_with_ai\ds_c_sharp_guide\cc_csharp_guide_v2.md

---

## 2. Command Reference (Windows)

2.1. **Running PowerShell from Bash:** Use double backslash to escape `$`:
```bash
powershell -Command "\\$var = something; Write-Host \\$var"
```

2.2. **Starting processes:** Use PowerShell to start the **compiled executable** and capture PID:
```bash
powershell -Command "\\$proc = Start-Process -FilePath '.\\App.exe' -PassThru; Write-Host 'PID:' \\$proc.Id"
```

2.3. **Killing processes:**
```bash
powershell -Command "Stop-Process -Id <PID>"
```

2.4. **Multiple git repos:**
```bash
git -C /path/to/repo status
```

---

2.5 ** misc **

## Rules

1. **Always enter plan mode before implementing any changes.** Do not execute code modifications until the plan is reviewed and approved.

## Hook Behaviour

1. **Stop on hook block:** If a hook denies permission during batch processing, STOP immediately. Do not continue with remaining operations.
2. **Report the block:** Explain what was blocked and why.
3. **Wait for guidance:** Ask the user how to proceed.
4. **Exception:** During hook testing (`th` command), continue processing to verify all hooks work correctly.

## Shortcuts

- "th" = Test hooks (run hook permission tests below)

## Test Hooks ("th")

When user says "th", run these tests and report results:

### Should PASS (allowed):
1. **Read project file:** Read `CLAUDE.md` in this project
2. **Read additional dir:** Read a file from `../ds_c_sharp_guide/`
3. **Glob project:** Glob for `*.md` in project root
4. **Bash relative:** Run `dir .`

### Should BLOCK (denied):
5. **Read outside:** Try to read `C:\Windows\System32\drivers\etc\hosts`
6. **Bash outside:** Try `cat C:\Windows\win.ini`

### Report format:
```
Hook Tests:
1. Read project:     [PASS/FAIL]
2. Read additional:  [PASS/FAIL]
3. Glob project:     [PASS/FAIL]
4. Bash relative:    [PASS/FAIL]
5. Read outside:     [BLOCKED/FAIL - should block]
6. Bash outside:     [BLOCKED/FAIL - should block]
```


## 3. Session Start Checklist

Go through each item below. For each, explain in your own words what it means and how you will apply it. Do not just acknowledge — demonstrate understanding with specific examples.

**Project:**
- [ ] 3.1. Read spec_high_level.md IN THE PROJECT DIRECTORY if exists.
- [ ] 3.2. Read C# guide Section 1.4
- [ ] 3.3. Read detailed docs only IF NEEDED for specific task

**Core Rules:**
- [ ] 3.4. STOP on non-trivial issues — DO NOT fix automatically. Explain the issue, propose a solution, wait for approval.
- [ ] 3.5. Report errors immediately — never ignore failed commands or tool errors.
- [ ] 3.6. Verify before proceeding — after each major step, confirm success before moving on.
- [ ] 3.7. NEVER tell the user to do something yourself. Your job is to DO, not to instruct.
- [ ] 3.7.1  Never scan or list directories outside the current project unless given an exact file path. If I need to find something, ask the user for the specific path — do not explore or search parent directories, sibling directories, or any location I wasn't explicitly pointed to
- [ ] 3.7.2 If the user tells you to explain: stop. Think what you did wrong. Explain in the detail. DO NOT CONTINUE UNLESS THE USER TELSS YOU TO.
- [ ] 3.7.3 When launching any agent (Explore, Plan, or other), explicitly state in the prompt:
  The exact project directory boundary (e.g., c:\Users\dsodo\project\built_with_ai\cc_component_test)
  "Do NOT explore, list, or access any directories outside this project"
  "If you need information from external files, STOP and report what you need — do not search for it"
**Process Management:**
- [ ] 3.8. Start the compiled .exe directly — never use `dotnet run` (spawns child process with different PID).
- [ ] 3.9. Do NOT use `-NoNewWindow` for interactive console apps.
- [ ] 3.10. Build first with `dotnet build` or `dotnet publish`, then start the executable.
- [ ] 3.11. Capture PID at startup.
- [ ] 3.12. Verify startup via logs — a process may start but fail internally. Only proceed after confirming logs show successful startup.
- [ ] 3.13. Claude Code must only kill processes Claude Code started, only by PID. If PID not captured, ask user to stop manually.
- [ ] 3.14. Multiple git repos: use explicit paths `git -C /path/to/repo`.

**Shortcuts:**
- [ ] 3.15. "r" = read CLAUDE.md and follow instructions.
- [ ] 3.16. "add to guide" = add C# specific principle to cc_csharp_guide_v1.md.
- [ ] 3.17. "reread the guide" = reread C# guide.

**Maintenance:**
- [ ] 3.18. Update DS.McpServer manual when adding new features.

**Ready:**
- [ ] 3.19. Confirm understanding of current task.
