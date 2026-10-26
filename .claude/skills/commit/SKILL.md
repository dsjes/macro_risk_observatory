---
name: commit
description: Run pre-commit checks (linting, code review) on staged changes and provide a git commit message. Use when the user says "commit", "commit 一下".
allowed-tools: Bash(rtk git diff:*), Bash(rtk git status:*), Bash(rtk git log:*), Bash(rtk uv run ruff:*), Bash(rtk python3 -m ruff:*), Bash(git diff:*), Bash(git status:*), Bash(git log:*), Bash(uv run ruff:*), Bash(python3 -m ruff:*)
---

# Git Commit Skill

Run a full check on **staged changes** before creating a Git commit.

## Hard Rule

**Never run `git commit` (or `git add`) yourself.** Only provide the commit message and let the user commit. This is a safety requirement.

## Conventions

- Prefix commands with `rtk` (e.g. `rtk git diff`). If `rtk` is not installed, run the plain `git` / `uv` command instead.
- Only staged changes are in scope. Always use `git diff --cached`.
- If nothing is staged, stop and tell the user to stage files first.

## Workflow

### Phase 1: Code Quality Check

1. **Ruff Linting**

- Get staged Python files: `rtk git diff --cached --name-only --diff-filter=d`, keep files ending in `.py`
- If there are no staged `.py` files, skip this phase
- Run linting with the first runner that exists (fall back to the next only if the command is not found, not if lint fails):
  ```bash
  rtk uv run ruff check <staged_py_files>
  rtk python3 -m ruff check <staged_py_files>
  ```
- Also run `ruff format --check <staged_py_files>` with the same runner
- Fixing: you may apply `ruff check --fix` for auto-fixable lint errors; fix the rest by hand. Do not run `ruff format` (report formatting issues instead), and do not stage the fixes. Tell the user which files changed so they can re-stage.

### Phase 2: Code Review

2. **Inspect the staged changes**

- Run `rtk git diff --cached --stat` to understand the scope
- Then review file by file with `rtk git diff --cached -- <file>`; do not dump one huge diff for large changesets

3. **Code review checklist**
   For each staged file, check:

- [ ] Is the logic correct?
- [ ] Are there potential bugs or unhandled edge cases?
- [ ] Are there security issues (e.g. SQL injection, XSS, hardcoded passwords)?
- [ ] Are names clear and consistent with project conventions?
- [ ] Is there unnecessary duplicated code?
- [ ] Is the code concise and free of over-engineering (needless abstractions, speculative flexibility, unused parameters or code paths), so it stays easy to maintain?
- [ ] Is error handling complete?
- [ ] Is any logging missing, or is there too much logging?
- [ ] Is any sensitive information left in, such as keys, passwords, hosts, or IPs?

Project-specific checks:

- [ ] Airflow DAGs (`dags/`): sensible `schedule`, `retries`, and idempotent tasks (safe to re-run)
- [ ] SQL (`sql/`, `src/`): parameterized queries, no string-formatted user input
- [ ] No staged files from `.env`, `secrets/`, `logs/`, or `.venv/` (`.env.example` is fine)

4. **Handle issues by severity**

- **Blocking** (security problems, sensitive data, definite bugs): stop, list the issues, and wait for the user to decide whether to fix before continuing
- **Minor** (style, naming, small suggestions): do not stop; list them in the final report

### Phase 3: Prepare the Commit

5. **Check Git status**

- Run `rtk git status` to confirm what is staged and what is not
- Run `rtk git log --oneline -5` to see recent commit messages (if history is too short to show a style, rely on the format below)

6. **Compose the commit message**

- Write it in English, based on the staged changes
- Explain _why_ the change was made, not just what
- If the staged changes mix unrelated concerns, suggest splitting them into separate commits

## Commit Message Format

```
<type>: <short description>

<optional one-line body explaining why>
```

Rules:

- Subject line ≤ 72 characters, imperative mood, lowercase after the type, no trailing period
- Add a body only when the subject alone does not make the reason clear

**Types**:

- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Refactoring (no behavior change)
- `docs`: Documentation changes
- `test`: Test-related changes
- `chore`: Miscellaneous (config, build, etc.)
- `perf`: Performance improvement

## Final Report

Use this output format:

```
✅ Ruff: passed | skipped (no .py files) | N issues fixed | N issues remaining
✅ Code review: no issues | N minor notes (listed below) | blocking issues (stopped)

Minor notes:
- <file>: <note>

Commit message:
<code block with the message>

Staged files:
- <file list>
```

Remind the user to commit themselves (and to re-stage any files that Ruff modified).
