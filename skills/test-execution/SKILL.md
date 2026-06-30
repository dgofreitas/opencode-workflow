---
name: test-execution
description: Strategy and best practices for agents to run tests and check coverage without failing or timing out. Covers Vitest, Jest, Node Native, Mocha, and npm test. Trigger when running tests, checking coverage, or dealing with truncated test output.
version: 3.0.0
author: opencode
type: skill
category: development
tags:
  - testing
  - coverage
  - vitest
  - jest
  - mocha
  - execution
---

# Test Execution & Coverage Strategy

> **Purpose**: Run tests and check coverage without timing out or looping.

---

## 🛑 What NOT to Do (Anti-Patterns)

1. **NEVER read raw `.log` files** (e.g., any `tee/*.log`). These files are huge and will cause you to time out or exceed token limits.
2. **NEVER blindly read `coverage-summary.json`**. It might not exist or might not be generated depending on the test configuration. Always verify file existence first.
3. **NEVER run the entire test suite** if you only need to check one failing test or if the suite produces too much output.
4. **NEVER run tests without verifying your directory**. In monorepos (e.g., frontend/backend), running `npm run test` in the root will fail if tests are inside sub-folders.
5. **NEVER use short forms** (`npm test`, `npm start`, `npm build`) — use `npm run <script>`.
6. **NEVER pipe `| tail`, `| head`, or `2>&1 | tail`** to any test command. It adds no value and breaks output parsing.
7. **NEVER retry when output shows `Output truncated`** — truncation is deterministic. Switch to the Coverage File Method (see below).
8. **NEVER retry a failing command more than twice with the same error** — 2-Strike Rule. Mark the item `BLOCKED` and move on.

---

## Coverage File Method — Get Coverage When Output Is Truncated

When the coverage output is truncated (the coverage table at the end is cut off),
use a file-based approach that sidesteps stdout truncation:

1. **Run tests with json-summary reporter** (writes coverage to a FILE, not stdout):
   ```bash
   npx vitest run --coverage --coverage.reporter=json-summary <test-files>
   ```
   The stdout may still be truncated, but `coverage/coverage-summary.json` is
   **written to disk regardless** — file writes are not affected by truncation.

2. **Read the total coverage** with the `read` tool:
   - Read `coverage/coverage-summary.json` line 1 — it contains the `"total"` object with overall `lines`, `functions`, `branches`, `statements` percentages.

3. **For per-file coverage**, use the `grep` tool to search the source file path in `coverage/coverage-summary.json`:
   - Example: `grep("CSVUploader", include_pattern="coverage/coverage-summary.json")`
   - This returns the coverage line for that specific source file.

4. **NEVER pipe `| tail`, `| head`, or `2>&1 | tail`** to any test command.

5. If `coverage/coverage-summary.json` is missing or unreadable after 1 attempt → mark `[BLOCKED]` and move on.

---

## ✅ Proper Strategy for Test Execution

### 1. Verify Working Directory First
Before running any test command, ensure you are in the correct directory containing the target `package.json` and test configuration.
- **Good**: `cd backend && npm run test`
- **Good**: `cd frontend && npx vitest run src/App.test.tsx`
- **Bad**: Trying to run `npm run test` from the root directory without checking if `package.json` exists there.

### 2. Running Tests Safely (Any Framework)
Always use standard test execution commands WITHOUT pipes. If using `npm run test`, you can pass arguments to the underlying runner using `--`.
- **Good**: `npm run test`
- **Good**: `npm run test -- src/my-file.test.ts`
- **Good**: `npx vitest run src/my-file.test.ts`
- **Good**: `npx jest src/my-file.test.ts`

### 3. Checking Coverage (The Smart Way)
Instead of looking for JSON or HTML files that might not exist or are too large, force the test runner to output a short text summary directly to the console.

**How to get Text-Summary Coverage by Framework:**

*   **Generic `npm run test` (passes args down):**
    ```bash
    npm run test -- --coverage
    ```

*   **Vitest:**
    ```bash
    npx vitest run --coverage.enabled=true --coverage.reporter=text-summary
    ```

*   **Jest:**
    ```bash
    npx jest --coverage --coverageReporters="text-summary"
    ```

*   **Node.js Native Test Runner (`node --test`):**
    ```bash
    node --experimental-test-coverage --test
    ```

*   **Mocha (requires c8 or nyc):**
    ```bash
    npx c8 --reporter=text-summary mocha
    # or
    npx nyc --reporter=text-summary mocha
    ```

*This will print a concise table in the console with % coverage, without needing to read external files.*

