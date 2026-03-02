# Workshop Demo Project

A minimal Rails 7.1 property management app for workshop exercises.

## Intentional issues (for workshop exercises)

1. **Missing validation** — WorkOrder allows empty descriptions (bug fix exercise)
2. **N+1 query** — WorkOrdersController#index loads associations one by one
3. **No Pundit authorization** — create endpoint has no access control
4. **No service objects** — business logic lives in controller
5. **No escalation logic** — old unassigned work orders stay at normal priority (BDD exercise)

## Tech stack
- Ruby on Rails 7.1
- PostgreSQL
- RSpec + FactoryBot
- Pundit (installed but not used yet)

## Commands
- `bundle exec rspec` — run tests
- `bin/rails server` — start dev server
- `bin/rails console` — Rails console

---

# Agentic Development Workshop Instructions

## From AI assistant to AI colleague: hands-on for Ruby on Rails + React teams

Per Hassle · Monterro · March 3–4, 2026

---

## Day 1 — Tuesday 13:00–16:00

| Time | Block | The colleague journey |
|------|-------|----------------------|
| 13:00–13:15 | Intro | Why hire an AI colleague? |
| 13:15–14:15 | Workshop 1 | Meet your new colleague |
| 14:15–14:25 | Break | |
| 14:25–15:30 | Workshop 2 | Onboard her |
| 15:30–15:45 | Workshop 3 | Give her a real task |
| 15:45–16:00 | Q&A + homework | |

---

### Intro: Why hire an AI colleague? (13:00–13:15)

**Today's through-line: You've got a new colleague.**

She's brilliant at development — if she gets the right context.
Just like a new developer on day 1: knows nothing about your system. Give her onboarding and she delivers.

Over two sessions we take her through four steps:

```
Today (Tue 13–16):
1. MEET      → What can she do? How does she think?
2. ONBOARD   → Give her context about your project
3. REAL TASK → Try a real Shortcut ticket

Tomorrow (Wed 09–12):
4. TRAIN     → Skills, hooks, integrations
5. TEAM UP   → Multi-agent workflows
6. FULL FLOW → Real work with everything combined
```

**What you'll take home:**
- Understand the paradigm shift — from assistant to agent
- Patterns that work regardless of tool
- An AGENTS.md tailored for your Rails + React codebase
- Automated quality: skills, hooks, MCP integrations
- Multi-agent patterns for feature development
- Experience with real Shortcut tickets using Claude Code

> **Today's tool:** Claude Code — but the patterns apply to all agent tools.

---

### Workshop 1: Meet your new colleague (13:15–14:15)

#### Three generations of AI coding help

```
2020    Autocomplete     →  Suggests the next line
2023    Chat             →  "Explain this code"
2025    Agent            →  Reads repo, edits files, runs tests, fixes errors
2026    Agentic dev      →  You lead — she executes entire tasks
```

#### Assistant vs. colleague

| Assistant | Colleague |
|-----------|-----------|
| You ask → get an answer | You describe a goal → she executes |
| One file at a time | Reads, edits, creates across files |
| You copy-paste | She runs commands, sees errors, fixes them |
| You drive | You lead, she drives |

#### The secret: AGENTS.md

One file changes everything. It's her **onboarding document**.

**Without AGENTS.md:**
```
"Add a properties search endpoint"
→ Creates Express controller     ← Wrong: project is Rails
→ Uses Sequelize                 ← Wrong: ActiveRecord
→ Writes Jest tests              ← Wrong: RSpec
```

**With AGENTS.md (15 lines):**
```
"Add a properties search endpoint"
→ Creates app/controllers/api/v1/properties_controller.rb  ✅
→ Uses ActiveRecord scopes + Pundit policy                 ✅
→ Adds serializer + RSpec request spec                     ✅
```

Same task. Same agent. Only difference: 15 lines of context.

AGENTS.md works with every tool — Claude Code, Copilot, Cursor, Gemini CLI. Write once, every agent reads it.

#### How she thinks: the context window

Think of it as her **desk**. Everything she's working with sits on it — when it's full, things fall off the edge.

```
┌─────────────────────────────────────────┐
│  CONTEXT WINDOW (200K tokens)           │
│                                         │
│  AGENTS.md            ~2K tokens        │
│  Your conversation     grows            │
│  Files she's read     ~1-5K/file        │
│  Results (tests, errors)  varies        │
│                                         │
│  ← Full? Earliest context forgotten     │
└─────────────────────────────────────────┘
```

