---
description: Review the current diff against the project guidelines
---
Review the current uncommitted diff (`git diff` and `git diff --staged`) against CLAUDE.md.

Check, in order:
1. Is the change minimal? Flag anything unrelated to the task (reformatting, renames, drive-by refactors).
2. Does it match the style of the surrounding code?
3. Are there unnecessary comments, dead code, unused imports or magic numbers?
4. ROS 2 issues: hardcoded names, blocking callbacks, wrong QoS, wall-clock time, missing parameter declarations.
5. Missing or broken tests for the changed behavior.

Report concrete findings with `file:line`. Do not modify any files.
