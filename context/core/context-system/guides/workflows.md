<!-- Context: core/workflows | Priority: high | Version: 2.0 | Updated: 2026-03-29 -->

# Context Operation Workflows

**Purpose**: Stage-by-stage workflows for context operations (extract, organize, update, error)

---

## Extract Workflow

**Command**: `/context extract from {source}`

| Stage | Action | Approval |
|-------|--------|----------|
| 1. Read Source | Read and analyze source content | No |
| 2. Analyze | Categorize into concepts, errors, guides | No |
| 3. Select | User chooses category + items (letter-based: A/B/C) | **Yes** |
| 4. Preview | Show files to create with sizes, allow preview/skip | **Yes** |
| 5. Create | Create files in selected category | No |
| 6. Update | Update navigation.md | No |
| 7. Report | Summary: files created, sizes, totals | No |

**Key**: Items grouped by type (concepts/errors/guides). User selects with letters or `all`.

---

## Organize Workflow

**Command**: `/context organize {directory}`

| Stage | Action | Approval |
|-------|--------|----------|
| 1. Scan | Scan directory, count files | No |
| 2. Categorize | Sort into function folders (concepts/examples/guides/lookup/errors) | No |
| 3. Resolve | Present ambiguous files (split/keep options) + conflicts (merge/rename/skip) | **Yes** |
| 4. Preview | Show moves, splits, merges, reference fixes. Offer dry-run | **Yes** |
| 5. Backup | Create backup at `.tmp/backup/{op}-{topic}-{timestamp}/` | No |
| 6. Execute | Move, split, merge files | No |
| 7. Update | Fix internal references, update navigation | No |
| 8. Report | Summary with rollback path | No |

**Key**: Ambiguous files get letter-based options (Split/Keep-as-concept/Keep-as-guide). Conflicts get Merge/Rename/Skip.

---

## Update Workflow

**Command**: `/context update for {topic}`

| Stage | Action | Approval |
|-------|--------|----------|
| 1. Identify | User describes changes (API/deprecations/features/breaking) | **Yes** |
| 2. Find | Search files referencing topic, show impact count | No |
| 3. Preview | Show line-by-line diffs per file. User can approve all or edit per-line | **Yes** |
| 4. Backup | Create backup | No |
| 5. Update | Apply approved changes | No |
| 6. Migrate | Add migration notes to errors/ if breaking changes | No |
| 7. Validate | Check all references, confirm files under size limits | No |
| 8. Report | Summary: files updated, lines changed, rollback path | No |

**Key**: Preview shows `- old` / `+ new` diffs. User can approve all, edit per-line, or reject.

---

## Error Workflow

**Command**: `/context error for "{error message}"`

| Stage | Action | Approval |
|-------|--------|----------|
| 1. Search | Find similar/related errors in existing files | No |
| 2. Deduplicate | Options: Add new / Update existing / Skip. User picks category | **Yes** |
| 3. Preview | Show current vs proposed content with diffs | **Yes** |
| 4. Add | Write or update error entry | No |
| 5. Update | Cross-reference with related errors | No |
| 6. Report | Summary: file, size check, changes made | No |

**Key**: Error entries follow format: Symptom → Cause → Solution → Code → Prevention → Frequency → Reference.

---

## Common Patterns

| Pattern | Rules |
|---------|-------|
| **Approval Gates** | Show preview, wait for input, offer yes/no/edit/preview/dry-run, never auto-proceed |
| **Conflict Resolution** | Letter-based selection (A/B/C), show impact of each option |
| **Previews** | Show create/modify/delete, file sizes (before → after), diffs, validation status |
| **Backups** | Create before changes, store at `.tmp/backup/{op}-{topic}-{timestamp}/`, report location |

---

## Related

- `../operations/extract.md` - Extract operation details
- `../operations/organize.md` - Organize operation details
- `../operations/update.md` - Update operation details
- `../operations/error.md` - Error operation details
- `compact.md` - MVI compression techniques