**200K tokens ≈ 500 pages of code.** Sounds like a lot — fills up fast.

#### Context windows across tools (March 2026)

| Model / Tool | Context window | Notes |
|---|---|---|
| **Claude Sonnet 4.6** | 200K tokens | Default in Claude Code |
| **Claude Opus 4.6** | 1M tokens (beta) | 5x larger — for complex tasks |
| **GPT-5.3 Codex** | 400K tokens | OpenAI's coding agent |
| **Gemini CLI** | 1M tokens | Google's open-source agent |
| **Codex Spark** | 128K tokens | Fast, real-time variant |

#### Keeping the desk clean

- `/context` — how full is the desk?
- `/compact` — clean it, keep a summary
- **`/clear` between tasks** — the #1 beginner mistake is mixing tasks in one session
- **Commit between phases** — the plan survives in git, not in memory
- Keep AGENTS.md short (< 150 lines)

#### Cost & speed

| Task | Agent time | Agent cost | Human cost (~$37/h) |
|------|-----------|-----------|-------------------|
| Simple bug fix | 2–5 min | $0.05–0.15 | $2–3 |
| New Rails endpoint + tests | 5–15 min | $0.20–0.80 | $9–18 |
| Larger feature (multi-file) | 15–45 min | $1–5 | $18–55 |

#### Commands to know

| Command | What it does |
|---------|-------------|
| `Shift+Tab` | Normal → Auto-accept → Plan |
| `/clear` | Clear conversation (fresh context) |
| `/context` | Show context window usage |
| `/permissions` | Pre-approve tools (less clicking "yes") |
| `Ctrl+C` | Cancel current generation |
| `claude -c` | Resume last conversation |
| `Esc + Esc` | Rewind |

#### Hands-on 1: Try it yourself (15 min)

1. `cd your-project && claude`
2. Ask: "What does this project do? What's the tech stack?"
3. **Plan mode** (Shift+Tab x 2):
   - "We need to add [a small feature]. Ask me questions to clarify, then give me 2 options."
   - Review the plan — don't accept yet. Iterate: "What about edge case X?"
   - When the plan looks good → accept → let her build
4. Try a bug fix: describe a symptom, let her find the cause

**Write down what she gets wrong — we'll fix it in Workshop 2.**

---

### Workshop 2: Onboard your AI colleague (14:25–15:30)

#### The onboarding document: AGENTS.md

**AGENTS.md** — used by 60,000+ GitHub repos, supported by every major tool.

| Tool | Reads AGENTS.md? | Also reads |
|------|:-:|---|
| **Claude Code** | Yes | `CLAUDE.md` |
| **GitHub Copilot** | Yes | `.github/copilot-instructions.md` |
| **Cursor** | Yes | `.cursorrules` |
| **Gemini CLI** | Yes | `GEMINI.md` |
| **Windsurf** | Yes | `.windsurfrules` |

Write once. Every agent reads the same rules.

#### Three layers — just like onboarding a human

| Layer | What | Example |
|-------|------|---------|
| **WHAT** | Tech stack, project structure | "Ruby on Rails 7 + React 18" |
| **WHY** | Purpose of key components | "app/services/ = business logic, never in controllers" |
| **HOW** | Commands, rules, workflow | "`bundle exec rspec` before every commit" |

#### Example: AGENTS.md for a Rails + React project

```markdown
# Project Name

## About
Property management platform. Ruby on Rails 7 backend + React frontend
(migrating from legacy JavaScript). PostgreSQL.
RSpec + FactoryBot for tests. Pundit for authorization.

## Commands
- Dev server: `bin/rails server`
- Tests: `bundle exec rspec`
- Specific test: `bundle exec rspec spec/models/property_spec.rb`
- Console: `bin/rails console`
- Migrations: `bin/rails db:migrate`
- Frontend dev: `cd frontend && npm run dev`

## Rules
- Be extremely concise. Sacrifice grammar for concision.
- At the end of each plan, list unresolved questions (if any).
- Always use service objects for business logic (app/services/)
- Never put business logic in controllers — thin controllers only
- Use Pundit policies for all authorization
- Use FactoryBot for test data — never create records manually in specs
- React components go in app/javascript/components/ (TypeScript)
- Follow Rails upgrade guides when updating framework versions

## Architecture
app/
├── controllers/api/v1/  ← API endpoints (thin, delegate to services)
├── models/              ← ActiveRecord models + validations
├── services/            ← Business logic (one service per use case)
├── serializers/         ← JSON serialization
├── policies/            ← Pundit authorization policies
├── javascript/
│   ├── components/      ← React components (new code goes here)
│   └── legacy/          ← Older JS (being modernized)
spec/
├── models/              ← Model specs
├── requests/            ← API endpoint specs
├── services/            ← Service specs
└── factories/           ← FactoryBot factories
```

