# AGENTS.md Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a comprehensive, strict `AGENTS.md` in the root repository enforcing GitFlow, strict LoC limits for Go and Dart, and rigid TDD protocols.

**Architecture:** A centralized markdown configuration document defining operational guardrails, development lifecycles, and verification checklists for all autonomous agents and human developers.

**Tech Stack:** Markdown, Git, Go 1.26, Dart / Flutter

## Global Constraints
- Target file: `/Users/vonar/personal_src/POS/AGENTS.md`
- GitFlow: Base from `dev`, branch naming `feat/*`, `fix/*`, `chore/*`, `refactor/*`, `test/*`, `docs/*`, PR to `dev`, confirm on `dev`, PR to `main`.
- Conventional Commits: `<type>(<scope>): <description>`
- LoC Limits: Max 200 LoC per source file, max 40 LoC per function/method, max 50 LoC per Flutter `build()` method, max 400 LoC per test file.
- TDD: Red-Green-Refactor strictly required before writing production code. $\ge 80\%$ coverage target.

---

### Task 1: Create `AGENTS.md` at Repository Root

**Files:**
- Create: `AGENTS.md`

- [ ] **Step 1: Write `AGENTS.md` with complete rules and sections**
- [ ] **Step 2: Verify all constraints and thresholds match the design spec**
- [ ] **Step 3: Commit `AGENTS.md` following Conventional Commits**

---

### Task 2: Verify `AGENTS.md` & Repository State

**Files:**
- Verify: `AGENTS.md`

- [ ] **Step 1: Inspect `AGENTS.md` formatting and clarity**
- [ ] **Step 2: Confirm git status and branches**
