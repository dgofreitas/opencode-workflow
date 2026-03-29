---
description: Create a structured user story from a feature request, bug report, or spike
---

# /story — Create User Story

Delegates to **ProductManager** to transform a feature request, bug report, or spike into a structured, actionable user story.

## Usage

```
/story <description of what needs to be done>
```

## Workflow

1. **Invoke ProductManager**:
   ```
   task(subagent_type="ProductManager", description="Create user story", prompt="Create a structured user story for: $ARGUMENTS")
   ```

2. **ProductManager will**:
   - Classify the request (feature, bug, refactor, spike)
   - Write a structured story with title, description, acceptance criteria (GIVEN-WHEN-THEN)
   - Define Definition of Done
   - Output the story to `docs/stories/STORY-XXX.md`

3. **Return** the story file path and a summary to the user.

## Output

A markdown story file at `docs/stories/STORY-XXX.md` containing:
- Story type and title
- User story (As a / I want / So that)
- Acceptance criteria (GIVEN-WHEN-THEN format)
- Technical notes and constraints
- Definition of Done