#### Two rules you should always include

```markdown
- Be extremely concise. Sacrifice grammar for concision.
- At the end of each plan, list unresolved questions (if any).
```

#### Hierarchy — like CSS cascade

```
project/AGENTS.md                ← Project-wide (all tools read this)
  ↓
project/app/AGENTS.md            ← Backend-specific overrides
  ↓
project/frontend/AGENTS.md       ← Frontend-specific overrides
```

#### Progressive disclosure

Keep AGENTS.md short — use it as an **index**:

```markdown
## Additional docs
- See docs/architecture.md for Rails patterns
- See docs/testing.md for RSpec conventions
- See docs/upgrade-guide.md for framework upgrade patterns
```

Stay under 150 lines. Move details to reference docs.

#### Pro tip: Let her write the first draft

Don't use `/init` — it generates too much generic content. Instead:

```
Analyze this codebase and create an AGENTS.md file following these principles:
1. Keep it under 150 lines — focus only on universally applicable information
2. Cover the essentials: WHAT (tech stack, structure), WHY (purpose), HOW (commands)
3. Use Progressive Disclosure: create a brief index pointing to docs/ files
4. Include file:line references instead of code snippets
5. Assume linters handle code style — don't include formatting guidelines

Additionally, extract patterns you observe into:
- docs/architectural_patterns.md — patterns that appear in multiple files

Reference these files in the AGENTS.md "Additional docs" section.

Finally, create a symlink: ln -s AGENTS.md CLAUDE.md
```

#### Hands-on 2: Write your AGENTS.md (20 min)

**Option A: Generate from your codebase**
1. Run `claude` in your project
2. Use the prompt above to auto-generate
3. Review — edit down to essentials
4. Test: give her a task → does she follow the rules?

**Option B: Start from the template**
1. Copy the example AGENTS.md above
2. Customize with your specific rules
3. Test: does she use RSpec, service objects, FactoryBot?

**Commit and push — now the whole team has the same AI onboarding.**

#### The workflow: Plan → Build → Simplify → Verify

```
0. ONBOARD    AGENTS.md provides context (happens automatically)
1. PLAN       Describe WHAT you want (not how) — agent asks questions, suggests a plan
2. BUILD      Agent implements the plan
3. SIMPLIFY   "It works — make it simpler"
4. VERIFY     Agent runs tests — you review
```

#### Three levels of planning

```
Level 1: Plan Mode (Shift+Tab x 2)
  → Tasks under 1 hour
  → Plan lives in conversation

Level 2: spec.md / PRD
  → Medium features (1 hour – 1 day)
  → "Write the plan to spec.md before implementing"
  → Plan survives compaction — it's in a file

Level 3: GSD framework (plan → execute → verify loop)
  → Large projects (days – weeks)
  → Breaks into phases, each with its own plan + verify
```

**Key insight:** always write the plan to a **file** or **issue**, not just the conversation. Files survive compaction. Conversations don't.

#### The feedback loop — 2-3x quality

```
Without: Agent codes → "Looks done" → You find bugs in review
With:    Agent codes → Runs rspec → Sees failure → Fixes → Runs again → ✅
```

How to create one:
- `"Run bundle exec rspec after every change"`
- Put it in AGENTS.md: `Always run bundle exec rspec before creating a PR`
- Visual feedback: `"Run Playwright tests and take a screenshot after each UI change"`

#### BDD exercise: Work Order Priority Escalation

Use this prompt on the demo project:

