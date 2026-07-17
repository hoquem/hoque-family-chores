# Known limitations

Things that work partially or depend on infrastructure not yet in place. Each
links to the issue tracking its fix.

## Child approvers can't award stars yet — parent approval only

**Tracked in [#137](https://github.com/hoquem/hoque-family-chores/issues/137).**

The app lets anyone in the family sign off a chore except the person who did it
(peer approval). This works fully **when the approver is a parent or guardian**.
When the approver is a **child**, the approval is denied by the Firestore
security rules and no stars are awarded.

Why: approving a chore awards stars to the *assignee's* user document, written
under the *approver's* sign-in. The rule that allows writing another member's
points still requires the writer to be a parent or guardian:

```
allow update: if isSignedIn()
  && (request.auth.uid == userId
      || (resource.data.familyId == me().familyId
          && me().role in ['parent', 'guardian']));
```

The peer-approval feature democratized the UI and the domain layer but not this
rule. The proper fix (issue #137) moves all star movement to Cloud Functions
with admin credentials and locks `users.points` so no client writes it directly
— which also closes a second hole: today the rules let a member freely rewrite
their *own* points.

**Pilot workaround:** have a parent do the final approval. Everything else in
the rewards loop (earning, claiming, settling, refunds) works for everyone.
