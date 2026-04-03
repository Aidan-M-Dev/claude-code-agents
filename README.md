# Claude Code Agents for Full-Stack Web Development

A collection of 9 specialized [Claude Code subagents](https://code.claude.com/docs/en/sub-agents) that enforce a disciplined development workflow: architecture-first design, Docker-containerized environments, test-driven development, security-by-default, and clean git history.

Built for hackathons and personal projects where you want to move fast without sacrificing code quality. Every project is containerized from the first task — `docker compose up` is all anyone needs to run your code.

## Why This Exists

Running a single Claude Code session for everything — design, implementation, testing, review — leads to sloppy results. The agent tries to do too much in one pass, skips tests "to save time," and forgets to commit.

These agents fix that by **separating concerns into distinct roles**, each with its own system prompt, tool access, and quality standards. The test-writer can't implement code. The reviewer can't edit files. The committer won't commit without passing security checks. Structure prevents shortcuts.

## The Agents

| Agent | Role | Tools | Phase |
|-------|------|-------|-------|
| `architect` | Designs system architecture, produces `architecture.md` | Read, Write, Bash, Grep, Glob | Planning |
| `planner` | Decomposes architecture into sequenced tasks in `tasks.md` | Read, Write, Grep, Glob | Planning |
| `tdd-test-writer` | Writes failing tests from acceptance criteria (RED phase) | Read, Write, Edit, Bash, Grep, Glob | Quality |
| `frontend-dev` | Implements UI components, pages, routing, state (GREEN phase) | Read, Write, Edit, Bash, Grep, Glob | Implementation |
| `backend-dev` | Implements APIs, middleware, business logic (GREEN phase) | Read, Write, Edit, Bash, Grep, Glob | Implementation |
| `database-dev` | Implements schemas, migrations, seed data (GREEN phase) | Read, Write, Edit, Bash, Grep, Glob | Implementation |
| `code-reviewer` | Read-only code review against standards and architecture | Read, Bash, Grep, Glob | Quality |
| `security-auditor` | Read-only security scanning and vulnerability analysis | Read, Bash, Grep, Glob | Quality |
| `git-committer` | Stages, validates, and commits with conventional commit messages | Read, Bash, Grep, Glob | Commit |

## Workflow

Every feature follows the same pipeline. The planner encodes this sequence into `tasks.md`, so you just work through tasks in order.

```
┌─────────────┐     ┌──────────┐
│  architect   │────▶│  planner  │
│              │     │           │
│ Designs the  │     │ Creates   │
│ system       │     │ tasks.md  │
└─────────────┘     └─────┬────┘
                          │
            For each task in tasks.md:
                          │
                          ▼
                 ┌─────────────────┐
                 │ tdd-test-writer  │
                 │                  │
                 │ Writes failing   │
                 │ tests (RED)      │
                 └────────┬────────┘
                          │
                          ▼
          ┌───────────────────────────────┐
          │      Specialist Agent         │
          │  (frontend / backend / db)    │
          │                               │
          │  Implements to pass tests     │
          │  (GREEN)                      │
          └───────────────┬───────────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │  code-reviewer   │
                 │                  │
                 │  Read-only       │
                 │  PASS / FAIL     │◀── if FAIL, specialist fixes
                 └────────┬────────┘
                          │ PASS
                          ▼
                 ┌─────────────────┐
                 │  git-committer   │
                 │                  │
                 │  Security scan   │
                 │  + Commit        │
                 └─────────────────┘
```

The `security-auditor` can be invoked independently at any time for a full-codebase audit, or the `git-committer` will run its own pre-commit security checks before each commit. For higher-stakes projects, invoke `security-auditor` explicitly between `code-reviewer` and `git-committer`.

## Docker Integration

Every project built with these agents is containerized from the start. This is not optional — it's baked into every agent's behavior.

**What the agents do automatically:**

- The **architect** includes a Docker & Containerization section in `architecture.md` specifying Dockerfile, docker-compose.yml services, volumes, health checks, and networking.
- The **planner** makes Docker scaffolding the first task. After Task 1, `docker compose up` works.
- The **database-dev** runs the database as a Docker Compose service. Connection strings use service names (`db:5432`), not `localhost`. Data persists in named volumes.
- The **backend-dev** binds the server to `0.0.0.0` inside the container and uses Docker Compose service names for inter-service communication.
- The **frontend-dev** configures the dev server for Docker (bind `0.0.0.0`, polling-based HMR if needed, API proxy to the backend service).
- The **tdd-test-writer** and implementation agents run tests via `docker compose exec`.
- The **security-auditor** scans Dockerfiles for running as root, unpinned base images, leaked secrets in build layers, and missing `.dockerignore`.
- The **git-committer** verifies Docker files don't contain hardcoded secrets before committing.

**What you need on your machine:**

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) (v2, included with Docker Desktop).
- That's it. No Node.js, no Python, no database installations. Everything runs in containers.