```
## Feature: Work Order Priority Escalation

A work order that has been open for more than 14 days without
being assigned should automatically be escalated to "high" priority.

### Expected behavior
- When a work order is created, priority defaults to "normal"
- If 14 days pass and assigned_to_id is still nil, priority
  becomes "high"
- Only work orders with status "open" are affected
- Work orders already assigned are never escalated

### Acceptance criteria
- Create app/services/work_order_escalation_service.rb
- Add a rake task that calls the service
- RSpec tests cover: old+unassigned → escalated, old+assigned → not,
  new+unassigned → not, already completed → not
- Use FactoryBot :old and :unassigned traits from spec/factories/
```

No implementation details. Just *what* should happen. She'll read schema.rb, find the existing model, and build the feature.

---

### Workshop 3: Give her a real task (15:30–15:45)

#### Hands-on 3: Pick a real Shortcut ticket (15 min)

1. Pick a ticket from your Shortcut board (bug fix or small feature)
2. `claude` in your project (with the AGENTS.md from Workshop 2)
3. Use plan mode: describe the ticket
4. Let her plan → review the plan → execute
5. Run `bundle exec rspec` — do the tests pass?

**Tips:**
- Start with something small (a bug fix or simple API change)
- Use "ask me questions" to get a better plan
- Watch: does she follow your AGENTS.md rules?

#### Common mistakes

| Mistake | Why it hurts |
|---------|-------------|
| "I trust the code without checking" | AI code has 1.7x more bugs. **Always review.** |
| "I trust the facts without checking" | She invents stats. Say: "Double check every claim." |
| "I gave it the whole repo as context" | Agent drowns. Give **relevant** context. |
| "I mix tasks in one session" | Context rot. **`/clear` between tasks.** |
| "It works, we ship it" | Without Simplify → deprecated patterns. **Always refactor.** |
| "We don't need AGENTS.md" | Without onboarding, agent guesses. Every time. |

---

### Day 1 — Five key takeaways

1. **You have a new colleague** — she executes entire tasks, not just suggests code
2. **Onboarding is everything** — AGENTS.md = the colleague's day 1 document
3. **Plan → Build → Simplify → Verify** — the workflow
4. **Feedback loops** — tests + TDD = 2-3x quality
5. **Worktrees** — the agent works in isolation, main is always safe

### Homework before Day 2

1. **Refine your AGENTS.md** — add rules for mistakes you discovered today, commit and push
2. **Work on a real Shortcut ticket with Claude Code** — use plan mode + worktree, note what worked and what didn't

---

## Day 2 — Wednesday 09:00–12:00

| Time | Block | The colleague journey |
|------|-------|----------------------|
| 09:00–09:15 | Recap + Feedback | What happened since yesterday? |
| 09:15–10:15 | Workshop 4 | Train her: skills, hooks, MCP |
| 10:15–10:25 | Break | |
| 10:25–11:15 | Workshop 5 | Build a team of AI colleagues |
| 11:15–11:50 | Workshop 6 | Real work: full workflow |
| 11:50–12:00 | Q&A + Next steps | |

---

### Recap + Feedback (09:00–09:15)

#### Model overview (March 2026)

| Model | Strength | Context | Best for |
|---|---|---|---|
| **Opus 4.6** | Most advanced | 1M (beta) | Complex tasks, Agent Teams |
| **Sonnet 4.6** (NEW) | Near-Opus performance | 200K | Daily dev, computer use |
| **Opus 4.5** | Top benchmarks | 200K | Deep coding, Thinking mode |
| **Haiku 4.5** | Fastest, cheapest | 200K | Sub-agents, quick tasks |

**70-80% of tasks are fine on cheaper tiers.** Track with `/cost`.

---

### Workshop 4: Train her — skills, hooks & integrations (09:15–10:15)

#### From onboarding to routines

```
AGENTS.md     = "What we do and why"       (always loaded)
Skills        = "Repeatable tasks"          (loaded on demand)
Hooks         = "Automatic quality checks"  (zero LLM tokens)
MCP           = "Access to your systems"    (external tools)
```

#### Skills = reusable slash commands

A skill is a **folder** with `SKILL.md` + supporting files:

```
.claude/skills/review/
├── SKILL.md              ← Entry point
├── checklist.md          ← Your team's review checklist
└── examples/
    └── good-review.md    ← What a good review looks like
```

