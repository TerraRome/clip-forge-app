# Context Docs Index

This directory stores project context documentation for AI tooling and developer onboarding.

## Files

| File | Description |
|------|-------------|
| `backend-architecture.md` | Backend layer diagram, dependency flow, service hierarchy |
| `api-contracts.md` | API endpoint specs, request/response schemas |
| `data-model.md` | Domain entities, value objects, storage schema |
| `pipeline-flow.md` | Video processing pipeline: stages, error boundaries, fallbacks |
| `tech-stack.md` | Language, framework, library versions and rationale |
| `clipforge-prd.md` | Product requirements document: goals, features, constraints |

## Purpose

Context docs bridge the gap between standards (rules) and implementation (code). They provide the "why" behind architectural decisions and serve as grounding for AI-generated code.

## Updating

- Update when architectural decisions change.
- Keep files under 100 lines. Split when growing beyond.
- Link from relevant standards files where appropriate.
