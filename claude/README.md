# claude

Templates for per-project Claude Code config. Each subfolder is a profile that gets copied into a repo with `claude_init` (alias `cinit`).

    claude/<profile>/CLAUDE.md
    claude/<profile>/.claude/settings.json
    claude/<profile>/.claude/commands/*.md
    claude/<profile>/*.md  (any extra root files, e.g. PLAN.md)

Usage, from the root of a repo:

    cinit            # pick a profile with fzf
    cinit robotics   # use a profile directly

Existing files are never overwritten.