**Two ways to trigger:**
1. You type `/review app/controllers/api/v1/properties_controller.rb`
2. She auto-activates — description matches your request

#### Example: /review skill for Rails

```yaml
---
name: review
description: Reviews Ruby on Rails + React code
allowed-tools: Read, Grep, Glob
---

Review $ARGUMENTS:

## Rails
1. N+1 queries? Missing `.includes()` or `.preload()`?
2. Business logic in controller? Should be in service object?
3. Missing Pundit authorization?
4. Raw SQL without parameterization?
5. Missing validations on model?

## React
6. Functional + hooks only?
7. API calls via dedicated service module?
8. TypeScript types defined?

## Testing
9. RSpec specs exist for all new code?
10. FactoryBot used for test data?

## Output
Summarize: good / warning / must fix
```

#### Example: /implement skill — BDD-style TDD

```yaml
---
name: implement
description: Implements a feature using BDD/TDD — one test at a time
---

Implement $ARGUMENTS using strict TDD:

## Process
1. Read the feature description / acceptance criteria
2. List all acceptance criteria as a numbered checklist
3. For EACH criterion, one at a time:
   a. Write ONE failing RSpec test
   b. Run `bundle exec rspec` — confirm it fails
   c. Write the minimum code to make it pass
   d. Run `bundle exec rspec` — confirm it passes
   e. Ask: "Criterion N done — move to next?" Wait for approval.
4. After all criteria pass: run full suite `bundle exec rspec`

## Rules
- Never write more than one test at a time
- Never skip the red-green cycle
- Use FactoryBot for test data
- Use service objects for business logic
- Show test output after each run
```

#### Practical skills to create

| Command | What it does |
|---------|-------------|
| `/implement` | BDD-style: one test → implement → next → repeat |
| `/plan-feature` | Multi-phase implementation plan |
| `/verify` | Run tests + review own code + check edge cases |
| `/simplify` | Remove over-engineering (built-in) |
| `/batch` | Migrations at scale with parallel agents (built-in) |
| `/review` | Code review with good/warning/must-fix |
| `/commit-push-pr` | Commit, push, create PR |
| `/upgrade-check` | Analyze deprecations before a framework upgrade |

#### Hooks — automatic quality control

Hooks run **without LLM tokens** — pure programmatic logic.

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "command": "bundle exec rubocop --autocorrect $FILE",
        "timeout": 30
      }]
    }],
    "Stop": [{
      "hooks": [{
        "command": "bundle exec rspec && bundle exec rubocop",
        "timeout": 180
      }]
    }]
  }
}
```

#### The decision matrix

| Question | Use |
|----------|-----|
| Should she **always** know this? | **AGENTS.md** |
| Should she know this **sometimes**? | **Skill** |
| Should it happen **automatically**? | **Hook** |
| Does she need **external systems**? | **MCP** |

#### MCP — give her access to your systems

```
Agent ←→ GitHub        (PRs, issues, reviews)
Agent ←→ Shortcut      (stories, epics, iterations)
Agent ←→ PostgreSQL    (run queries)
Agent ←→ Context7      (real-time documentation)
```

```bash
/mcp add github
/mcp add context7
```

#### Hands-on 4: Create a skill + hook + MCP (20 min)

**Task A: Create `/review` for your project**
1. Create `.claude/skills/review/SKILL.md`
2. Write review checks for your Rails codebase
3. Test: `/review app/controllers/some_controller.rb`

**Task B: Add a Stop hook**
1. Add to `.claude/settings.json` → Stop hook
2. `bundle exec rspec` runs automatically when she's done

**Task C: Connect GitHub MCP**
```bash
/mcp add github
```
Test: "Show all open PRs" / "Create a PR for this branch"

---

### Workshop 5: Build a team of AI colleagues (10:25–11:15)

#### Why multi-agent?

One colleague on a big project loses perspective. Multiple colleagues = **specialization + parallelism**. Each has her own context window → no "context rot".

#### Two patterns

**Sequential (quality):**
```
Researcher → Builder → Reviewer
```

**Parallel (speed):**
```
Terminal 1: API endpoint (Rails)
Terminal 2: React component (frontend)
Terminal 3: RSpec tests
```

#### Parallel agents in practice

```bash
Terminal 1: claude -w feature-api    "Add maintenance scheduling API"
Terminal 2: claude -w feature-ui     "Create maintenance calendar React component"
Terminal 3: claude -w feature-tests  "Write integration tests for maintenance flow"
```

All work in isolation. Each opens a PR. You review.

#### Sub-agents — specialized colleagues

```markdown
# .claude/agents/reviewer.md
---
name: reviewer
description: Reviews code for security and Rails conventions
tools: ["Read", "Grep", "Glob"]
---

