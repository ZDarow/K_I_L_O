# Specifications (Specs)

Multi-session specifications for large initiatives that span multiple conversations.

## When to Use Specs

Use specs for work that:
- Spans **multiple sessions/conversations**
- Takes **2+ weeks** to complete
- Requires tracking across **multiple phases**
- Needs **persistent context** beyond a single plan

## Directory Structure

```
docs/specs/
├── README.md              # This file
├── templates/
│   └── spec-template.md   # Template for new specs
├── archive/               # Completed specs
└── {project-name}/        # Active spec directories
    ├── 00-START-HERE.md   # Quick context for session resume
    ├── README.md          # Spec overview
    ├── 01-problem.md      # Problem statement
    ├── 02-solution.md     # Proposed solution
    ├── 03-tasks.md        # Task breakdown by phase
    └── plans/             # Phase-specific plans
```

## Creating a New Spec

```bash
# Use the /specs workflow
/specs Create spec for {initiative name}

# Or manually:
cp -r docs/specs/templates docs/specs/{project-name}
```

## Spec Lifecycle

1. **Draft** - Initial creation, gathering requirements
2. **In Review** - Ready for stakeholder review
3. **Approved** - Ready for implementation
4. **In Progress** - Active development
5. **Completed** - All phases done, moved to archive

## Best Practices

- Keep `00-START-HERE.md` updated with current context
- Update `03-tasks.md` as phases complete
- Link plans to their parent spec
- Archive completed specs, don't delete them

## Related Workflows

- `/specs` - Create and manage specifications
- `/plan` - Create phase-specific plans within a spec
- `/work` - Execute plans
