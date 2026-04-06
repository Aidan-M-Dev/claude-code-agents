# Claude Code Agents for Full-Stack Web Development

A collection of 10 specialized [Claude Code subagents](https://code.claude.com/docs/en/sub-agents) that enforce a disciplined development workflow: architecture-first design, Docker-containerized environments, test-driven development, security-by-default, and clean git history.

Built for hackathons and personal projects where you want to move fast without sacrificing code quality. Every project is containerized from the first task — `docker compose up` is all anyone needs to run your code.

## Why This Exists

Running a single Claude Code session for everything — design, implementation, testing, review — leads to sloppy results. The agent tries to do too much in one pass, skips tests "to save time," and forgets to commit.

These agents fix that by **separating concerns into distinct roles**, each with its own system prompt, tool access, and quality standards. The test-writer can't implement code. The reviewer can't edit files. The committer won't commit without passing review.

## Token Efficiency

These agents are designed to minimize token usage without compromising quality:

- **Split architecture files** — instead of one large `architecture.md`, the architect produces separate files in `architecture/` (data-models.md, api-contracts.md, logging.md, etc.). Agents read only the files they need.
- **Split task files** — instead of one large `tasks.md`, the planner produces individual task files in `tasks/`. Agents read only their assigned task.
- **Orchestrator inlines context** — the orchestrator reads architecture files and passes relevant snippets directly in spawn prompts, so child agents don't re-read files the orchestrator already has in context.
- **Lean agent prompts** — agents contain only role, workflow, and output format. They don't repeat things the model already knows (REST conventions, how to write JSDoc, etc.).
- **Model tiering** — mechanical agents (planner, tdd-test-writer, code-reviewer, security-auditor, git-committer) use Sonnet. Judgment-heavy agents (architect, implementation agents) use Opus.
- **Logging standards centralized** — `architecture/logging.md` is the single source of truth. Agents reference it instead of carrying 40+ lines of duplicated logging instructions.

## The Agents

| Agent | Role | Tools | Model |
|-------|------|-------|-------|
| `orchestrator` | Manages the full pipeline, spawns all other agents | Agent(\*), Read, Write, Bash, Grep, Glob | inherit |
| `architect` | Designs system architecture → `architecture/` folder | Read, Write, Bash, Grep, Glob | inherit |
| `planner` | Decomposes architecture into tasks → `tasks/` folder | Read, Write, Grep, Glob | sonnet |
| `tdd-test-writer` | Writes failing tests from acceptance criteria (RED) | Read, Write, Edit, Bash, Grep, Glob | sonnet |
| `frontend-dev` | Implements UI components, pages, routing (GREEN) | Read, Write, Edit, Bash, Grep, Glob | inherit |
| `backend-dev` | Implements APIs, middleware, business logic (GREEN) | Read, Write, Edit, Bash, Grep, Glob | inherit |
| `database-dev` | Implements schemas, migrations, seed data (GREEN) | Read, Write, Edit, Bash, Grep, Glob | inherit |
| `code-reviewer` | Read-only code review against diff and criteria | Read, Bash, Grep, Glob | sonnet |
| `security-auditor` | Read-only security scanning, full-codebase audits | Read, Bash, Grep, Glob | sonnet |
| `git-committer` | Stages, validates, and commits with conventional messages | Read, Bash, Grep, Glob | sonnet |

## Workflow

```
                    ┌──────────────────────────────────────────────┐
                    │              orchestrator                     │
                    │  Spawns agents, reads verdicts, retries      │
                    │  (run via: claude --agent orchestrator)       │
                    └──────────────────┬───────────────────────────┘
                                       │
                    ┌──────────────────┼───────────────────────────┐
                    │                  ▼                            │
                    │  ┌─────────────┐     ┌──────────┐           │
                    │  │  architect   │────▶│  planner  │           │
                    │  │ → architecture/   │ → tasks/   │           │
                    │  └─────────────┘     └─────┬────┘           │
                    │                            │                 │
                    │          For each task in tasks/:            │
                    │                            │                 │
                    │                            ▼                 │
                    │                   ┌─────────────────┐        │
                    │                   │ tdd-test-writer  │        │
                    │                   │ (RED phase)      │        │
                    │                   └────────┬────────┘        │
                    │                            ▼                 │
                    │        ┌───────────────────────────────┐     │
                    │        │      Specialist Agent         │     │
                    │        │  (frontend / backend / db)    │     │
                    │        │  (GREEN phase)                │     │
                    │        └───────────────┬───────────────┘     │
                    │                        ▼                     │
                    │               ┌─────────────────┐            │
                    │               │  code-reviewer   │            │
                    │               │  PASS / FAIL     │◀── retry  │
                    │               └────────┬────────┘   (max 3)  │
                    │                        │ PASS                 │
                    │                        ▼                     │
                    │               ┌─────────────────┐            │
                    │               │  git-committer   │            │
                    │               └─────────────────┘            │
                    │                                              │
                    │          After all tasks:                     │
                    │          security-auditor (full codebase)     │
                    └──────────────────────────────────────────────┘
```

The `security-auditor` runs once at the end on the full codebase, not per-task. This avoids redundant scans while still catching everything before release.

## Project Structure (Generated)

When the agents build a project, they produce:

```
your-project/
├── architecture/           # Split architecture docs (one per concern)
│   ├── overview.md
│   ├── tech-stack.md
│   ├── project-structure.md
│   ├── data-models.md
│   ├── api-contracts.md
│   ├── frontend-components.md
│   ├── auth.md
│   ├── security.md
│   ├── logging.md          # Single source of truth for logging standards
│   ├── docker.md
│   ├── env-vars.md
│   └── external-deps.md
├── tasks/                  # Split task files (one per task)
│   ├── overview.md         # Sequence table with status tracking
│   ├── task-01.md
│   ├── task-02.md
│   └── ...
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .env.example
└── [application code]
```

## Docker Integration

Every project is containerized from the start. This is not optional.

**What you need on your machine:**

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) (v2, included with Docker Desktop).
- That's it. No Node.js, no Python, no database installations.

