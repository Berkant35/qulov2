---
name: run-tests
description: Run vitest tests for the backend, optionally filtering by service or file name
disable-model-invocation: true
---

# Run Tests

Runs backend tests using vitest.

## Arguments

- `<filter>` — (optional) Test file or service name to filter (e.g., `auth`, `quiz`, `diamond`)

## Steps

1. **If filter provided**: Run filtered tests
   ```bash
   cd server && npx vitest run --reporter=verbose <filter>
   ```

2. **If no filter**: Run all tests
   ```bash
   cd server && npx vitest run --reporter=verbose
   ```

3. **If tests fail**: Report failures with file paths and line numbers. Do NOT auto-fix unless asked.

4. **If no test files found for filter**: Suggest creating tests at `server/src/__tests__/<filter>.test.ts`

## Conventions

- Tests live in `server/src/__tests__/` or colocated as `*.test.ts`
- Use vitest (`describe`, `it`, `expect`)
- Mock Supabase calls, don't hit real DB in tests