Focus on:
1. Security (SQL injection, mass assignment, missing authorization)
2. Performance (N+1, missing indexes, unscoped queries)
3. Conventions (thin controllers, service objects, Pundit policies)
4. Testing (RSpec coverage, FactoryBot usage)
```

```bash
claude --agent reviewer "Review the latest changes"
```

#### Spec-driven development

```
1. SPECIFY    Write the story: what should happen? Who is it for?
2. CLARIFY    Ask the agent: "What questions do you have?"
3. PLAN       Agent proposes implementation plan
4. BUILD      Agent implements the plan (TDD: one test at a time)
5. VERIFY     Run tests + review + /simplify
6. DELIVER    Commit → push → PR against story requirements
```

> The developer role shifts from "write code" to **"specify, clarify, verify."**

#### Context engineering > Prompt engineering

```
Bad:  "Add maintenance scheduling"
Good: "Add maintenance scheduling for properties:
       - Recurring schedules (weekly, monthly, yearly)
       - Assign to contractors from the contractors table
       - Email notification 3 days before due date
       - Edge cases: holidays, contractor unavailable
       - Use existing service object pattern in app/services/"
```

#### Hands-on 5: Multi-agent workflow (15 min)

**Option A: Parallel feature**
```bash
# Terminal 1 (API):
claude -w feature-api
> "Plan: Add a work order assignment endpoint.
>  A manager can assign a work order to a technician.
>  Ask me questions first."

# Terminal 2 (Tests):
claude -w feature-tests
> "Write integration specs for the work order assignment flow"
```

**Option B: Framework upgrade task**
```bash
claude -w upgrade-fix "Find and fix all Rails deprecation warnings
in app/models/. Plan first, then fix one file at a time, run rspec after each."
```

---

### Workshop 6: Real work — full workflow (11:15–11:50)

#### The full workflow — everything together

```
1. PLAN      Pick a Shortcut story → describe it → iterate the plan
2. BUILD     TDD: one test at a time
3. SIMPLIFY  "It works — make it simpler"
4. VERIFY    Run tests + review
5. DELIVER   Commit → push → PR
```

#### TDD: one test at a time

Don't say "build the feature". Say this:

```
"Write ONE failing test for [first acceptance criterion].
 Then implement just enough to make it pass.
 Show me the result before moving on."
```

Then repeat:
```
"Good. Next test: [second criterion]. Same approach."
```

#### Hands-on 6: Full workflow (30 min)

1. **Pick a Shortcut ticket** (medium complexity)
2. **Start in a worktree:** `claude -w feature/SC-XXXX`
3. **Plan:** describe the ticket → "ask me questions" → iterate the plan
4. **Build with TDD:** one failing test at a time
5. **Simplify:** `/simplify`
6. **Verify:** `bundle exec rspec` all green
7. **Deliver:** commit → push → PR

---

### Recommended path forward

**Week 1: Foundation**
- Commit AGENTS.md — whole team uses it
- Plan mode + worktree for daily tasks
- 2-mistake rule: same error twice → new AGENTS.md rule

**Week 2: Automation**
- Create `/review` and `/implement` skills
- Add Stop hook (rspec + rubocop)
- Connect GitHub MCP

**Week 3: Scale**
- Open 2-3 terminals → parallel agents on independent Shortcut tickets
- Try `/batch` for a real task (deprecation fixes, gem upgrades)
- Connect Shortcut MCP

**Week 4+: Autonomy**
- Agent Teams for complex features
- Spec-driven: story → agent builds → you review
- Track costs, optimize model selection

### Resources

| Resource | Link |
|----------|------|
| Claude Code docs | code.claude.com |
| Skills marketplace | skillsmp.com |
| MCP servers | awesome-mcp-servers (GitHub) |
| AGENTS.md standard | agents-md.org |
| GitHub Spec Kit | github.com/github/spec-kit |
| Context7 | context7.com |
