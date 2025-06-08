# Branch Management Guide

_A consistent Git workflow keeps **Hoque Family Chores** healthy, predictable, and easy for every contributor._

---

## 1. Branch Strategy

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Single source of truth for production-ready code | 🔒 Required PR reviews, CI must pass |
| `feature/*`, `fix/*`, `hotfix/*`, `maintenance/*` | Short-lived branches for new work | No direct pushes |
| `release/*` (rare) | Optional stabilization before a store release | Locked once cut |

```text
main ──┬─► feature/task-X ── PR ──┐
       ├─► fix/bug-Y     ── PR ──┤──► merge ─► main
       └─► maintenance/tools     ── PR ────┘
```

### Key Rules

1. **Never commit to `main` directly** – always create a branch + PR.  
2. Keep branches **focused & small**; aim to merge within a few days.  
3. Rebase (or pull with `--rebase`) to keep history linear.  
4. Delete the branch after the PR merges (GitHub UI or `git push origin --delete branch`).

---

## 2. Naming Conventions

| Prefix | When to use | Example |
|--------|-------------|---------|
| `feature/` | New user-facing work | `feature/task-list-screen` |
| `fix/` | Bug fix discovered in development | `fix/xcode-cloud-paths` |
| `hotfix/` | Urgent prod issue patched off `main` | `hotfix/crash-on-launch` |
| `maintenance/` | Tooling, docs, build scripts | `maintenance/add-branch-cleanup` |
| `release/` | Pre-release hardening (optional) | `release/v1.2.0` |

Tips  
• use `kebab-case` words separated by `-`.  
• prepend issue number if it helps: `42-fix-login-null-error`.

---

## 3. Typical Workflow

1. **Sync main**

   ```bash
   git checkout main
   git pull
   ```

2. **Create branch**

   ```bash
   git checkout -b feature/task-list-screen
   ```

3. **Develop & commit**

   ```bash
   git add .
   git commit -m "feat: create task list screen"
   ```

4. **Push**

   ```bash
   git push -u origin feature/task-list-screen
   ```

5. **Open Pull Request** (GitHub prompts URL).  
   • Fill in description, link issues, choose reviewers.  
   • _Draft_ PRs welcome for early feedback.

6. **CI must pass** (Flutter tests, Xcode/Android builds).  
   • Fix failures before requesting review.

7. **Review & merge**  
   • Require at least **one approval**.  
   • Use **“Squash & merge”** to keep `main` history clean.

8. **Delete branch** (GitHub UI or CLI).

---

## 4. Pull Request Checklist

- [ ] Title follows Conventional Commits (`feat:`, `fix:`, `docs:` …).
- [ ] Description clearly states **what** and **why**.
- [ ] Linked issue(s) closed by `Fixes #123`.
- [ ] Added/updated tests if needed.
- [ ] Ran `flutter analyze` with no new warnings.
- [ ] Local build succeeds on iOS & Android.
- [ ] No TODOs or debug prints left.
- [ ] Updated docs/README if behaviour changed.

---

## 5. Cleaning Up Stale Branches

Old branches clutter the repo and slow down cloning.

### When to clean

| Scenario | Action |
|----------|--------|
| PR merged | Delete local **and** remote branch immediately. |
| Branch > 2 weeks stale & no activity | Ask the author, then delete. |
| Experimental WIP, not needed | Tag it (optional) then delete. |

### Automated Script

We ship `scripts/cleanup_branches.sh` to simplify housekeeping.

```bash
# Dry-run: see what would be removed
./scripts/cleanup_branches.sh --dry-run -l -r -v

# Interactive delete merged local & remote branches (skips protected)
./scripts/cleanup_branches.sh -l -r
```

Options:

```
-l  local           Clean local branches
-r  remote          Clean remote branches
-a  all             Include unmerged branches (use with care)
-f  force           Force-delete unmerged branches
-y  yes             Skip confirmations
--include-protected Allow deletion of main/develop etc. (rare)
```

The script always performs `git fetch --prune` first, so deleted remote refs vanish locally too.

---

## 6. FAQ

**Q: I rebased and my PR shows dozens of unrelated commits.**  
A: `git pull --rebase origin main`, then `git push --force-with-lease`.

**Q: Someone force-pushed over my branch. How to avoid?**  
A: Use `--force-with-lease`, not `--force`, so you don’t overwrite others’ work.

**Q: How do I recover a deleted branch?**  
A: `git reflog` locally or GitHub “Restore branch” button if within 90 days.

**Q: Can I commit generated files (e.g., `pubspec.lock`)?**  
A: Yes for apps – keep it version-controlled to ensure deterministic builds.

---

Happy branching! 🚀
