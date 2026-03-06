# Feature Docs Updater — Memory

## features.md Structure
- The file does NOT use the category-based format described in instructions. It uses numbered sections with `####` headers.
- Top section ("Core App Features") contains numbered items 15–56 covering the original feature set.
- Bottom section ("New Features") contains items 1–N for features added after the initial build.
- New features go at the bottom of the "## New Features" section, incrementing the number.
- Each entry uses bullet points under the `####` header (not a single-line format).
- Sections are separated by `---` horizontal rules.

## features_new.md Structure
- Created 2026-03-06 (did not previously exist).
- Standard chronological log: newest date at top, one bullet per feature per date.
- Format: `- **Feature Name**: One or two sentence description.`

## Naming Conventions
- Feature names in both files are concise title-case noun phrases (e.g., "Multi-Currency Support", "Bulk edit transactions").
- Descriptions use present tense and focus on user-visible behavior, not implementation class names.
- Exception: implementation details (provider names, method names) are acceptable in features.md bullets when they add useful technical context.

## Key Paths
- `/Users/user/dev/Cachium/docs/features.md` — category/numbered doc
- `/Users/user/dev/Cachium/docs/features_new.md` — chronological new-features log
