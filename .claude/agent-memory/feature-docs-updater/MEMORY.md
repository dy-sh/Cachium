# Feature Docs Updater — Memory

## features.md Structure
- The file does NOT use the category-based format described in instructions. It uses numbered sections with `####` headers.
- Top section ("Core App Features") contains numbered items 15–56 covering the original feature set.
- Bottom section ("New Features") contains items 1–N for features added after the initial build.
- New features go at the bottom of the "## New Features" section, incrementing the number.
- Each entry uses bullet points under the `####` header (not a single-line format).
- Sections are separated by `---` horizontal rules.
- Current highest item in "New Features": 34 (as of 2026-03-19). Note: items are not strictly sequential — item 32 exists but 33 was inserted before it in the file; numbering follows insertion order, not file order.

## features_new.md Structure
- Created 2026-03-06 (did not previously exist).
- Standard chronological log: newest date at top, one bullet per feature per date.
- Format: `- **Feature Name**: One or two sentence description.`

## Naming Conventions
- Feature names in both files are concise title-case noun phrases (e.g., "Multi-Currency Support", "Bulk edit transactions").
- Descriptions use present tense and focus on user-visible behavior, not implementation class names.
- Exception: implementation details (provider names, method names) are acceptable in features.md bullets when they add useful technical context.

## CLAUDE.md Update Pattern
- When a feature introduces a new route, add it to the "Routes" list in the relevant section (Database Management, etc.) or create a new section.
- When a feature introduces new key files/services, add them to the "Key Files" section.
- When a feature introduces a significant new architectural pattern (e.g., multi-currency), add a dedicated ## section explaining the pattern, key model fields, and conventions.
- The agent's job description says to update CLAUDE.md as well as docs/ files.

## Key Paths
- `/Users/user/dev/Cachium/docs/features.md` — numbered feature doc
- `/Users/user/dev/Cachium/docs/features_new.md` — chronological new-features log
- `/Users/user/dev/Cachium/CLAUDE.md` — project instructions (update routes, key files, and patterns here)
- `/Users/user/dev/Cachium/.claude/agent-memory/feature-docs-updater/MEMORY.md` — this file

## Notes
- Agent threads always have their cwd reset between bash calls; always use absolute file paths.
- Do not use emojis in any files.
- Do not use a colon before tool calls in responses.
