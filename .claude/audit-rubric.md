:

# Engineering Audit Rubric

8-dimension conformance scorecard for this repo. Used in `docs/engineering-audit-YYYY-MM-DD.md`.

---

## Dimensions

### 1. Domain language (0–5)

- **5** — Glossary is maintained; every domain concept has a single code name;
  no synonyms or translations; naming isomorphic to business language.
- **3** — Most concepts map, but a few leaks or synonyms exist.
- **1** — Significant drift; the same business idea has multiple code names
  or is conflated with unrelated concepts.
- **0** — No glossary; naming is arbitrary or framework-driven.

### 2. Bounded contexts (0–5)

- **5** — Contexts are explicit, separated by repository/use-case boundaries;
  cross-context access only through declared interfaces.
- **3** — Boundaries mostly respected, with a few direct imports or collection
  references across contexts.
- **1** — Multiple contexts tangled; Firestore paths or use cases reach across
  domains freely.
- **0** — No concept of contexts; everything is one flat model.

### 3. Aggregates / invariants (0–5)

- **5** — Aggregate roots enforce invariants; server-side or domain-layer rules
  protect consistency; no partial updates that break invariants.
- **3** — Core invariants are enforced, but edge cases are client-guarded or
  duplicated.
- **1** — Invariants scattered or weak; data can enter inconsistent states.
- **0** — No invariant enforcement; any client can write anything.

### 4. Test coverage (0–5)

- **5** — >80% line coverage; domain layer fully covered; every repository
  implementation has Firebase + Mock tests.
- **3** — ~50–80% coverage; core paths covered, some UI/edge cases missing.
- **1** — <50% coverage; critical paths untested.
- **0** — Almost no tests.

### 5. Testability (0–5)

- **5** — Dependencies are injected; pure domain logic is trivial to test;
  infrastructure is behind interfaces; no global state or hidden I/O.
- **3** — Most code is testable, but some classes require heavy mocking or
  setup.
- **1** — Many classes are hard to test; tests require real backends or
  complex fixtures.
- **0** — Untestable by design.

### 6. Module depth (0–5)

- **5** — Common operations hide substantial complexity behind simple
  interfaces; pass-through methods and config leaks are absent.
- **3** — Good depth overall, with a few shallow modules or leaked decisions.
- **1** — Many shallow abstractions; callers repeatedly configure internal
  behavior; change amplification is common.
- **0** — Every module is a thin wrapper or a grab-bag utility class.

### 7. Change amplification (0–5)

- **5** — One conceptual change touches one or two files; new features plug
  into existing interfaces without cascading edits.
- **3** — Some changes ripple, but the blast radius is usually small.
- **1** — Adding a feature requires edits across many layers/files.
- **0** — Even trivial changes require widespread edits.

### 8. Error design (0–5)

- **5** — Errors are defined out of existence where possible; documented
  exceptions are part of the contract; failures are loud, not silently swallowed.
- **3** — Most errors handled explicitly, but a few silent catches or vague
  fallbacks remain.
- **1** — Silent failures or generic errors make debugging hard.
- **0** — Errors are ignored, swallowed, or pushed to the user as raw stack traces.

---

## Scoring guidance

- Each dimension gets an integer score 0–5.
- For every score <5, list **file:line evidence** (good or bad).
- Compute average for headline number.
- Rank fixes by `(5 − score) × change_frequency`, using `git log --stat` or
  `git log --follow -- <file>` to find hot files.
- Propose only incremental, strangler-style fixes — no rewrite proposals.