**Development workflow:**

```bash
docker compose up               # Start everything
docker compose exec app npm test    # Run tests
docker compose down -v && docker compose up -d  # Reset database
docker compose build && docker compose up -d    # Rebuild after dep changes
```

## Installation

### Prerequisites

- [Claude Code](https://code.claude.com/docs/en/overview) installed and configured.
- [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2.

### Install

```bash
git clone <this-repo-url>
cd claude-code-agents
./install.sh
```

The installer asks whether to install project-level (`.claude/agents/`) or globally (`~/.claude/agents/`).

### Manual installation

```bash
# Project-level
mkdir -p .claude/agents
cp agents/*.md .claude/agents/

# Global
mkdir -p ~/.claude/agents
cp agents/*.md ~/.claude/agents/
```

### Verify

In Claude Code, run `/agents` to see all 10 agents listed.

## Usage

### Orchestrated mode (recommended)

```bash
claude --agent orchestrator
```

Then describe what you want to build. The orchestrator handles the full pipeline:
architect → planner → (test-writer → specialist → reviewer → committer) per task → final security audit.

**Make it the default** by adding to `.claude/settings.json`:

```json
{
  "agent": "orchestrator"
}
```

### Manual mode

Invoke each agent yourself:

```
Use the architect agent to design a task management app with Vue.js
Use the planner agent to create tasks from the architecture
Use the tdd-test-writer agent to write tests for Task 1
Use the backend-dev agent to implement Task 1
Use the code-reviewer agent to review Task 1
Use the git-committer agent to commit Task 1
```

### Hackathon speed mode (manual only)

- Skip `code-reviewer` if tests pass and you trust the implementation.
- Combine tasks by telling an agent to handle multiple at once.
- Keep `tdd-test-writer` — cheap and catches bugs early.
- Keep `git-committer` — clean commits save time on reverts and demos.
- Keep Docker — 5-minute setup saves you at demo time.

## Customization

### Changing the tech stack

Edit `architect.md` to hardcode preferences in its "Decision Principles" section.

### Adding specialist agents

Create a new `.md` file following the [subagent format](https://code.claude.com/docs/en/sub-agents#write-subagent-files), then update `planner.md` (agent assignment) and `orchestrator.md` (team table + Agent() tool list).

### Changing models

Edit the `model:` field in agent frontmatter. Options: `opus`, `sonnet`, `haiku`, or a full model ID.

## Design Decisions

**Why split architecture and task files?** Token efficiency. A monolithic architecture.md gets re-read by every agent — 10 agents × 10k tokens = 100k wasted tokens per project. Split files let agents read only the 1-2 files they need. The orchestrator can also inline relevant snippets in spawn prompts, eliminating file reads entirely.

**Why an orchestrator?** Without it, you're manually invoking agents in sequence and tracking task state. The orchestrator eliminates that overhead and optimizes token usage by extracting context for child agents.

**Why separate test-writer and implementation agents?** Same agent writing tests and code produces tests that match the planned implementation, not the actual behavior spec.

**Why are reviewer and auditor read-only?** Edit access leads to silent "fixes" that hide problems. Read-only forces articulation of every issue.

**Why security audit at the end, not per-task?** Per-task audits duplicate work and burn tokens. A single comprehensive audit at the end catches everything with one pass.

**Why Docker from Task 1?** "It works on my machine" is the most common demo-day failure. One command to run the project, guaranteed.

## Troubleshooting

**Agent not showing up in `/agents`** — Restart Claude Code. Agents load at session start.

**Orchestrator can't spawn agents** — Must run with `claude --agent orchestrator`. Subagents can't spawn subagents.

**Orchestrator writes code directly** — Interrupt and say "delegate this to the [specialist] agent."

**Tests pass when they should fail (RED)** — The tdd-test-writer investigates this. Usually means a previous task already implemented the behavior.

**Code reviewer too strict/lenient** — Edit the checklist in `code-reviewer.md`.

**Docker won't start** — Run `docker compose logs`. Common: port conflicts, missing `.env`, stale images.

**Hot reload not working** — Add `usePolling: true` to dev server config (Vite: `server.watch.usePolling`).
