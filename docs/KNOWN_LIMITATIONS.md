# Known limitations

There are currently no outstanding known limitations tracked here.

Previously: child approvers could not award stars because star movement
required writing another member's `users.points` document, which the rules
restricted to parents/guardians. This was resolved in build 41 by moving all
star movement (award, claim, settle, refund) to Cloud Functions under admin
credentials and locking `users.points` from every client. Peer approval now
works for any family member except the doer, and the self-mint hole is closed.

See `PROJECT_STATUS.md` for active work and `docs/KNOWN_LIMITATIONS.md` history
is preserved in git if needed.
