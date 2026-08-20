# Develop Workflow - Design System (UI Fase 0)

## Scope

This document defines the global visual foundation for the first dark version.

Constraints for this phase:

- No feature logic changes.
- No backend/network/firebase/share-intent behavior changes.
- No complete screen redesign yet.

## Theme Architecture

Theme files are centralized in `lib/core/theme`:

- `app_colors.dart`
- `app_theme.dart`
- `app_typography.dart`
- `app_spacing.dart`
- `app_radius.dart`
- `app_shadows.dart`

## Dark Palette (source of truth)

- Background main: `#0F1419`
- Background secondary: `#151B22`
- Surface/Card: `#1B232C`
- Surface elevated: `#222C36`
- Border/Divider: `#2C3742`
- Text primary: `#F3F6F8`
- Text secondary: `#A7B0BA`
- Text muted: `#6F7A86`
- Primary: `#2F6FED`
- Primary hover: `#3D7BFF`
- Primary muted: `#1C355E`

## Semantic Accent Tokens

Discussion type accents:

- ERROR: `#D65A62`
- IDEA: `#7A6FF0`
- IMPROVEMENT: `#42A98B`
- QUESTION: `#D2A94E`

Workflow status accents:

- NEW (Entrada): `#697684`
- REVIEW (Revision): `#C89B3C`
- IN_PROGRESS (Trabajando): `#4D7DE8`
- RESOLVED (Resuelto): `#3FA37C`

Unread accent (independent from status):

- UNREAD: `#4D8DFF`

Rule: semantic colors are accent colors (chips, small bars, icons, indicators). Cards keep neutral surfaces.

## Message UI Rule (future implementation)

Discussion messages must NOT look like WhatsApp bubbles.

Use a Slack/Discord style conversation structure:

- Continuous conversation background.
- Avatar + username + timestamp header.
- Message content below.
- Attachments integrated in message flow.
- Consecutive message compaction.
- Subtle hover on web.

## Discussion Card Rule (future implementation)

Discussion cards keep neutral background (`surface`).

Type/status/unread are visual accents only.

Do not paint the entire card with semantic colors.

## Density

Target density is medium/compact for professional internal usage.

Avoid oversized cards, giant controls, and oversized headers.

## Light Theme

`AppTheme` is prepared for:

- `AppTheme.darkTheme`
- `AppTheme.lightTheme`

Light theme visual design is intentionally postponed to a dedicated phase.