**If you MUST read coverage files:**
1. First verify the directory exists using the `glob` or `read` tool on the directory. Do not blindly read paths like `coverage/coverage-summary.json`.
2. Check `package.json` or `vitest.config.ts`/`jest.config.js` to see where coverage is actually output.

**If text-summary output is truncated, switch immediately to the Coverage File Method:**
```bash
npx vitest run --coverage --coverage.reporter=json-summary <test-files>
```
Then read `coverage/coverage-summary.json` with the `read` tool.

### 4. Handling Test Failures & Large Outputs
If a test suite fails with a massive output that gets truncated:
1. **Do NOT** try to read the full truncated log file.
2. Identify the specific file that failed from the summary output.
3. Run ONLY that file to get a focused error trace:
   ```bash
   npm run test -- path/to/failing-file.test.ts
   # or
   npx vitest run path/to/failing-file.test.ts
   ```
4. If still too large, stop on the first failure (Bail):
   - **Vitest/Jest:** `npm run test -- path/to/failing.test.ts --bail 1`
   - **Mocha:** `npx mocha path/to/failing.test.ts --bail`

### 5. Linting and Static Analysis (ESLint & TSC)
Running `eslint` or `tsc` on a dirty codebase can produce massive outputs that crash the terminal proxy or consume all tokens.

*   **TypeScript (tsc):**
    Never pipe `tsc` to `grep`. If `npx tsc --noEmit` fails with too many errors, fix the most critical errors first or focus on the files you modified.
*   **ESLint:**
    If `npx eslint .` produces too much output:
    1. **Target Specific Files:** Run ESLint only on the files you are currently working on.
       ```bash
       npx eslint path/to/your-file.ts
       ```
    2. **Quiet Mode:** Only show errors, ignore warnings to reduce output size.
       ```bash
       npx eslint . --quiet
       ```
    3. **Auto-fix:** Attempt to automatically fix issues before reading the output.
       ```bash
       npx eslint . --fix
       ```

---

## The 2-Strike Rule

ANY test/coverage command that fails **twice in a row with the same error** →
STOP. Do NOT retry a 3rd time.

1. **Log the failure** under "Blocked Items".
2. **Mark the affected item** `[BLOCKED]` (not `[x]`, not skipped).
3. **Continue with the next item** — a blocked item does NOT stop the session.
4. **Output truncation is a 1-strike terminal**, NOT 2-strike: switch to the
   Coverage File Method on the 1st failure.

### Examples
| Scenario | Strike 1 | Action | Strike 2 | Outcome |
|----------|----------|--------|----------|---------|
| `npx vitest run` fails | `vitest: not found` | `npm install` then retry | Still fails | BLOCKED. Report missing dep. Move on. |
| Test file has import error | `Cannot find module` | Fix import path, retry | Different error | New 2-strike cycle begins |
| Output is truncated | `Output truncated` | Switch to Coverage File Method (`--coverage.reporter=json-summary` → read `coverage/coverage-summary.json`) | File readable | Continue |
| Output is truncated | `Output truncated` | Retry same command with `\| tail` | Still truncated | NEVER do this — pipes are forbidden + truncation is deterministic |
| Coverage JSON parse fails | Parse error | Use `text-summary` fallback | Works | Continue |
| Coverage JSON parse fails | Parse error | Use `text-summary` fallback | Also fails | BLOCKED. Report. |

---

## Coverage Loop Prevention

This rule is specifically for agents that are **read-only validators** (e.g., QAAnalyst).

If all tests pass but coverage is below the required threshold:
1. **STOP.** Do NOT run more tests, do NOT write new tests, do NOT modify code.
2. **Report the gap as a finding** in your validation report:
   - Status: `REQUIRES FIXES`
   - Owner: `TestEngineer`
   - Action: write additional tests to reach coverage target
3. **Update the checkpoint** to reflect that QA is blocked by missing coverage.

Only **TestEngineer** (or another implementation agent) is allowed to write new tests to raise coverage. QA's job is to detect and report the gap, not to close it.

---

## Summary of Golden Rules

1. **NO PIPES** on test or lint commands.
2. **VERIFY CWD**: Always `cd` into the correct project folder (frontend/backend) first.
3. **TEXT REPORTERS** for coverage (e.g., `--coverageReporters="text-summary"`).
4. **COVERAGE FILE METHOD** when output is truncated (`--coverage.reporter=json-summary` → read JSON).
5. **ISOLATE** failing tests by running only their specific files.
6. **NEVER READ** raw log files (`tee/*.log`).
7. **2-STRIKE RULE**: same error twice = STOP, report `BLOCKED`, move on.
8. **Output truncation = 1-strike terminal**: switch to Coverage File Method, do not retry.
9. **READ-ONLY AGENTS** do not chase coverage gaps — they report them and stop.