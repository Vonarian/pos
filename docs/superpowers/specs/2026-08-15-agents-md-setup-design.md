# AGENTS.md Configuration & Operating Framework Design

**Date:** 2026-08-15  
**Topic:** AGENTS.md Repository Setup  
**Status:** Approved  

---

## 1. Overview & Objectives

This design defines the operational standard, strict code constraints, and quality gates codified in `AGENTS.md` for all AI agents and contributors working in the **Personal Operating System (POS)** repository.

### Key Goals
1. **Enforce Strict GitFlow**: Guarantee consistent branching (`dev` base), Conventional Commits, and two-tier PR verification (`feature` $\rightarrow$ `dev` $\rightarrow$ `main`).
2. **Explicit Line of Code (LoC) Budgets**: Enforce strict size and complexity limits across Go backend and Dart/Flutter frontend to prevent monolithic bloat.
3. **Rigid Test-Driven Development (TDD)**: Mandate Red-Green-Refactor cycle with failing tests proven before writing implementation code, aiming for $\ge 80\%$ test coverage on core business logic.

---

## 2. GitFlow & Release Management Specification

### Branch Taxonomy
- `main`: Production-ready release branch. Locked; direct pushes forbidden.
- `dev`: Active integration branch. All feature and fix branches are cut from and merged back into `dev`.
- Working branches:
  - `feat/<short-name>`: New capabilities or enhancements.
  - `fix/<short-name>`: Defect repairs.
  - `chore/<short-name>`: Build tooling, CI, dependencies.
  - `refactor/<short-name>`: Code restructuring without functional changes.
  - `test/<short-name>`: Test suite additions and test infrastructure.
  - `docs/<short-name>`: Documentation modifications.

### Commit Standards (Conventional Commits)
- Format: `<type>(<optional-scope>): <imperative description>`
- Types: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `perf`, `ci`, `style`
- Example: `feat(routine): implement morning protocol state progression`

### PR & Verification Lifecycle
1. Cut `feat/*` or `fix/*` from up-to-date `dev`.
2. Implement using TDD; pass all local tests and lints.
3. Open PR / merge into `dev`.
4. Run integration validation on `dev` across both `backend` and `frontend`.
5. Open PR / merge from `dev` into `main` for release tagging.

---

## 3. Strict Lines of Code (LoC) & Modularity Budgets

To keep code comprehensible, modular, and maintainable by both human engineers and AI agents, the following hard limits apply:

| Scope | Maximum LoC | Action on Violation |
| :--- | :--- | :--- |
| **Go / Dart Source File** | **200 lines** | Extract sub-components, helper packages, or DAOs. |
| **Function / Method** | **40 lines** | Decompose into smaller, single-responsibility functions. |
| **Flutter Widget `build()`** | **50 lines** | Extract sub-trees into dedicated `StatelessWidget` / helper widgets. |
| **Test File** | **400 lines** | Split test suite across multiple behavior-focused files (e.g., `_test.go` or `_test.dart`). |

### Decomposition Rules
- If a Go struct or file exceeds 200 LoC, split responsibilities (e.g., separate handler endpoints, query builders, or domain mappers).
- If a Flutter screen exceeds 200 LoC, extract child widgets into `presentation/widgets/` as isolated widgets.

---

## 4. Test-Driven Development (TDD) Protocol

All modifications and new features must strictly follow the **Red-Green-Refactor** lifecycle:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  1. RED      │ ──> │  2. GREEN    │ ──> │  3. REFACTOR │
│ Failing Test │     │ Minimal Code │     │ Clean & LoC  │
└──────────────┘     └──────────────┘     └──────────────┘
```

### Protocol Steps
1. **RED**: Write a unit/widget test for the expected requirement. Run the test suite and verify the test fails as expected. **Never write implementation code before a failing test exists.**
2. **GREEN**: Write the minimal code necessary to make the test pass. Verify test execution succeeds.
3. **REFACTOR**: Clean up, adhere to LoC limits, and ensure all existing tests remain green.

### Language-Specific Testing Standards
- **Backend (Go)**:
  - Frameworks: Standard `testing` package, `github.com/stretchr/testify` (`assert`, `require`, `mock`).
  - Style: Table-driven tests (`tests := []struct{...}`).
  - Execution: `go test -v -race -cover ./...`
  - Coverage: $\ge 80\%$ line coverage on services, repositories, and domain state machines.
- **Frontend (Dart/Flutter)**:
  - Frameworks: `flutter_test`, `mocktail` for mocks.
  - Style: Grouped behavioral unit tests (`group('RoutineRepository', ...)`), provider/state tests, and isolated widget tests.
  - Execution: `flutter test --coverage`
  - Coverage: $\ge 80\%$ on repositories, providers/cubits/controllers, and data mapping.

---

## 5. Language Quality & Architecture Guidelines

### Go (Backend)
- Explicit error handling: Always handle errors at the call site; never ignore `_ = err`.
- Context propagation: Always accept and propagate `ctx context.Context` across service and DB layers.
- Interface Segregation: Define interfaces at consumer boundaries.

### Dart / Flutter (Frontend)
- Sound Null Safety: Avoid force unwraps (`!`) unless proven non-null by preceding assertions.
- Separation of Concerns: Keep business logic out of UI widgets; use ViewModels / Providers / Repositories.
- Composition: Favor small, reusable `StatelessWidget` compositions.

---

## 6. Definition of Done (DoD)

Before declaring any task or PR complete:
1. [ ] Changes developed on `feat/*` or `fix/*` branch branched from `dev`.
2. [ ] Failing test written and passed (TDD adherence).
3. [ ] All Go tests pass with `-race`: `cd backend && go test -race ./...`.
4. [ ] All Flutter tests pass: `cd frontend && flutter test`.
5. [ ] LoC limits respected (all files $\le 200$, funcs $\le 40$, `build()` $\le 50$, tests $\le 400$).
6. [ ] Conventional Commit messages formatted accurately.
