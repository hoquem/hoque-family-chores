# Agent Briefing — [Task Name]

## Task

[One paragraph: desired behavior in domain language. Avoid implementation
prescription; focus on the user outcome and the invariant that must hold.]

---

## Glossary (excerpt)

| Term | Means | Is NOT |
|------|-------|--------|
| [term] | [precise definition] | [common confusion] |

---

## Bounded context

- **This task lives in:** [auth / family / task / reward / notification / analytics]
- **May touch:** [specific layers/files]
- **Must NOT reach into:** [other bounded contexts; direct Firestore access from presentation, etc.]

---

## Interface (agreed — do not change without asking)

### New or changed public API

```dart
// Example shape. Replace with the real interface for this task.
Future<Result<Task, Failure>> approveTask({
  required TaskId taskId,
  required UserId approverId,
});
```

### Errors that may escape

- `[ExceptionName]` — when [condition]

---

## Tests to satisfy

- [behavior sentence 1]
- [behavior sentence 2]
- [behavior sentence 3]

Tests are written first. No production code exists until a failing test demands
it.

---

## Invariants

- [Rule that must hold at all times, and where it is enforced.]
- [Another invariant.]

---

## Hard rules

1. **Test-first.** No production code without a failing test.
2. **Never weaken/delete/skip a test** to make the suite pass.
3. **Names from the glossary only.** If a new concept is needed, propose a
glossary entry first.
4. **Interface adherence.** Do not redesign the agreed interface without
approval.
5. **Small green commits.** Each commit is a single verified behavior;
`flutter analyze` and `flutter test` pass at every commit.
6. **Done =** green tests + `flutter analyze` clean + end-to-end verified +
deep-module checklist.

---

## Out of scope

- [Explicit exclusion 1]
- [Explicit exclusion 2]

---

## Notes / links

- Related issue: #[number]
- Related spec/plan: [path]
- MC ticket: [TASK-xxx if applicable]
