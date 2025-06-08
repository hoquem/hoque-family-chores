# Fixing Xcode Cloud Build Failures – `ios/ci_scripts/ci_post_clone.sh`

## 1. Original Problem

| Symptom | Details |
|---------|---------|
| **Empty `PROJECT_ROOT`** | `$CI_WORKSPACE` was **empty** in Xcode Cloud, so the script executed `cd ''`, leaving it inside `ios/ci_scripts`. |
| **Wrong `.env` path** | Because `PROJECT_ROOT` was unset the script defaulted to `/.env` (root directory), which is read-only. A second attempt used `/ios/Runner/.env`, another invalid absolute path. |
| **Result** | `.env` could not be written → script exited `1` → entire Xcode Cloud workflow failed before pods / flutter commands ran. |

## 2. Strategy for the Fix

1. **Robust Project-Root Detection**  
   A new block determines `PROJECT_ROOT` using a *cascade* of checks:  
   1. `$CI_WORKSPACE` if set and valid.  
   2. Presence of `pubspec.yaml` in `.` / `..` / `../..`.  
   3. Path heuristics for `ios/ci_scripts` or `ios` folders.  
   4. Hard-coded fall-backs for `/Volumes/workspace/repository`.  
   5. Final fall-back: relative to the script’s own directory.

2. **Multiple Writable Locations for `.env`**  
   An ordered list of candidate paths is tried:  

   1. `<PROJECT_ROOT>/.env`  
   2. `<PROJECT_ROOT>/ios/.env`  
   3. `<PROJECT_ROOT>/ios/Runner/.env`  
   4. `<PROJECT_ROOT>/ios/Flutter/.env`  
   5. `./.env` (current dir)

   The first directory that exists **and** is writable is chosen.  
   If no candidate is writable the script creates `flutter_env/.env` inside the current directory.

3. **Safety & DX Enhancements**  
   * Debug echo statements show path logic and permissions.  
   * `set -e -x` terminates early and prints commands for easier log inspection.  
   * After writing, non-secret variables are echoed (secrets filtered).  
   * Symbolic links to the final `.env` are created at common locations for redundancy.  

## 3. .ENV Creation Flow (Pseudo)

```text
determine_project_root()
 ├─ check $CI_WORKSPACE
 ├─ look for pubspec.yaml (cwd, .., ../..)
 ├─ ios/ci_scripts → ../..
 ├─ ios           → ..
 ├─ /Volumes/workspace/repository
 └─ fallback via script dir

for location in [root/.env, ios/.env, ios/Runner/.env, ios/Flutter/.env, ./env]
 └─ if dirname(location) is writable → ENV_FILE_PATH=location; break

if ENV_FILE_PATH empty
 └─ mkdir flutter_env && use flutter_env/.env

write_env_file(ENV_FILE_PATH)
link_env_file(ProjectRoot/.env, ios/Runner/.env)
```

## 4. Testing the Script

1. **Local dry-run**  
   ```bash
   cd ios/ci_scripts
   ./ci_post_clone.sh
   ```
   (Export fake environment variables first.)

2. **Simulate unwritable root**  
   ```bash
   readonly_root() { sudo mount -o ro /; } # macOS – be careful
   ```

3. **Validate outputs**  
   * Logs should show a *writable* `.env` path.  
   * `ls -la` should list the file with expected size.  
   * `grep -v KEY .env` must print non-secret lines.

4. **CI run**  
   Push to a feature branch – Xcode Cloud clone step should now complete and advance to pod install / flutter build without `.env` errors.

## 5. Troubleshooting Checklist

| Issue | Checks / Fixes |
|-------|----------------|
| **`PROJECT_ROOT` wrong** | Confirm log shows expected path; ensure repo contains `pubspec.yaml` in root. |
| **“No writable location” fatal** | Xcode Cloud may mount workspace read-only – confirm by inspecting `ls -ld` perms printed in log; add another path under `ENV_FILE_LOCATIONS` that suits your workflow. |
| **Symlink warnings** | Safe to ignore unless your app explicitly loads one of the missing symlinks. |
| **Missing secrets** | Verify required env vars are set in **Xcode Cloud → Workflow → Environment Variables (Secret)**. |
| **GoogleService-Info.plist not found** | Commit the file to `ios/Runner/` or add a *pre-xcodebuild* script to fetch it. |

---

**Status:** `ci_post_clone.sh v 2.0.2` is now deployed in `fix/xcode-cloud-paths` branch and addresses all observed path & permission failures.
