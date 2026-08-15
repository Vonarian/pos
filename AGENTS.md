# AGENTS.md — Engineering Standards & Operating Guidelines

> **Repository:** Personal Operating System (POS)  
> **Target Platforms:** Android / Desktop Flutter Frontend (`/frontend`), Go Sync Daemon (`/backend`)  
> **Audience:** All AI agents and software engineers contributing to this repository.

---

## 1. Core Operating Principles & Non-Negotiables

Every agent operating within this codebase must strictly observe three core pillars:
1. **Always Follow GitFlow:** Branch from `dev`, commit via Conventional Commits, merge to `dev`, verify on `dev`, then release to `main`.
2. **Strict Lines of Code (LoC) Limits:** Zero tolerance for monolithic files or sprawling functions. Keep code compact, single-responsibility, and modular.
3. **Rigid Test-Driven Development (TDD):** Red $\rightarrow$ Green $\rightarrow$ Refactor. Write failing tests **before** implementation code. Maintain $\ge 80\%$ test coverage on business logic.

---

## 2. GitFlow & Branch Lifecycle

### 2.1 Branch Taxonomy
- **`main`**: Production release branch. Highly protected. Only merges from `dev` are permitted.
- **`dev`**: Integration branch for active development. All work stems from and returns to `dev`.
- **Working Branches**: Always branched directly from `dev`. Use strict naming:
  - `feat/<feature-name>`: New capabilities (e.g., `feat/routine-state-machine`)
  - `fix/<bug-name>`: Bug repairs (e.g., `fix/health-connect-token-refresh`)
  - `chore/<task-name>`: Tooling, dependency updates, CI/CD (e.g., `chore/bump-drift-sqlite`)
  - `refactor/<target>`: Structural changes without behavioral change (e.g., `refactor/extract-metric-dao`)
  - `test/<test-suite>`: Test additions or test framework adjustments (e.g., `test/routine-dao-cases`)
  - `docs/<doc-name>`: Documentation updates (e.g., `docs/update-architecture-spec`)

### 2.2 Conventional Commits
All commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
```text
<type>(<optional-scope>): <imperative description>
```
- **Allowed Types**: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `perf`, `ci`, `style`
- **Examples**:
  - `feat(routine): implement morning protocol state progression`
  - `fix(sync): resolve drift batch insert deadlock`
  - `test(metric): add table-driven unit tests for summary aggregator`

### 2.3 End-to-End Release Cycle
1. **Sync `dev`**: Ensure local `dev` is up-to-date (`git checkout dev && git pull origin dev`).
2. **Branch Off**: Cut a new branch (`git checkout -b feat/<name> dev`).
3. **Implement via TDD**: Write tests first, implement minimal code, refactor within LoC limits.
4. **Local Verification**: Run all backend and frontend test suites and lints.
5. **PR / Merge to `dev`**: Open a Pull Request targeting `dev` (or merge if self-contained).
6. **Confirm on `dev`**: Switch to `dev`, pull changes, and run the full test suite to guarantee zero regression:
   - Backend: `cd backend && go test -v -race ./...`
   - Frontend: `cd frontend && flutter test`
7. **Release PR to `main`**: Once stability is verified on `dev`, create a release PR from `dev` to `main`.

---

## 3. Strict Lines of Code (LoC) & Modularity Budgets

To ensure high maintainability, readability, and agent context fit, all source files must adhere to strict size ceilings:

| Target Scope | Maximum LoC | Enforcement Action |
| :--- | :--- | :--- |
| **Go Source File (`.go` non-test)** | **200 lines** | Split struct methods, extract helper packages or sub-services. |
| **Dart Source File (`.dart` non-test)** | **200 lines** | Extract sub-widgets, DAOs, or domain entities. |
| **Function / Method (Go or Dart)** | **40 lines** | Decompose logic into smaller helper functions with single responsibilities. |
| **Flutter Widget `build()` Method** | **50 lines** | Extract widget sub-trees into dedicated `StatelessWidget` classes in `presentation/widgets/`. |
| **Test File (`_test.go` / `_test.dart`)** | **400 lines** | Split test suite into multiple behavioral test files (e.g., `user_handler_auth_test.go`). |

