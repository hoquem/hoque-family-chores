# Known limitations

There are currently no outstanding known limitations tracked here.

Previously: child approvers could not award stars because star movement
required writing another member's `users.points` document, which the rules
restricted to parents/guardians. This was resolved in build 41 by moving all
star movement (award, claim, settle, refund) to Cloud Functions under admin
credentials and locking `users.points` from every client. Peer approval now
works for any family member except the doer.

That closed the *direct* self-mint hole, but not every route to it — a member's
own `role` field was not protected the way the star economy assumes. The rules
now pin `role` once you are in a family (`test/rules/role_lock.test.mjs`), but
**the fix is not deployed until the rules ship with a client build**, so it is
still live for existing users. Tracked as **TASK-494** (private board); see
"Open security items" in `PROJECT_STATUS.md`. This repository is public, so the
reproduction path is deliberately not written down here.

See `PROJECT_STATUS.md` for active work and `docs/KNOWN_LIMITATIONS.md` history
is preserved in git if needed.