**Development workflow:**

```bash
# Start everything
docker compose up

# Run tests
docker compose exec app npm test

# Run a specific agent's work
docker compose exec app npm run db:migrate

# Reset the database
docker compose down -v && docker compose up -d

# Rebuild after dependency changes
docker compose build && docker compose up -d
```

## Installation

### Prerequisites

- [Claude Code](https://code.claude.com/docs/en/overview) installed and configured.
- [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2 (included with Docker Desktop).

### Install

Clone this repo, then run the installer:

```bash
git clone <this-repo-url>
cd claude-code-agents
./install.sh
```

The installer asks whether to install project-level (`.claude/agents/`) or globally (`~/.claude/agents/`).

**Project-level** is recommended — it keeps the agents versioned with your code and lets teammates use the same workflow.

**Global** is useful if you want these agents available in every project without copying them each time.

### Manual installation

Copy the `agents/` directory contents to either location:

```bash
# Project-level
mkdir -p .claude/agents
cp agents/*.md .claude/agents/

# Global
mkdir -p ~/.claude/agents
cp agents/*.md ~/.claude/agents/
```

### Verify

In Claude Code, run `/agents` to see all 9 agents listed.

## Usage Guide

### Starting a new project

**Step 1 — Design the architecture.** Describe what you want to build. The architect agent asks clarifying questions if needed and produces `architecture.md`.

```
Use the architect agent to design a task management app with user auth,
project boards, and real-time updates. Use Vue.js for the frontend.
```

Review `architecture.md`. Edit it yourself if you disagree with any decisions — it's the source of truth for all downstream agents.

**Step 2 — Create the task plan.** The planner reads `architecture.md` and produces `tasks.md` with sequenced, dependency-aware tickets.

```
Use the planner agent to create tasks from the architecture
```

Review `tasks.md`. Reorder, remove, or add tasks as needed.

**Step 3 — Work through tasks.** For each task, follow the sequence. The task in `tasks.md` tells you which agent to use.

```
Use the tdd-test-writer agent to write tests for Task 1

Use the database-dev agent to implement Task 1

Use the code-reviewer agent to review Task 1

Use the git-committer agent to commit Task 1
```

Repeat for each task.

### Handling review failures

If `code-reviewer` returns a FAIL verdict, re-invoke the implementation agent with the feedback:

```
Use the backend-dev agent to fix the issues found by code-reviewer:
[paste the BLOCKING issues or let Claude read from context]
```

Then re-run `code-reviewer`. Repeat until PASS.

### Skipping steps (hackathon speed mode)

For hackathons where speed matters more than thoroughness, you can compress the workflow:

- **Skip `code-reviewer`** if you trust the implementation agent and tests are passing.
- **Combine tasks** by telling an agent to handle multiple tasks at once.
- **Keep `tdd-test-writer`** — the cost of writing tests first is low and catches bugs early.
- **Keep `git-committer`** — clean commits save time when you need to revert or demo.
- **Keep Docker** — don't skip this even for speed. The 5-minute setup cost saves you when someone else needs to run your project or when you demo on a different machine.

### Running a security audit

For a full-codebase security review at any time:

```
Use the security-auditor agent to audit the entire codebase
```

### Adding to an existing project

The agents work on existing codebases. The architect reads existing code before designing, and the planner accounts for what's already built.

```
Use the architect agent to design a new notifications feature
for this existing project
```

## Customization

### Changing the tech stack

The agents are framework-agnostic. The `architect` agent decides the tech stack based on your requirements, and all downstream agents read `architecture.md` to know what tools to use.

If you always use a specific stack, edit `architect.md` to hardcode your preferences in its "Decision Principles" section.

### Adding new specialist agents

Create a new `.md` file in the agents directory following the [Claude Code subagent format](https://code.claude.com/docs/en/sub-agents#write-subagent-files):

```yaml
---
name: your-agent-name
description: >
  When Claude should delegate to this agent.
tools: Read, Write, Edit, Bash, Grep, Glob
model: inherit
---

Your system prompt here.
```

Then update `planner.md` to include your new agent in its "Agent Assignment" section so it knows to assign tasks to it.

### Changing models

Each agent's `model` field controls which Claude model it uses. The defaults are:

- `inherit` (uses your session's model) for agents that need strong reasoning — architect, planner, tdd-test-writer, all implementation agents, code-reviewer.
- `sonnet` for cost-effective pattern matching — security-auditor, git-committer.

To change an agent's model, edit the `model:` line in its frontmatter. Options: `opus`, `sonnet`, `haiku`, or a full model ID like `claude-sonnet-4-6`.

## Design Decisions

**Why separate test-writer and implementation agents?** When the same agent writes tests and code, it unconsciously writes tests that match its planned implementation rather than testing behavior. A separate agent writes tests purely from acceptance criteria, producing more honest coverage.

**Why are reviewer and auditor read-only?** Agents with edit access tend to silently "fix" issues instead of reporting them, hiding problems. Read-only agents must articulate every issue, giving you visibility into code quality.

**Why conventional commits?** Machine-parseable commit messages enable automatic changelog generation, semantic versioning, and easier git bisect when debugging.

**Why per-task commits instead of feature branches?** For hackathons and solo projects, per-task commits on the main branch are simpler and provide fine-grained rollback points. For team projects, you can easily adapt this to feature branches by adding a branch step before the first task.

**Why Docker from Task 1?** "It works on my machine" is the most common demo-day failure at hackathons. Containerizing from the start means every teammate (and every judge) can run the project with one command. It also eliminates "install Node 18 not 20" type issues and makes the database setup automatic. The small upfront cost of writing a Dockerfile pays for itself immediately.

## Troubleshooting

**Agent not showing up in `/agents`** — Restart Claude Code. Agents are loaded at session start. If installed to `.claude/agents/`, make sure you're in the project root.

**Agent ignores its instructions** — Subagents get ONLY their own system prompt, not the main Claude Code system prompt. If an agent seems confused, check that its `.md` file has the correct frontmatter and that its prompt is self-contained.

**Tests pass when they should fail (RED phase)** — The tdd-test-writer agent is designed to catch this. If it reports tests passing, it investigates whether the feature already exists. If you hit this, it usually means a previous task already implemented the behavior.

**Code reviewer is too strict / too lenient** — Edit the review checklist in `code-reviewer.md`. Mark items as BLOCKING or NON-BLOCKING to match your standards.

**Security auditor false positives** — The auditor is instructed to verify grep results by reading the actual code. If it's still producing false positives, add exclusion patterns to its grep commands for your specific codebase patterns.

**Docker containers won't start** — Run `docker compose logs` to see error output. Common causes: port conflicts (another service on the same port), missing `.env` file (copy from `.env.example`), or stale images after dependency changes (run `docker compose build --no-cache`).

**Tests fail in Docker but pass locally** — Usually a networking issue. Tests that hit the database must use the Docker Compose service name (`db`) as the host, not `localhost`. Check your test config's database URL. Also check that the database container is healthy before tests run: `docker compose ps` should show the db service as "healthy."

**Hot reload not working in Docker** — File watchers sometimes don't detect changes through Docker volume mounts, especially on macOS and Windows. The frontend-dev and backend-dev agents are instructed to configure polling mode, but if they miss it, add `usePolling: true` to your Vite/webpack/nodemon config. For Vite specifically, set `server.watch.usePolling: true` in `vite.config.ts`.

**Database data disappeared** — If you ran `docker compose down -v`, the `-v` flag deletes named volumes (including database data). Use `docker compose down` (without `-v`) to stop services while keeping data. Use `docker compose down -v` intentionally when you want a fresh database.

## License

MIT