### 3.1 Decomposition Strategies
- **Go Backend**:
  - Separate HTTP route registration from handler business logic.
  - Split large database query mappers into focused DAO files.
  - Place domain interfaces in `domain/` and implementations in `service/` or `repository/`.
- **Flutter Frontend**:
  - Never inline large UI sub-trees inside screen widgets; create granular reusable widgets.
  - Keep business logic in Providers / BLoCs / Repositories; UI widgets should only observe and render.
  - Avoid monster models; use focused immutable data classes.

---

## 4. Test-Driven Development (TDD) Protocol

All new features, endpoints, repositories, and bug fixes must be built using the **Red-Green-Refactor** workflow:

```
┌────────────────────────────────┐
│ 1. RED: Write Failing Test     │ (Prove requirement & failure before code)
└──────────────┬─────────────────┘
               │
               ▼
┌────────────────────────────────┐
│ 2. GREEN: Minimal Code         │ (Write simplest code to pass test)
└──────────────┬─────────────────┘
               │
               ▼
┌────────────────────────────────┐
│ 3. REFACTOR: Clean & Modular   │ (Enforce LoC limits, optimize, keep green)
└────────────────────────────────┘
```

### 4.1 Strict TDD Rules
- **Never write production code before a failing test exists.**
- Every test must fail for the expected reason before implementing the solution.
- Run tests continuously during development.

### 4.2 Backend (Go) Testing Standards
- **Tooling**: Standard `testing` package + `github.com/stretchr/testify` (`assert`, `require`, `mock`).
- **Pattern**: Table-Driven Tests (`tests := []struct{ name string; ... }{...}`).
- **Execution Command**:
  ```bash
  cd backend && go test -v -race -cover ./...
  ```
- **Coverage Target**: Minimum **80% line coverage** on domain models, state machines, and services.

### 4.3 Frontend (Dart/Flutter) Testing Standards
- **Tooling**: `flutter_test`, `mocktail` for mocks and spies.
- **Pattern**: Grouped behavior-driven unit, repository, and widget tests (`group('RoutineRepository', () { ... })`).
- **Execution Command**:
  ```bash
  cd frontend && flutter test --coverage
  ```
- **Coverage Target**: Minimum **80% line coverage** on repositories, DAOs, and state providers.

---

## 5. Code Quality & Architectural Directives

### 5.1 Go (Backend Sync Daemon)
- **Error Handling**: Handle all errors explicitly. Never ignore returned errors with `_ = err`.
- **Context Propagation**: Always pass `ctx context.Context` as the first argument in database, network, and service calls.
- **Interface Segregation**: Define interfaces where they are consumed, keeping them minimal.
- **Concurrency Safety**: Run all tests with `-race` enabled to catch race conditions.

### 5.2 Dart / Flutter (Cross-Platform Frontend)
- **Sound Null-Safety**: Do not use force unwrap (`!`) without prior assertion or null check.
- **Immutability**: Use immutable entities and models.
- **Separation of Concerns**: UI widgets must not make direct network or raw database calls. Always use repository and provider abstractions.
- **Widget Composition**: Build deep trees through composition of small, focused `StatelessWidget` elements rather than huge monoliths.

---

## 6. Definition of Done (DoD) Checklist

Before submitting a PR or closing a task, verify every item:

- [ ] **GitFlow**: Work was performed on a `feat/*` or `fix/*` branch cut from `dev`.
- [ ] **TDD Verified**: Failing test was written first, followed by passing code and refactoring.
- [ ] **Go Tests**: `cd backend && go test -race -cover ./...` passes without errors or race conditions.
- [ ] **Flutter Tests**: `cd frontend && flutter test` passes with all tests green.
- [ ] **LoC Limits Enforced**:
  - [ ] Every non-test source file $\le 200$ lines.
  - [ ] Every function/method $\le 40$ lines.
  - [ ] Every Flutter `build()` method $\le 50$ lines.
  - [ ] Every test file $\le 400$ lines.
- [ ] **Commit Format**: All commit messages follow Conventional Commits format.
- [ ] **Integration Confirmed on `dev`**: Branch merged/rebased to `dev`, and verified on `dev` prior to `main` release PR.
