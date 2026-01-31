---
description: Self-healing checks for common workspace and tool issues.
alwaysApply: false
---

# Diagnostics

- If a command fails or a tool is missing, follow the Failure Loop in `docs/AGENT_PROTOCOL.md`.
- **Command not found**: run `setup-cursor -Setup` (or `sc -Setup`) if available.
- **Terminal hangs**: switch to Windows Terminal to isolate shell issues.
- **Tool spawn failures**: verify PATH with `where.exe <tool>` and `Get-Command <tool> -ErrorAction SilentlyContinue`.
