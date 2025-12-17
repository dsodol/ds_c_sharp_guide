# Claude Behaviour

## 1. Reference Locations

1.1. C# Guide: C:\Users\dsodo\project\built_with_ai\ds_c_sharp_guide\cc_csharp_guide_v1.md (repo: dsodol/ds_c_sharp_guide)

1.2. DS.McpServer Manual: C:\Users\dsodo\project\built_with_ai\ds_c_sharp_guide\ds_mcp_server_manual.md (repo: dsodol/ds_c_sharp_guide)

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

## 3. Session Start Checklist

Go through each item below. For each, explain in your own words what it means and how you will apply it. Do not just acknowledge — demonstrate understanding with specific examples.

**Project:**
- [ ] 3.1. Read [spec_high_level.md](spec_high_level.md)
- [ ] 3.2. Read C# guide Section 1.4
- [ ] 3.3. Read detailed docs only IF NEEDED for specific task

**Core Rules:**
- [ ] 3.4. STOP on non-trivial issues — DO NOT fix automatically. Explain the issue, propose a solution, wait for approval.
- [ ] 3.5. Report errors immediately — never ignore failed commands or tool errors.
- [ ] 3.6. Verify before proceeding — after each major step, confirm success before moving on.
- [ ] 3.7. NEVER tell the user to do something yourself. Your job is to DO, not to instruct.

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
