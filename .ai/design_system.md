# AI YouTube Clipper — Design System

> **Version:** 1.0.0  
> **Status:** Final  
> **Audience:** Flutter Developers, UI Designers, QA  
> **Purpose:** Single source of truth for the application's visual language. Every design token, component standard, and usage rule is documented to production detail.  
> **Relation to ui.md:** This document defines the **visual language**. `ui.md` defines **screen and component specifications**. Design decisions in both documents are identical.

---

## Table of Contents

1. Introduction
2. Material 3 Adaptation
3. Color System
4. Typography
5. Spacing
6. Radius
7. Elevation
8. Icon System
9. Component Standards
10. Motion System
11. Responsive Rules
12. Accessibility
13. Theme Extension Planning
14. Design Do & Don't
15. Future Expansion
16. Token Naming Convention
17. Visual Hierarchy
18. Component Composition Rules
19. Layout Rules
20. Asset Standards
21. Theme Scalability
22. Documentation Rules

---

## 1. Introduction

### 1.1 Purpose

The AI YouTube Clipper Design System defines the complete visual language for the application. It governs every pixel, color, typeface, motion, and interaction across Flutter mobile and desktop platforms. Every design decision is documented, named, and enforced through design tokens that map directly to `ThemeExtension` classes in the Flutter implementation.

### 1.2 Goals

- **Consistency** — Every screen looks and behaves like part of the same application.
- **Efficiency** — Designers and developers reach for documented tokens, not bespoke values.
- **Scalability** — New screens, themes, and features can be added without visual drift.
- **Accessibility** — WCAG AA compliance is built into the token system, not retrofitted.
- **Production clarity** — No ambiguity. Every value has a name, a purpose, and a usage rule.

### 1.3 Scope

This Design System covers:

- Color system (light and dark modes)
- Typography (typeface, scale, weights)
- Spacing (4dp grid, 10 tokens)
- Radius (5 levels)
- Elevation (6 levels)
- Iconography (library, sizes, stroke rules)
- Component standards (behavioral descriptions for 15 component types)
- Motion system (timing, curves, 6 animation types)
- Responsive rules (4 breakpoints)
- Accessibility (WCAG AA, contrast, semantics, touch targets)
- Token naming convention
- Visual hierarchy
- Component composition rules
- Layout rules
- Asset standards
- Theme scalability
- Documentation rules

Out of scope: screen layouts, navigation flows, state machines, API contracts, backend architecture, implementation code.

### 1.4 Design Philosophy

The design language sits between **Notion** (clean typography, generous whitespace) and **Linear** (purposeful color, soft shadows, micro-interactions). The app should feel like a professional creative tool: confident, quiet, and fast.

- **Minimal** — Every element must earn its place.
- **Premium** — Generous whitespace, refined typography, subtle shadows.
- **Simple** — Linear user flow. Never present more than one path forward.
- **Fast** — Perceived performance over actual performance. Skeleton screens, optimistic UI.
- **Accessible by default** — Tokens enforce WCAG AA contrast. No afterthought.

---

## 2. Material 3 Adaptation

### 2.1 What Is Used

| M3 Feature                                                                     | Usage                               | Rationale                                                                            |
| ------------------------------------------------------------------------------ | ----------------------------------- | ------------------------------------------------------------------------------------ |
| Color scheme tokens (`primary`, `secondary`, `surface`, `background`, `error`) | Base structure for theme definition | Flutter's `ColorScheme` maps directly to M3 concepts; we extend via `ThemeExtension` |
| Elevation system (`elevation: 0–5`)                                            | Conceptual inspiration only         | We define 6 custom levels with explicit y/blur/spread/opacity values                 |
| Typography system (`TextTheme`)                                                | Not used                            | We define a custom 10-level scale via `ThemeExtension`                               |
| Component defaults (`M3ButtonTheme`, `M3CardTheme`)                            | Not used                            | Every component is custom-built with explicit tokens                                 |
| `SurfaceTint` / `SurfaceContainer`                                             | Avoided                             | All surfaces use solid color tokens — no tonal elevation overlays                    |
| `NavigationBar` / `NavigationDrawer`                                           | Not used in MVP                     | Future features may adopt M3 navigation patterns                                     |

### 2.2 What Is Avoided

| M3 Feature                                            | Reason                                                                                                               |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `MaterialColor` swatches (50–900)                     | Not needed. Each color token has one light and one dark value. No tonal palette.                                     |
| `ColorScheme.brightness` for automatic adaptation     | We manually provide every color in both modes. No computed colors.                                                   |
| `useMaterial3: true` default components               | Default M3 components (buttons, cards, dialogs) do not match our custom design language. Every component is bespoke. |
| M3 surface variants (`surfaceVariant`, `surfaceTint`) | We use `colorSurfaceVariant` as a transparent token name — it maps to a solid color, not M3's tonal elevation.       |
| M3 dynamic color (Monet)                              | Not supported. Brand identity requires fixed primary (`#6C5CE7`).                                                    |
| M3 motion tokens                                      | We define our own timing/curve system (see §10).                                                                     |
| M3 shape tokens                                       | We define 5 custom radius levels (see §6).                                                                           |
| M3 spacing system                                     | We define a 10-level 4dp grid (see §5).                                                                              |

### 2.3 Adaptation Summary

The Design System uses **M3 as an architectural base** (separation of color/typography/elevation into token groups, `ThemeExtension` pattern) but **replaces every value** with custom tokens. No default M3 component theme is used. Every visual value originates from this document.

---

## 3. Color System

### 3.1 Token Overview

The color system has 18 color tokens. Each token has a light mode and dark mode hex value. All token names follow the `color` + `Name` convention (e.g. `colorPrimary`, `colorBackground`, `colorTextSecondary`).

### 3.2 Primary Colors

#### `colorPrimary`

| Attribute  | Value                                                                                   |
| ---------- | --------------------------------------------------------------------------------------- |
| Purpose    | Primary call-to-action buttons, active states, loading spinner, accent accent           |
| Light mode | `#6C5CE7` (Electric Violet)                                                             |
| Dark mode  | `#6C5CE7` (unchanged)                                                                   |
| Usage      | Background of `AppPrimaryButton`, selected tab indicator, active toggle, branded loader |
| Example    | "Generate Clips" button background, selected chip border                                |
| Do         | Use only for actionable elements. One saturated primary per screen.                     |
| Don't      | Use for body text, card backgrounds, decorative icons, or passive states.               |

#### `colorPrimaryContainer`

| Attribute  | Value                                                                                        |
| ---------- | -------------------------------------------------------------------------------------------- |
| Purpose    | Background for badges, selected chip backgrounds, highlighted states                         |
| Light mode | `#EDE9FE`                                                                                    |
| Dark mode  | `#2D2640`                                                                                    |
| Usage      | Background of selected `AppChip`, info badge background, tonal highlight behind primary icon |
| Example    | Selected clip count chip background, "Subtitles" info badge                                  |
| Do         | Use as a tonal complement to `colorPrimary` for selected/highlighted states                  |
| Don't      | Use for interactive element backgrounds — only for state indication                          |

#### `colorOnPrimary`

| Attribute  | Value                                                                                    |
| ---------- | ---------------------------------------------------------------------------------------- |
| Purpose    | Text and icons rendered on `colorPrimary` backgrounds                                    |
| Light mode | `#FFFFFF`                                                                                |
| Dark mode  | `#FFFFFF`                                                                                |
| Usage      | Button label text on primary buttons, icon on primary backgrounds                        |
| Example    | "Generate Clips" label text, check icon on success badge                                 |
| Do         | Always use this token for content placed on `colorPrimary` or `colorSuccess` backgrounds |
| Don't      | Use on non-primary backgrounds — use `colorTextPrimary` instead                          |

### 3.3 Secondary Color

#### `colorSecondary`

| Attribute  | Value                                                                    |
| ---------- | ------------------------------------------------------------------------ |
| Purpose    | Secondary actions, success indicators, brand accent variation            |
| Light mode | `#00CEC9` (Teal)                                                         |
| Dark mode  | `#00CEC9` (unchanged)                                                    |
| Usage      | Success badge dot, secondary decorative accent, optional alternative CTA |
| Example    | Success variant of `AppStatusBadge` dot                                  |
| Do         | Reserve for success feedback and low-emphasis brand moments              |
| Don't      | Use for primary CTAs, body text, or error states                         |

### 3.4 Background & Surface

#### `colorBackground`

| Attribute  | Value                                                   |
| ---------- | ------------------------------------------------------- |
| Purpose    | App-level background behind all content                 |
| Light mode | `#F7F7F8`                                               |
| Dark mode  | `#0D0D0F`                                               |
| Usage      | Scaffold background, splash screen, screen behind cards |
| Example    | Home screen background behind card list                 |
| Do         | Use as the outermost container color                    |
| Don't      | Use on cards, sheets, or elevated surfaces              |

#### `colorSurface`

| Attribute  | Value                                                               |
| ---------- | ------------------------------------------------------------------- |
| Purpose    | Card backgrounds, bottom sheets, dialogs, elevated surfaces         |
| Light mode | `#FFFFFF`                                                           |
| Dark mode  | `#1C1C1E`                                                           |
| Usage      | `AppCard` background, `AppDialog` surface, `AppBottomSheet` surface |
| Example    | Project card background, processing card background                 |
| Do         | Use for any elevated content container                              |
| Don't      | Use for the app background                                          |

#### `colorSurfaceVariant`

| Attribute  | Value                                                                                   |
| ---------- | --------------------------------------------------------------------------------------- |
| Purpose    | Tonal elevation for search bars, chip unselected backgrounds, secondary surfaces        |
| Light mode | `#F0F0F2`                                                                               |
| Dark mode  | `#2C2C2E`                                                                               |
| Usage      | Unselected chip background, disabled text field background, section divider backgrounds |
| Example    | Unselected "1 clip" chip background                                                     |
| Do         | Use as a lower-contrast alternative to `colorSurface` for non-interactive containers    |
| Don't      | Use for interactive element backgrounds — only for passive state containers             |

### 3.5 Text Colors

#### `colorTextPrimary`

| Attribute  | Value                                                                           |
| ---------- | ------------------------------------------------------------------------------- |
| Purpose    | Primary body text, headings, labels                                             |
| Light mode | `#1A1A2E`                                                                       |
| Dark mode  | `#F5F5F7`                                                                       |
| Usage      | Card titles, screen headings, button labels (non-primary), input values         |
| Example    | "Recent Projects" section heading, clip title text                              |
| Do         | Use for all primary text content                                                |
| Don't      | Use on colored backgrounds — use `colorOnPrimary` or ensure sufficient contrast |

#### `colorTextSecondary`

| Attribute  | Value                                                               |
| ---------- | ------------------------------------------------------------------- |
| Purpose    | Helper text, metadata, secondary labels, descriptions               |
| Light mode | `#6B7280`                                                           |
| Dark mode  | `#9CA3AF`                                                           |
| Usage      | Helper text below text field, metadata on video card, step labels   |
| Example    | "1 clip = ~15-60 seconds" helper text, "1080×1920 · 12 MB" metadata |
| Do         | Use for any text that supports but is not the primary content       |
| Don't      | Use for headlines, CTAs, or primary information                     |

#### `colorTextTertiary`

| Attribute  | Value                                                                             |
| ---------- | --------------------------------------------------------------------------------- |
| Purpose    | Placeholder text, disabled text, hint text                                        |
| Light mode | `#9CA3AF`                                                                         |
| Dark mode  | `#6B7280`                                                                         |
| Usage      | Text field placeholder, disabled button label, timestamp placeholders             |
| Example    | "Paste YouTube URL" placeholder text                                              |
| Do         | Use for the lowest-emphasis text in a visual hierarchy                            |
| Don't      | Use for any text that must be legible at small sizes — only for very low emphasis |

### 3.6 Border & Divider

#### `colorBorder`

| Attribute  | Value                                                                      |
| ---------- | -------------------------------------------------------------------------- |
| Purpose    | Card outlines, text field borders, separator lines                         |
| Light mode | `#E5E7EB`                                                                  |
| Dark mode  | `#38383A`                                                                  |
| Usage      | 1px border on outlined buttons, text field default border, card top border |
| Example    | Unselected `AppChip` border, `AppSecondaryButton` outlined variant border  |
| Do         | Use for 1px borders that separate content visually without elevation       |
| Don't      | Use for thick section dividers — use `colorDivider` instead                |

#### `colorDivider`

| Attribute  | Value                                                                         |
| ---------- | ----------------------------------------------------------------------------- |
| Purpose    | Thick section dividers between content groups                                 |
| Light mode | `#F0F0F2`                                                                     |
| Dark mode  | `#2C2C2E`                                                                     |
| Usage      | Section divider below `AppSection` heading, separator between settings groups |
| Example    | Divider below "Recent Projects" section header                                |
| Do         | Use for visual separation between distinct sections of content                |
| Don't      | Use for 1px card borders — use `colorBorder` instead                          |

### 3.7 Semantic Colors

#### `colorError`

| Attribute  | Value                                                                                         |
| ---------- | --------------------------------------------------------------------------------------------- |
| Purpose    | Error messages, destructive actions, validation failures                                      |
| Light mode | `#EF4444`                                                                                     |
| Dark mode  | `#F87171`                                                                                     |
| Usage      | Text field error border, error message text, destructive dialog confirm button, error icon    |
| Example    | "Please enter a valid YouTube URL" error text, "Cancel & Delete" button on destructive dialog |
| Do         | Use only for errors, destructive confirmations, and critical failures                         |
| Don't      | Use for warnings, info states, or decorative purposes                                         |

#### `colorSuccess`

| Attribute  | Value                                                                            |
| ---------- | -------------------------------------------------------------------------------- |
| Purpose    | Success indicators, positive feedback, subtitle-exists badge                     |
| Light mode | `#10B981`                                                                        |
| Dark mode  | `#34D399`                                                                        |
| Usage      | Success badge background, success snackbar background, upload complete indicator |
| Example    | "Subtitles ✓" badge on video card                                                |
| Do         | Use exclusively for positive confirmation states                                 |
| Don't      | Use for errors, warnings, or informational states                                |

#### `colorWarning`

| Attribute  | Value                                                               |
| ---------- | ------------------------------------------------------------------- |
| Purpose    | Warning indicators, caution states, processing stall notice         |
| Light mode | `#F59E0B`                                                           |
| Dark mode  | `#FBBF24`                                                           |
| Usage      | Warning badge, stalled processing warning text                      |
| Example    | "This is taking longer than usual" warning text on processing stall |
| Do         | Use for non-critical attention states                               |
| Don't      | Use for errors or success states                                    |

#### `colorInfo` (Implied — no dedicated token)

Information states use `colorPrimaryContainer` (background) + `colorPrimary` (text/icon). No separate `colorInfo` token exists. This pattern is used for "info" variant badges.

### 3.8 Overlay & Feedback

#### `colorOverlay`

| Attribute  | Value                                                                      |
| ---------- | -------------------------------------------------------------------------- |
| Purpose    | Scrim overlay for modals, dialogs, bottom sheets                           |
| Light mode | `#000000` at 40% opacity                                                   |
| Dark mode  | `#000000` at 60% opacity                                                   |
| Usage      | Background scrim behind `AppDialog`, `AppBottomSheet`, `AppLoadingOverlay` |
| Example    | Semi-transparent black behind cancel confirmation dialog                   |
| Do         | Use for all modal overlays consistently                                    |
| Don't      | Use as a color on any element — only as an overlay scrim                   |

#### `colorSkeleton`

| Attribute  | Value                                                                      |
| ---------- | -------------------------------------------------------------------------- |
| Purpose    | Skeleton loader base color for shimmer animation                           |
| Light mode | `#E5E7EB`                                                                  |
| Dark mode  | `#38383A`                                                                  |
| Usage      | Background of `AppSkeletonCard`, `AppSkeletonText`, `AppSkeletonThumbnail` |
| Example    | Gray placeholder shape on loading project list                             |
| Do         | Use only within skeleton/shimmer loader components                         |
| Don't      | Use for loading spinners — use `colorPrimary` instead                      |

#### `colorSkeletonHighlight`

| Attribute  | Value                                                    |
| ---------- | -------------------------------------------------------- |
| Purpose    | Skeleton shimmer sweep highlight                         |
| Light mode | `#F3F4F6`                                                |
| Dark mode  | `#48484A`                                                |
| Usage      | Moving highlight gradient in skeleton loaders            |
| Example    | Light sweep across gray skeleton card                    |
| Do         | Pair with `colorSkeleton` for shimmer animation gradient |
| Don't      | Use independently — always combined with `colorSkeleton` |

#### `colorShadow`

| Attribute  | Value                                                              |
| ---------- | ------------------------------------------------------------------ |
| Purpose    | Box shadow color for elevation effects                             |
| Light mode | `#000000` at 8%                                                    |
| Dark mode  | `#000000` at 30%                                                   |
| Usage      | Drop shadow on cards, buttons, sheets, dialogs                     |
| Example    | Subtle card shadow in light mode                                   |
| Do         | Use as the shadow color in elevation box shadows                   |
| Don't      | Modify opacity per elevation level — use elevation tokens (see §7) |

### 3.9 Disabled State

Disabled state uses a single opacity value, not a separate color:

- **Disabled opacity:** 38% (`opacityDisabled`)
- Applied to the entire component, not individual elements
- No dedicated `colorDisabled` token

---

## 4. Typography

### 4.1 Typeface

| Attribute          | Value                                                    |
| ------------------ | -------------------------------------------------------- |
| Primary typeface   | Inter                                                    |
| Fallback stack     | SF Pro (iOS), Roboto (Android), system sans-serif        |
| Availability       | Free download from rsms.me/inter, Google Fonts           |
| License            | SIL Open Font License 1.1                                |
| Font family in use | `'Inter', -apple-system, 'SF Pro', 'Roboto', sans-serif` |

### 4.2 Scale

| Token             | Size | Weight          | Line Height | Letter Spacing | Usage                                               |
| ----------------- | ---- | --------------- | ----------- | -------------- | --------------------------------------------------- |
| `textCaption`     | 12px | 400 (Regular)   | 16px        | 0.4px          | Badges, timestamps, metadata labels, legal text     |
| `textCaptionBold` | 12px | 600 (Semi-bold) | 16px        | 0.4px          | Active badge text, selected state in badges         |
| `textBody`        | 14px | 400 (Regular)   | 20px        | 0px            | Card descriptions, secondary content, helper text   |
| `textBodyMedium`  | 14px | 500 (Medium)    | 20px        | 0px            | Card titles, list item labels, button text          |
| `textBodyLarge`   | 16px | 400 (Regular)   | 24px        | 0px            | Paragraph body text, text input value, instructions |
| `textSubhead`     | 18px | 500 (Medium)    | 24px        | -0.2px         | Section headings, screen title in app bar           |
| `textTitle`       | 20px | 600 (Semi-bold) | 28px        | -0.3px         | Screen titles, page headings, dialog title          |
| `textHeading`     | 24px | 600 (Semi-bold) | 32px        | -0.4px         | Large headings, empty state title, hero title       |
| `textH2`          | 32px | 600 (Semi-bold) | 40px        | -0.5px         | Hero section headings, marketing copy               |
| `textH1`          | 40px | 700 (Bold)      | 48px        | -0.6px         | Splash screen brand display, brand hero             |

### 4.3 Weight Usage

| Weight    | Value | Used For                                                   |
| --------- | ----- | ---------------------------------------------------------- |
| Regular   | 400   | Body text, descriptions, captions, footnotes               |
| Medium    | 500   | Card titles, list item labels, subheadings, input values   |
| Semi-bold | 600   | All headings, button labels, active state text, badge bold |
| Bold      | 700   | Reserved for `textH1` brand display only                   |

### 4.4 Line Height Rules

- Body text: 1.5× font size (20px for 14px, 24px for 16px)
- Headings: 1.3–1.4× font size (24px for 18px, 28px for 20px, 32px for 24px)
- Hero text: 1.2× font size (40px for 32px, 48px for 40px)

### 4.5 Letter Spacing Rules

- Zero letter spacing for all body text (14–16px)
- Negative letter spacing for headings (18px and above): -0.2px to -0.6px
- Positive letter spacing for captions (12px): 0.4px
- Never apply positive letter spacing to body or heading text

### 4.6 When to Use Each Style

| Context               | Style                | Rationale                                           |
| --------------------- | -------------------- | --------------------------------------------------- |
| Badge text            | `textCaption`        | Small, low-emphasis, space-constrained              |
| Active badge state    | `textCaptionBold`    | Emphasis within small space                         |
| Card description      | `textBody`           | Regular weight, readable at small size              |
| Card title            | `textBodyMedium`     | Medium weight gives hierarchy without size increase |
| Button label          | `textBodyMedium`     | Slightly heavier than body, not as heavy as heading |
| Form input value      | `textBodyLarge`      | Larger for editing comfort                          |
| Paragraph instruction | `textBodyLarge`      | Comfortable reading size for instructions           |
| Section heading       | `textSubhead`        | Distinguished from body without being too large     |
| Screen title          | `textTitle`          | Clear page-level hierarchy                          |
| Dialog title          | `textTitle`          | Same as screen title for consistent modal hierarchy |
| Empty state headline  | `textHeading`        | Prominent but not overwhelming                      |
| Hero/brand display    | `textH2` or `textH1` | Marketing weight, not frequent in app UI            |

### 4.7 Text Wrapping & Truncation Rules

- Body text: soft wrap, never truncate
- Card titles: max 2 lines, ellipsis on overflow
- Badge labels: single line, max 12 characters, overflow hidden
- Button labels: single line, never truncate — button should grow
- Section headings: single line, ellipsis on overflow
- Screen titles: single line, ellipsis on overflow

### 4.8 Typeface Usage Rules

- Use Inter for all UI text. No exceptions.
- No italic typeface in UI. Reserved for fine print and legal text only.
- No all-caps text except for badges of 4 characters or fewer.
- No underlined text except for explicit hyperlinks.
- Default text alignment: left-to-left for LTR languages. Centered only for empty states, splash screen, and dialogs.

---

## 5. Spacing

### 5.1 Grid System

The spacing system is based on a **4dp base unit**. All spacing values are multiples of 4.

### 5.2 Spacing Tokens

| Token            | Value | Base Units | Usage                                                                                  |
| ---------------- | ----- | ---------- | -------------------------------------------------------------------------------------- |
| `spacingXxs`     | 4dp   | 1×         | Between icon and text in buttons, inline spacing, minimum gap                          |
| `spacingXs`      | 8dp   | 2×         | Between chips, avatar groups, icon-to-text gap                                         |
| `spacingSm`      | 12dp  | 3×         | Between related form elements (label + input), section header to first item            |
| `spacingMd`      | 16dp  | 4×         | Card content padding, horizontal page padding (phone), between unrelated form sections |
| `spacingLg`      | 20dp  | 5×         | Between sections on a card, between section header and divider                         |
| `spacingXl`      | 24dp  | 6×         | Between major sections, bottom of page content, page top padding (below app bar)       |
| `spacingXxl`     | 32dp  | 8×         | Between cards, vertical section spacing on screen                                      |
| `spacingXxxl`    | 40dp  | 10×        | Page top padding (hero screens), very large section separation                         |
| `spacingHuge`    | 48dp  | 12×        | Between content groups, large screen breathing room                                    |
| `spacingMassive` | 64dp  | 16×        | App bar top offset, splash screen vertical spacing                                     |

### 5.3 Token Usage Examples

| Element Context            | Token                   | Rationale                                |
| -------------------------- | ----------------------- | ---------------------------------------- |
| Card content to edge       | `spacingMd`             | Standard content inset                   |
| Card to next card          | `spacingXxl`            | Separates distinct items                 |
| Section heading to content | `spacingSm`             | Tight coupling between label and content |
| Form label to form field   | `spacingSm`             | Related elements                         |
| Form field to next field   | `spacingXl`             | Unrelated form groups                    |
| Icon to adjacent label     | `spacingXs`             | Tight visual pairing                     |
| Page edge (phone)          | `spacingMd`             | Comfortable reading margin               |
| Page edge (tablet/desktop) | `spacingXxl`            | Centered layout with breathing room      |
| Primary CTA to bottom      | safe area + `spacingMd` | Gesture accessibility                    |
| Section to next section    | `spacingXxl`            | Clear content grouping                   |
| Between chips in row       | `spacingXs`             | Compact but selectable                   |

### 5.4 Margin Rules

- Horizontal page margins: `spacingMd` (16dp) on phone, `spacingXxl` (32dp) on tablet/desktop
- Vertical section margins: `spacingXxl` (32dp)
- Card internal padding: `spacingMd` (16dp) all sides
- Between elements within a card: `spacingSm` (12dp)
- App bar bottom border: 0 margin (border is flush with app bar)

### 5.5 Padding Rules

- Buttons: horizontal `spacingXl` (24dp), vertical `spacingSm` (12dp)
- Text fields: horizontal `spacingMd` (16dp)
- Dialog content: `spacingXl` (24dp) all sides
- Bottom sheet content: top `spacingLg` (20dp), horizontal `spacingMd` (16dp)
- Chip content: horizontal 10dp, vertical 6dp

### 5.6 Section Spacing

| Between                                  | Gap  | Token        |
| ---------------------------------------- | ---- | ------------ |
| Section heading and first item           | 12dp | `spacingSm`  |
| Section heading and content (no divider) | 12dp | `spacingSm`  |
| Section heading and divider              | 8dp  | `spacingXs`  |
| Divider and content                      | 12dp | `spacingSm`  |
| Between two sections                     | 32dp | `spacingXxl` |
| Last section and bottom CTA              | 24dp | `spacingXl`  |

---

## 6. Radius

### 6.1 Radius Tokens

| Token        | Value | Visual             | Characteristics                                    |
| ------------ | ----- | ------------------ | -------------------------------------------------- |
| `radiusSm`   | 8dp   | Slightly rounded   | Buttons, text fields, small chips                  |
| `radiusMd`   | 12dp  | Moderately rounded | Cards, primary component corners, loading overlays |
| `radiusLg`   | 16dp  | Very rounded       | Dialogs, bottom sheets                             |
| `radiusXl`   | 24dp  | Extremely rounded  | Full-width cards, hero images, sheet top corners   |
| `radiusFull` | 999dp | Fully pill-shaped  | Chips, badges, circular avatars                    |

### 6.2 Per-Component Radius Mapping

| Component            | Radius Token         | Notes                                 |
| -------------------- | -------------------- | ------------------------------------- |
| Primary button       | `radiusSm` (8dp)     | Distinct but not pill-shaped          |
| Secondary button     | `radiusSm` (8dp)     | Consistent with primary               |
| Text field           | `radiusSm` (8dp)     | Consistent with buttons               |
| Card (full)          | `radiusMd` (12dp)    | All four corners                      |
| Video card thumbnail | `radiusMd` (12dp)    | Top corners only; bottom corners flat |
| Dialog               | `radiusLg` (16dp)    | All four corners                      |
| Bottom sheet         | `radiusXl` (24dp)    | Top-left and top-right corners only   |
| Chip (selectable)    | `radiusFull` (999dp) | Fully pill-shaped                     |
| Badge (status)       | `radiusFull` (999dp) | Fully pill-shaped                     |
| Loading overlay      | `radiusMd` (12dp)    | All four corners                      |
| Progress card        | `radiusMd` (12dp)    | All four corners                      |
| Snackbar             | `radiusMd` (12dp)    | All four corners                      |

### 6.3 Radius Usage Guidelines

- Apply the same radius to all four corners by default.
- Override corners individually only when specified (e.g., bottom sheet top-only radius, video card top-only radius).
- Never mix `radiusSm` and `radiusMd` on the same component.
- `radiusFull` is only for chips and badges — never for cards or buttons.
- Cards in a grid must all use the same radius value.
- Nested components should never have a larger radius than their container.

---

## 7. Elevation

### 7.1 Elevation Tokens

Each elevation token defines a box shadow using four parameters: vertical offset (y), blur radius, spread radius, and shadow opacity.

| Token             | y    | blur | spread | Opacity (light) | Opacity (dark) | Visual                           |
| ----------------- | ---- | ---- | ------ | --------------- | -------------- | -------------------------------- |
| `elevationNone`   | 0    | 0    | 0      | 0%              | 0%             | Flat. No shadow.                 |
| `elevationSm`     | 1px  | 4px  | 0      | 6%              | 6%             | Subtle. Card default.            |
| `elevationMd`     | 2px  | 8px  | 0      | 8%              | 8%             | Medium. Elevated cards, buttons. |
| `elevationLg`     | 4px  | 16px | -2px   | 10%             | 10%            | High. Dropdowns, popovers, FAB.  |
| `elevationXl`     | -4px | 24px | 0      | 12%             | 12%            | Upward. Bottom sheets.           |
| `elevationDialog` | 8px  | 32px | -4px   | 16%             | 16%            | Highest. Dialogs.                |

### 7.2 Per-Component Elevation Mapping

| Component                 | Default Elevation            | Pressed Elevation         | Rationale                               |
| ------------------------- | ---------------------------- | ------------------------- | --------------------------------------- |
| Card (in scrollable list) | `elevationNone` (use border) | `elevationSm`             | Flat list, subtle tap feedback          |
| Card (tappable)           | `elevationSm`                | `elevationMd`             | Default depth, slightly higher on tap   |
| Primary button            | `elevationMd`                | `elevationMd` (no change) | Stands out, no lift on press            |
| Bottom sheet              | `elevationXl`                | —                         | Sheet appears above content             |
| Dialog                    | `elevationDialog`            | —                         | Highest context, modal focus            |
| App bar                   | `elevationNone` (use border) | —                         | Flat, clean, modern                     |
| FAB                       | `elevationLg`                | `elevationMd`             | Floating above, drops slightly on press |
| Dropdown / popover        | `elevationLg`                | —                         | Overlapping content                     |
| Snackbar                  | `elevationMd`                | —                         | Above content, below dialog             |
| Text field (focused)      | `elevationLg`                | —                         | Slight lift on focus                    |

### 7.3 Elevation Rules

- Cards in a scrollable list should use `elevationNone` with a bottom border (`colorBorder`, 1px) to avoid messy shadow stacking during scroll.
- Only elevated surfaces with content separation needs should have shadows. Do not add elevation to elements that are flush with their background.
- Negative y offset (`elevationXl`) creates an upward shadow, visually lifting the element from the bottom.
- Elevation is purely visual (box shadow). No Z-translation or physical depth in code.

---

## 8. Icon System

### 8.1 Library

| Attribute     | Value                                                                                         |
| ------------- | --------------------------------------------------------------------------------------------- |
| Library       | Lucide Icons                                                                                  |
| License       | MIT License                                                                                   |
| Style         | Outlined, 2px stroke, consistent 24×24 viewBox                                                |
| Package       | `lucide_icons` (Flutter)                                                                      |
| Quantity      | 1000+ icons                                                                                   |
| Justification | Consistent stroke weight, minimalist aesthetic, MIT license, tree-shakeable, active community |

### 8.2 Icon Size Tokens

| Token         | Size | Usage                                                                        |
| ------------- | ---- | ---------------------------------------------------------------------------- |
| `iconInline`  | 16dp | Inline with body text, status indicators inside badges, small metadata icons |
| `iconSmall`   | 20dp | Secondary button icons, compact action icons, chip icons                     |
| `iconDefault` | 24dp | App bar actions, primary button icons, section icon headers                  |
| `iconLarge`   | 32dp | Empty state illustrations, feature icons, card hero icons                    |
| `iconHero`    | 48dp | Splash screen logo, large decorative icons, brand hero                       |

### 8.3 Stroke Width

All Lucide icons use the default 2px stroke width. Never modify stroke width. If an icon appears too thin at small sizes (`iconInline`), choose a simpler icon rather than increasing stroke weight.

### 8.4 Filled vs Outlined

| Type               | Usage                                                                                                                                                                          |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Outlined (default) | All UI icons. This is the only style in use.                                                                                                                                   |
| Filled             | Never used. Lucide does not provide filled variants. If filled visual is needed (e.g., active tab), use a different icon (e.g., bold variant) or apply a background container. |

### 8.5 Color Inheritance

Icons inherit color from their parent text color by default. Explicit icon colors are only set in these cases:

- Icons on colored button backgrounds: `colorOnPrimary`
- Error icons: `colorError`
- Success icons: `colorSuccess`
- Warning icons: `colorWarning`
- Info icons: `colorPrimary`

### 8.6 Icon Usage Rules

- Icons must always have a semantic label for screen readers.
- Icons in buttons must have accompanying text (icon + label). Never icon-only buttons.
- Decorative icons (empty states, illustrations) can be text-free but must have an empty `Semantics` label.
- Never use icons from multiple libraries. Lucide only.
- Never modify icon stroke, fill, or viewBox.
- Icons receive color from the parent text color by default. Only override when on a colored background or for semantic purpose.
- Minimum icon touch target: 48×48dp (WCAG). Wrap small icons in a 48dp touch container.

### 8.7 Icon Inventory

| Icon             | Page                | Component                          |
| ---------------- | ------------------- | ---------------------------------- |
| `ClipboardPaste` | New Project         | Paste-detection icon in text field |
| `Scissors`       | Home                | Create New button, FAB             |
| `Loader`         | Processing          | Processing animation               |
| `CheckCircle`    | Result              | Success badge                      |
| `Download`       | Result, Clip Detail | Download button                    |
| `Eye`            | Result, Clip Detail | Preview button                     |
| `Share2`         | Result, Clip Detail | Share button                       |
| `ChevronLeft`    | All                 | Back navigation                    |
| `Sun`            | Settings            | Light mode icon                    |
| `Moon`           | Settings            | Dark mode icon                     |
| `Settings`       | Home                | Settings gear                      |
| `Trash2`         | Processing          | Cancel icon                        |
| `Film`           | Empty state         | No videos icon                     |
| `WifiOff`        | Error state         | Offline icon                       |
| `AlertCircle`    | Error state         | Error icon                         |
| `Play`           | Clip Detail         | Video play overlay                 |
| `Subtitles`      | Result              | Subtitle badge icon                |
| `Clock`          | Result              | Duration indicator                 |
| `Maximize2`      | Clip Detail         | Fullscreen toggle                  |
| `RefreshCw`      | Error state         | Retry icon                         |

---

## 9. Component Standards

This section defines the visual and behavioral standards for each component type. It does not define props, states, or implementation details (those are in `ui.md` §13). These standards are the visual contract that every component implementation must satisfy.

### 9.1 Buttons

**Primary Button (`AppPrimaryButton`):** Full-width, high-emphasis call-to-action. Background is `colorPrimary`. Text is `colorOnPrimary` using `textBodyMedium` (14/500). Height is 56dp (`touchButton`). Corner radius is `radiusSm` (8dp). Elevation is `elevationMd`. Leading icon is optional, 20dp (`iconSmall`). Loading state replaces icon with a 20dp circular spinner in `colorOnPrimary`. Disabled state applies `opacityDisabled` (38%). Always positioned at bottom of viewport with safe area padding.

**Secondary Button (`AppSecondaryButton`):** Medium-emphasis action. Two variants: `outlined` (1px `colorBorder` stroke, no background, `colorTextPrimary` text) and `text` (no border, no background, `colorTextPrimary` text). Height is 48dp (compact) or 56dp (to match primary). Corner radius is `radiusSm` (8dp). Destructive variant uses `colorError` for text and border. No elevation.

**Rules:**

- One primary button per screen maximum.
- Secondary buttons never appear without a primary button present.
- Sentence case labels only ("Generate clips", not "Generate Clips").
- No all-caps labels.

### 9.2 Cards

**Standard Card (`AppCard`):** Content container with `colorSurface` background, `radiusMd` (12dp) corners, and `elevationSm` shadow (unless in scrollable list, then `elevationNone` with 1px `colorBorder` bottom border). Internal padding is `spacingMd` (16dp) all sides. Tappable cards have minimum 72dp height (`touchCard`). Pressed state increases elevation to `elevationMd` with subtle scale (0.99).

**Rules:**

- Never nest cards inside cards.
- Cards in a grid must have identical dimensions.
- Tappable cards cover the full card area — no small tap targets within.

### 9.3 Text Fields

**Text Field (`AppTextField`):** Input container with `colorSurface` background, `colorBorder` 1px border, `radiusSm` (8dp) corners. Height is 56dp (`touchButton`). Padding is `spacingMd` (16dp) horizontal. Focused state uses `colorPrimary` border (2px) with `elevationLg`. Error state uses `colorError` border (2px) with error text below (`textCaption`, 12/400, `colorError`, 8dp gap). Disabled state uses `colorSurfaceVariant` background with `opacityDisabled`. Prefix icon is `iconDefault` (24dp) in `colorTextSecondary`. Clear/suffix icon appears when value is non-empty. Paste detection adds brief pulsating animation on prefix icon.

**Rules:**

- Validate on focus loss or explicit submit, not on every keystroke.
- Error text appears below the field, not in a dialog or snackbar.
- No success state (green border). Only error or default.

### 9.4 Dialogs

**Dialog (`AppDialog`):** Modal confirmation container centered on screen. Background is `colorSurface`, corner radius is `radiusLg` (16dp), elevation is `elevationDialog`. Width is 312dp on phone, max 400dp on larger screens. Internal padding is `spacingXl` (24dp) all sides. Title uses `textTitle` (20/600). Message uses `textBody` (14/400). Two bottom-aligned buttons: cancel (`AppSecondaryButton`, left) and confirm (`AppPrimaryButton`, right). Scrim overlay is `colorOverlay`, tappable to dismiss.

**Appearance animation:** Scale from 0.95 + fade in, 150ms `easeOutBack`.  
**Dismiss animation:** Scale to 0.95 + fade out, 100ms `easeIn`.

**Rules:**

- Only use for destructive confirmations (cancel processing, delete project).
- Use bottom sheets for non-destructive selections.
- Never present more than two options.

### 9.5 Bottom Sheets

**Bottom Sheet (`AppBottomSheet`):** Draggable sheet from bottom of screen. Top-left and top-right corners are `radiusXl` (24dp). Background is `colorSurface`. Elevation is `elevationXl` (upward shadow). Drag handle is 32dp wide, 4dp tall, `colorBorder`, rounded pill, centered at top. Sheet heading uses `textSubhead` (18/500). Each action item is 56dp height with leading icon (24dp, `iconDefault`) and label (`textBody`, 14/400). Tapping an action dismisses the sheet. Swipe down or tap scrim to dismiss.

**Appearance animation:** Slide up, 250ms `easeOutCubic`.  
**Dismiss animation:** Slide down, 200ms `easeInCubic`.

**Rules:**

- Use for selections, pickers, and sharing options.
- Never use for destructive confirmations (use dialog instead).
- Maximum 6 action items.

### 9.6 Snackbars

**Snackbar (`AppSnackbar`):** Brief feedback message at bottom of screen. Positioned above safe area with 16dp margin from edges. Corner radius is `radiusMd` (12dp). Padding is 16dp horizontal, 12dp vertical. Height is auto (min 48dp). Four variants with distinct background colors:

- **Default:** `colorSurface` background, `colorTextPrimary` text
- **Success:** `colorSuccess` background, `colorOnPrimary` text
- **Error:** `colorError` background, `colorOnPrimary` text
- **Warning:** `colorWarning` background, `#1A1A2E` (dark text)

**Appearance animation:** Slide up, 250ms `easeOut`.  
**Dismiss animation:** Slide down, 200ms `easeIn`.  
**Duration:** 4 seconds auto-dismiss.

**Rules:**

- Max 80 characters per message.
- Swipe to dismiss.
- Only one snackbar visible at a time (queue subsequent).
- Optional action button: `textBodyMedium` (14/500) in white.

### 9.7 Badges

**Status Badge (`AppStatusBadge`):** Small pill indicator for status. Height is 24dp. Padding is 10dp horizontal. Corner radius is `radiusFull` (999dp). Font is `textCaption` (12/400). Leading icon is `iconInline` (16dp). Six variants:

- **Default:** `colorSurfaceVariant` background, `colorTextSecondary` text, no icon
- **Success:** `colorSuccess` at 15% opacity background, `colorSuccess` text, check icon
- **Warning:** `colorWarning` at 15% opacity background, `colorWarning` text, alert icon
- **Error:** `colorError` at 15% opacity background, `colorError` text, X icon
- **Info:** `colorPrimaryContainer` background, `colorPrimary` text, info icon

**Rules:**

- No tap interaction by default.
- Max 12 characters.
- Single line only.

### 9.8 Chips

**Chip (`AppChip`):** Selectable pill for option selection. Height is 36dp (default) or 32dp (compact). Corner radius is `radiusFull` (999dp). Two states:

- **Unselected:** `colorSurfaceVariant` background, `colorTextSecondary` text, `borderThin` (1px) `colorBorder`
- **Selected:** `colorPrimaryContainer` background, `colorPrimary` text, `borderRegular` (2px) `colorPrimary`

Press scale: 0.97. Disabled: `opacityDisabled`.

**Rules:**

- Equal width in a row (fills available space).
- Maximum 4 chips per row.
- Always mutually exclusive selection (radio behavior, not checkbox).

### 9.9 Progress

**Progress Card (`AppProgressCard`):** Processing state card with circular determinate progress ring. Ring tracks progress from 0.0 to 1.0, animating on each update. Current step label below ring uses `textBodyLarge` (16/400). Estimated time uses `textBody` (14/400) in `colorTextSecondary`. Pipeline steps list below: done steps show check icon in `colorSuccess`, active step shows pulsing dot in `colorPrimary`, pending steps show circle outline in `colorTextTertiary`.

**Rules:**

- Progress ring uses determinate animation — updates every poll interval.
- Stalled warning (>30s no change) shows `colorWarning` text below pipeline.
- Background is `colorSurface` with `radiusMd`.

### 9.10 Video Cards

**Video Card (`AppVideoCard`):** Card displaying a clip thumbnail, metadata, and action row. Thumbnail area is 9:16 aspect ratio with `BoxFit.cover`. Duration badge overlays bottom-right corner (semi-transparent black background, white `textCaptionBold` text). Play icon overlay (48dp, `iconHero`, white, 40% opacity) centered on thumbnail on default state. Metadata row below thumbnail: title (`textBodyMedium`), subtitle badge (`AppStatusBadge`, success variant). Action row: Preview, Download, Share icons (24dp, `iconDefault`, icon-only secondary buttons, 48dp touch target each).

**Rules:**

- Thumbnail: 9:16 vertical video ratio.
- All action buttons are icon-only with semantic labels.
- Cards in a list must have consistent height.

### 9.11 Empty States

**Empty Widget (`AppEmptyWidget`):** Centered layout with optional illustration (SVG or Lottie, max 120×120dp), fallback icon (48dp, `iconHero`, `colorTextTertiary`), title (`textHeading`, 24/600, `colorTextPrimary`), description (`textBodyLarge`, 16/400, `colorTextSecondary`, max 80 chars), and optional primary action (`AppPrimaryButton`).

**Rules:**

- Always centered vertically and horizontally in available space.
- Illustration is preferred over icon.
- Never show empty state and loading simultaneously.

### 9.12 Error States

**Error Widget (`AppErrorWidget`):** Centered layout with error icon (48dp, `iconHero`, `colorError`), title (`textTitle`, 20/600, `colorTextPrimary`), description (`textBody`, 14/400, `colorTextSecondary`), retry button (`AppPrimaryButton`, "Try Again"), and optional secondary action (`AppSecondaryButton` or text link).

**Rules:**

- Always centered vertically and horizontally in available space.
- Error widget replaces the content area entirely — not shown alongside content.
- Retry is always the primary action.

### 9.13 Loading States

**Skeleton Card (`AppSkeletonCard`):** Card-shaped placeholder with shimmer animation. Base color: `colorSkeleton`. Highlight color: `colorSkeletonHighlight`. Shimmer sweep: left-to-right, 1.5s loop, linear easing.

**Skeleton Text (`AppSkeletonText`):** Single line placeholder, 60% width of parent, same shimmer animation.

**Skeleton Thumbnail (`AppSkeletonThumbnail`):** 9:16 aspect ratio container, same shimmer animation.

**Full Loader (`AppLoader`):** Centered spinner (`colorPrimary`, 40dp diameter) with optional message below (`textBody`, `colorTextSecondary`). No blocking overlay by default.

**Loading Overlay (`AppLoadingOverlay`):** Same spinner + message, overlaid on semi-transparent scrim (`colorOverlay`). Blocks interaction. Dismissable only if specified.

**Rules:**

- Every screen that loads data must show skeleton before content.
- Never show skeleton and content simultaneously.
- Skeleton elements should match the layout of the content they replace (same dimensions).

---

## 10. Motion System

### 10.1 Timing & Curve Reference

| Token         | Duration | Curve                 | Usage                                                    |
| ------------- | -------- | --------------------- | -------------------------------------------------------- |
| `animInstant` | 100ms    | `easeOut`             | Button press, ripple, icon rotation                      |
| `animFast`    | 150ms    | `easeOut`             | Color transitions, opacity changes, elevation changes    |
| `animNormal`  | 250ms    | `easeInOut`           | Icon rotation, small element moves, bottom sheet dismiss |
| `animSlow`    | 350ms    | `easeInOut`           | Page transitions, bottom sheet appear, dialog dismiss    |
| `animReveal`  | 500ms    | `easeOut`             | Content appearance, staggered list, hero animation       |
| `animSpring`  | 500ms    | spring (damping: 0.7) | Success burst, celebratory emphasis                      |

### 10.2 Animation Types

#### Page Transition

| Direction      | Duration | Curve            | Animation                                                                 |
| -------------- | -------- | ---------------- | ------------------------------------------------------------------------- |
| Push (forward) | 350ms    | `easeInOutCubic` | Current screen fades out (100ms) → new screen slides up + fade in (350ms) |
| Pop (back)     | 250ms    | `easeInOutCubic` | Current screen slides down + fade out                                     |
| Replace        | 200ms    | `easeOut`        | Cross-fade between screens                                                |

#### Fade

| Context                 | Duration | Curve     |
| ----------------------- | -------- | --------- |
| Element appear          | 150ms    | `easeOut` |
| Element disappear       | 100ms    | `easeIn`  |
| Page cross-fade         | 200ms    | `easeOut` |
| Overlay scrim appear    | 150ms    | `easeOut` |
| Overlay scrim disappear | 100ms    | `easeIn`  |

#### Scale

| Context        | Duration | Curve         | Range      |
| -------------- | -------- | ------------- | ---------- |
| Dialog appear  | 150ms    | `easeOutBack` | 0.95 → 1.0 |
| Dialog dismiss | 100ms    | `easeIn`      | 1.0 → 0.95 |
| Button press   | 100ms    | `easeOut`     | 1.0 → 0.97 |
| Button release | 150ms    | `easeOut`     | 0.97 → 1.0 |
| Card tap       | 150ms    | `easeOut`     | 1.0 → 0.99 |

#### Slide

| Context               | Duration       | Curve            | Direction              |
| --------------------- | -------------- | ---------------- | ---------------------- |
| Bottom sheet appear   | 250ms          | `easeOutCubic`   | Up                     |
| Bottom sheet dismiss  | 200ms          | `easeInCubic`    | Down                   |
| Snackbar appear       | 250ms          | `easeOut`        | Up                     |
| Snackbar dismiss      | 200ms          | `easeIn`         | Down                   |
| Page push             | 350ms          | `easeInOutCubic` | Up (new) / down (back) |
| Staggered list appear | 350ms per item | `easeOut`        | Up, 50ms stagger delay |

#### Progress

| Context                   | Duration       | Curve                           |
| ------------------------- | -------------- | ------------------------------- |
| Determinate progress fill | 300ms per step | `easeOut`                       |
| Indeterminate spinner     | 1s loop        | `linear` (rotation)             |
| Loading pulse             | 1s loop        | `easeInOut` (opacity 0.3 → 1.0) |
| Skeleton shimmer          | 1.5s loop      | `linear` (left-to-right sweep)  |

#### Success / Emphasis

| Context             | Duration    | Curve                       |
| ------------------- | ----------- | --------------------------- |
| Success checkmark   | 500ms       | spring (damping: 0.7)       |
| Processing complete | 500ms pause | — (pause before navigation) |
| Badge appear        | 150ms       | `easeOut`                   |

#### Error

| Context                | Duration | Curve                     |
| ---------------------- | -------- | ------------------------- |
| Input error shake      | 400ms    | 3× horizontal oscillation |
| Error icon appear      | 150ms    | `easeOut`                 |
| Error state transition | 200ms    | `easeOut`                 |

### 10.3 Motion Principles

- **Responsive:** All interactions respond within 100ms (visual feedback).
- **Natural:** Use easing curves that mimic real-world physics. No linear motion for UI.
- **Fast exit:** Dismissals are always faster than appearances (user wants to leave).
- **Staggered:** Lists appear item by item with 50ms offset. Never all at once.
- **Spring sparingly:** Only for celebratory moments. Not for standard navigation.
- **No motion sickness:** No parallax, no 3D transforms, no excessive rotation. Keep it subtle.

### 10.4 Easing Curve Reference

| Curve                | Equation (conceptual)      | Feeling                  |
| -------------------- | -------------------------- | ------------------------ |
| `easeOut`            | Fast start, gradual end    | Natural deceleration     |
| `easeIn`             | Gradual start, fast end    | Natural acceleration     |
| `easeInOut`          | Gradual both ends          | Smooth, professional     |
| `easeOutCubic`       | Cubic deceleration         | Very smooth deceleration |
| `easeInCubic`        | Cubic acceleration         | Very smooth acceleration |
| `easeInOutCubic`     | Cubic both ends            | Prestigious, smooth      |
| `easeOutBack`        | Overshoot target briefly   | Playful emphasis         |
| spring(damping: 0.7) | Oscillate with 70% damping | Bouncy but controlled    |

---

## 11. Responsive Rules

### 11.1 Breakpoints

| Category         | Width Range | Devices                                     |
| ---------------- | ----------- | ------------------------------------------- |
| Phone            | < 600dp     | iPhone SE to 15 Pro Max, Android phones     |
| Tablet Portrait  | 600–840dp   | iPad Mini, iPad, Android tablets (portrait) |
| Tablet Landscape | 840–1024dp  | iPad, iPad Pro (landscape)                  |
| Desktop          | > 1024dp    | macOS, Windows, Web                         |

### 11.2 Per-Screen Adaptations

#### Splash

| Element | Phone    | Tablet          | Desktop         |
| ------- | -------- | --------------- | --------------- |
| Layout  | Centered | Centered        | Centered        |
| Spacing | Default  | Expanded (1.5×) | Expanded (1.5×) |

#### Home

| Element            | Phone                           | Tablet Portrait         | Tablet Landscape / Desktop  |
| ------------------ | ------------------------------- | ----------------------- | --------------------------- |
| Horizontal gutters | 24dp                            | 32dp                    | 40dp (centered, max 1200dp) |
| Recent Projects    | Horizontal scroll (1.5 visible) | 2-column grid           | 3-column grid               |
| FAB                | Bottom-right                    | Hidden (app bar button) | Hidden (sidebar button)     |
| Quick Actions      | Full-width compact              | Full-width normal       | Full-width normal           |

#### New Project

| Element         | Phone                   | Tablet / Desktop          |
| --------------- | ----------------------- | ------------------------- |
| Layout          | Full-width form         | Centered card (max 480dp) |
| Generate button | Fixed bottom            | Inline at card bottom     |
| Chips           | Equal-width fill layout | Auto-width centered       |

#### Processing

| Element        | Phone         | Tablet / Desktop          |
| -------------- | ------------- | ------------------------- |
| Progress card  | Full-width    | Centered card (max 480dp) |
| Pipeline steps | Single column | Single column             |

#### Result

| Element        | Phone             | Tablet         | Desktop        |
| -------------- | ----------------- | -------------- | -------------- |
| Clip grid      | 1 column          | 2 columns      | 3 columns      |
| Download All   | App bar icon      | App bar button | App bar button |
| Generate Again | Full-width button | Compact button | Compact button |

#### Clip Detail

| Element     | Phone            | Tablet                   | Desktop            |
| ----------- | ---------------- | ------------------------ | ------------------ |
| Video width | Full-width       | 60% (landscape)          | Max 480dp centered |
| Info layout | Stacked vertical | Side-by-side (landscape) | Side-by-side       |
| Actions     | Fixed bottom     | Inline below info        | Inline below info  |

#### Settings

| Element | Phone           | Tablet / Desktop          |
| ------- | --------------- | ------------------------- |
| Layout  | Full-width list | Centered card (max 480dp) |

### 11.3 Landscape Orientation

- **Home:** Same as portrait. Horizontal cards scroll naturally.
- **New Project:** Form remains centered. Generate button fixed bottom (may need compact mode for short landscape heights).
- **Processing:** Compact progress ring (smaller). Pipeline steps in 2 columns if space allows.
- **Result:** Minimum 2 columns on landscape phone.
- **Clip Detail:** Video left (60%), info right (40%). No scrolling needed.
- **Settings:** Same as portrait.

### 11.4 Responsive Grid Rules

- Phone: 4-column grid, 24dp gutters
- Tablet: 8-column grid, 32dp gutters
- Desktop: 12-column grid, 40dp gutters, max 1200dp content width

---

## 12. Accessibility

### 12.1 WCAG AA Compliance Targets

| Requirement                       | Target                   | How It's Met                                                      |
| --------------------------------- | ------------------------ | ----------------------------------------------------------------- |
| Contrast ratio (normal text)      | ≥ 4.5:1                  | All text tokens designed to meet ≥ 4.5:1 against their background |
| Contrast ratio (large text ≥24px) | ≥ 3:1                    | Headings use `textHeading` (24px) and above                       |
| Non-text contrast                 | ≥ 3:1                    | Icons, borders, focus indicators                                  |
| Touch targets                     | ≥ 48×48dp                | All interactive elements at minimum `touchMin`                    |
| Focus visible                     | Yes                      | 2dp `colorPrimary` focus indicator on all interactive             |
| Screen reader labels              | All interactive elements | `Semantics` on every widget                                       |

### 12.2 Contrast Ratios

| Foreground            | Background                | Light Ratio | Dark Ratio | Pass AA |
| --------------------- | ------------------------- | ----------- | ---------- | ------- |
| `colorPrimary` text   | `colorSurface`            | 4.8:1       | 4.8:1      | ✓       |
| `colorOnPrimary` text | `colorPrimary` background | 4.8:1       | 4.8:1      | ✓       |
| `colorTextPrimary`    | `colorSurface`            | 16:1        | 14:1       | ✓       |
| `colorTextSecondary`  | `colorSurface`            | 8:1         | 7:1        | ✓       |
| `colorTextTertiary`   | `colorSurface`            | 5:1         | 4.5:1      | ✓       |
| `colorError` text     | `colorSurface`            | 5:1         | 4.8:1      | ✓       |
| `colorSuccess` text   | `colorSurface`            | 5.5:1       | 5:1        | ✓       |
| `colorTextPrimary`    | `colorBackground`         | 15:1        | 13:1       | ✓       |
| `colorTextSecondary`  | `colorBackground`         | 7:1         | 6:1        | ✓       |

### 12.3 Semantic Label Guidelines

Every interactive element must have a clear, descriptive semantic label for screen readers. Labels should:

- Describe the element's function, not its appearance.
- Include the element's state (selected, disabled, active).
- Use natural language phrases ("Create new clip", not "New clip button").
- For dynamic elements (progress bars), announce the current value as it changes.

### 12.4 Touch Target Minimums

| Token         | Value   | Elements                                |
| ------------- | ------- | --------------------------------------- |
| `touchMin`    | 48×48dp | All interactive elements (WCAG minimum) |
| `touchButton` | 56×56dp | Primary and secondary buttons           |
| `touchChip`   | 32×36dp | Chips (minimum height)                  |
| `touchCard`   | 72dp    | Tappable cards (minimum height)         |

### 12.5 Dynamic Font Scaling

- Application supports system font scaling from 100% to 200%.
- Tested at 150% scaling: no text truncation, no layout breakage.
- Cards and containers use flexible heights (no hardcoded constraints).
- `textCaption` (12px) is the minimum — may scale to 24px at 200%.
- Wrap specific elements in `MediaQuery.withNoTextScale` only if they break at extreme scales (last resort).

### 12.6 Focus Order

Natural component order equals focus order:

1. AppBar (back → title → actions)
2. Body content top-to-bottom
3. Fixed bottom CTA (last)

### 12.7 Screen Reader Announcement Patterns

- Screen loaded: describe current screen and primary data state.
- Processing step changed: announce step name and percentage.
- Processing complete: announce completion and result count.
- Download started / completed: announce file name and status.
- Error occurred: announce error type and suggested action.
- Empty state: announce empty state and available action.

---

## 13. Theme Extension Planning

### 13.1 Extension Classes

The design tokens are organized into five `ThemeExtension` classes. Each class contains only the tokens for its category.

| Class                    | Tokens Included                    |
| ------------------------ | ---------------------------------- |
| `AppColorExtension`      | All 18 color tokens                |
| `AppSpacingExtension`    | All 10 spacing tokens              |
| `AppRadiusExtension`     | All 5 radius tokens                |
| `AppTypographyExtension` | All 10 typography tokens           |
| `AppAnimationExtension`  | 6 duration tokens + 4 curve tokens |

### 13.2 Future Extension Pattern

To add a new token to any category:

1. Add a new field to the corresponding `ThemeExtension` class.
2. Provide light and dark values (colors) or single values (spacing, radius, etc.).
3. Update this document with the new token.
4. Add the token to `ui.md` if used in component specifications.

### 13.3 No Extension for Elevation, Icons, or Opacity

| Group        | Reason for no ThemeExtension                                                                                                                                                                    |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Elevation    | Elevation is applied via BoxShadow directly in component widgets. BoxShadow is not a ThemeExtension-compatible type in Flutter. Elevation tokens remain as constants or component-level values. |
| Icons        | Icon references (IconData) are not theme-able. They are selected per-component. The icon library (Lucide) is fixed.                                                                             |
| Opacity      | Opacity values are used inline within component animations and disabled states. No ThemeExtension needed.                                                                                       |
| Border width | Border width values are used inline within component decoration. No ThemeExtension needed.                                                                                                      |

### 13.4 Light and Dark Theme Data

Each `AppColorExtension` requires two instances: one for light mode, one for dark mode. All other extensions (spacing, radius, typography, animation) have identical values in both modes.

---

## 14. Design Do & Don't

### 14.1 Color

| Do                                                       | Don't                                                                    |
| -------------------------------------------------------- | ------------------------------------------------------------------------ |
| Use `colorPrimary` for one element per screen            | Don't use `colorPrimary` for body text, card backgrounds, or decorations |
| Use `colorTextPrimary` for all body text                 | Don't use `colorPrimary` or any accent color for body text               |
| Use `colorError` only for errors and destructive actions | Don't use `colorError` for warnings, info, or decorative elements        |
| Use `colorSuccess` only for positive confirmation        | Don't use `colorSuccess` for neutral or informational states             |
| Use `colorSurfaceVariant` for unselected, passive states | Don't use `colorSurfaceVariant` for interactive element backgrounds      |
| Use `colorOverlay` consistently on all modals            | Don't use different overlay opacities per modal type                     |

### 14.2 Typography

| Do                                                       | Don't                                                       |
| -------------------------------------------------------- | ----------------------------------------------------------- |
| Use `textBodyMedium` (14/500) for button labels          | Don't use `textBody` (14/400) for buttons — too light       |
| Use `textCaption` (12/400) for all badges and timestamps | Don't use `textBody` sizes for badge text                   |
| Use sentence case for all labels ("Generate clips")      | Don't use all-caps for any UI text except badges            |
| Use a single typeface (Inter) throughout                 | Don't mix typefaces for emphasis — use weight instead (600) |
| Use negative tracking for headings 18px+                 | Don't apply letter-spacing to body text                     |

### 14.3 Spacing & Layout

| Do                                                        | Don't                                                   |
| --------------------------------------------------------- | ------------------------------------------------------- |
| Use consistent `spacingMd` (16dp) card padding everywhere | Don't vary card padding between screens                 |
| Use `spacingXxl` (32dp) between sections                  | Don't use inconsistent gaps between sections            |
| Use `spacingSm` (12dp) between related form elements      | Don't use more than `spacingSm` between label and input |
| Keep primary CTA visible without scrolling                | Don't put the primary CTA behind scroll content         |
| Use full-width buttons on phone                           | Don't use compact buttons on phone — hard to tap        |

### 14.4 Components

| Do                                               | Don't                                                           |
| ------------------------------------------------ | --------------------------------------------------------------- |
| Use one primary button per screen                | Don't place two primary buttons on one screen                   |
| Use bottom sheets for non-destructive selections | Don't use dialogs for selections — use bottom sheets            |
| Use dialogs only for destructive confirmations   | Don't use dialogs for informational messages — use snackbars    |
| Use cards for content presentation               | Don't use tables for content presentation (settings excepted)   |
| Use skeleton screens for all loading states      | Don't use spinners for content loading — use skeletons          |
| Make all interactive elements ≥ 48×48dp          | Don't place small tap targets (e.g., icon-only without padding) |

### 14.5 Icons

| Do                                    | Don't                                          |
| ------------------------------------- | ---------------------------------------------- |
| Use Lucide icons only                 | Don't mix icon libraries                       |
| Use outlined icons only (2px stroke)  | Don't use filled icons                         |
| Pair icons with text in buttons       | Don't use icon-only buttons                    |
| Provide semantic labels for all icons | Don't leave icons without screen reader labels |

### 14.6 Motion

| Do                                                           | Don't                                              |
| ------------------------------------------------------------ | -------------------------------------------------- |
| Use faster dismissal than appearance                         | Don't animate dismissals slower than appearances   |
| Use `easeOut` for elements entering the screen               | Don't use linear easing for UI motion              |
| Use spring only for celebratory moments                      | Don't use spring animation for standard navigation |
| Keep page transitions consistent (same duration, same curve) | Don't vary transition timing per screen            |

### 14.7 Responsive

| Do                                                             | Don't                                                            |
| -------------------------------------------------------------- | ---------------------------------------------------------------- |
| Use 24dp gutters on phone, 32–40dp on tablet/desktop           | Don't use fixed widths that break on smaller screens             |
| Use single column on phone, multiple columns on larger screens | Don't show single-column on desktop with huge whitespace         |
| Adapt FAB visibility (show on phone, hide on tablet/desktop)   | Don't show a FAB on desktop where keyboard navigation is primary |

### 14.8 Accessibility

| Do                                                 | Don't                                                    |
| -------------------------------------------------- | -------------------------------------------------------- |
| Label every interactive element for screen readers | Don't leave any interactive element unlabeled            |
| Ensure touch targets ≥ 48×48dp                     | Don't reduce touch target size for visual compactness    |
| Support font scaling up to 200%                    | Don't hardcode text sizes that truncate at larger scales |
| Provide visible focus indicators                   | Don't remove focus outlines                              |

---

## 15. Future Expansion

### 15.1 Token System Extensibility

The design token system is additive. New tokens can be introduced without breaking existing usage:

- **Colors:** Add a new field to `AppColorExtension` + provide light/dark hex values.
- **Spacing:** Add a new field to `AppSpacingExtension`.
- **Radius:** Add a new field to `AppRadiusExtension`.
- **Typography:** Add a new field to `AppTypographyExtension` (new `TextStyle`).
- **Animation:** Add a new field to `AppAnimationExtension` (new duration + curve pair).

### 15.2 Future Features and Their Design System Impact

| Feature               | Design System Impact                                                                                                    |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Timeline Editor**   | New color tokens for track/slider/playhead. New radius tokens for waveform segments. New animation for scrubbing.       |
| **Subtitle Editor**   | New typography tokens for subtitle preview. New color tokens for text style chips. New component: `AppTextStylePicker`. |
| **AI Settings**       | New color tokens for model tiers (lightning/balanced/quality). New component: `AppSlider` for sensitivity.              |
| **History**           | No new tokens. Uses existing `AppVideoCard` and `AppSection`.                                                           |
| **Team Workspace**    | New color tokens for user avatars. New component: `AppAvatar`. New data-display tokens for multi-user context.          |
| **Profile / Auth**    | New component: `AppAvatar`. No new tokens.                                                                              |
| **Bottom Navigation** | No new tokens. Existing colors used. New component: `AppNavigationBar`.                                                 |

### 15.3 Component Extensibility

- `AppCard` accepts any child widget — new features add new card content without modifying the component.
- `AppVideoCard` has action slots — new features add more icon buttons to the action row.
- `AppScaffold` has optional `bottomCta` — new features without a CTA work by passing `null`.
- `AppBottomSheet` accepts a dynamic list of children — new options are just list items.

### 15.4 Asset Pipeline Extensibility

- SVGs and Lottie files are stored in `assets/` directory organized by type.
- Future assets follow the same path convention: `assets/illustrations/`, `assets/animations/`, `assets/icons/`.
- Image optimization (WebP conversion, compression) is handled at build time.

---

## 16. Token Naming Convention

### 16.1 General Rules

- All tokens use **camelCase** with a **category prefix**.
- Categories: `color`, `spacing`, `radius`, `elevation`, `anim`, `icon`, `opacity`, `border`, `touch`, `text`.
- Token names describe purpose, not appearance. `colorPrimary` not `colorPurple`.
- State suffixes: `Default`, `Pressed`, `Focused`, `Disabled`, `Loading`, `Selected`, `Unselected`.
- Semantic suffixes: `Primary`, `Secondary`, `Tertiary`, `Error`, `Success`, `Warning`, `Info`.

### 16.2 Color Token Naming

| Pattern                        | Examples                                                                       |
| ------------------------------ | ------------------------------------------------------------------------------ |
| `color` + `Role`               | `colorPrimary`, `colorSecondary`, `colorError`, `colorSuccess`, `colorWarning` |
| `color` + `Role` + `Container` | `colorPrimaryContainer`                                                        |
| `color` + `On` + `Role`        | `colorOnPrimary`                                                               |
| `color` + `Surface`            | `colorSurface`, `colorSurfaceVariant`                                          |
| `color` + `Text` + `Priority`  | `colorTextPrimary`, `colorTextSecondary`, `colorTextTertiary`                  |
| `color` + `Element`            | `colorBorder`, `colorDivider`, `colorOverlay`, `colorShadow`                   |
| `color` + `Function`           | `colorSkeleton`, `colorSkeletonHighlight`                                      |

### 16.3 Spacing Token Naming

`spacing` + `Size`: `spacingXxs`, `spacingXs`, `spacingSm`, `spacingMd`, `spacingLg`, `spacingXl`, `spacingXxl`, `spacingXxxl`, `spacingHuge`, `spacingMassive`.

### 16.4 Radius Token Naming

`radius` + `Size`: `radiusSm`, `radiusMd`, `radiusLg`, `radiusXl`, `radiusFull`.

### 16.5 Elevation Token Naming

`elevation` + `Level`: `elevationNone`, `elevationSm`, `elevationMd`, `elevationLg`, `elevationXl`, `elevationDialog`.

### 16.6 Typography Token Naming

`text` + `Role`: `textCaption`, `textCaptionBold`, `textBody`, `textBodyMedium`, `textBodyLarge`, `textSubhead`, `textTitle`, `textHeading`, `textH2`, `textH1`.

### 16.7 Animation Token Naming

| Pattern          | Examples                                                                        |
| ---------------- | ------------------------------------------------------------------------------- |
| `anim` + `Speed` | `animInstant`, `animFast`, `animNormal`, `animSlow`, `animReveal`, `animSpring` |

### 16.8 Icon Token Naming

`icon` + `Size`: `iconInline`, `iconSmall`, `iconDefault`, `iconLarge`, `iconHero`.

### 16.9 Opacity Token Naming

`opacity` + `Context`: `opacityDisabled`, `opacityHint`, `opacityScrim`, `opacityPressed`, `opacitySubtext`.

### 16.10 Border Width Token Naming

`border` + `Thickness`: `borderNone`, `borderThin`, `borderRegular`.

### 16.11 Touch Target Token Naming

`touch` + `Context`: `touchMin`, `touchButton`, `touchChip`, `touchCard`.

---

## 17. Visual Hierarchy

### 17.1 Priority Levels

| Level          | Description                                                          | Examples                                                   | Token Usage                                                                                    |
| -------------- | -------------------------------------------------------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| **Primary**    | The single most important element on screen. User's first attention. | Primary CTA button, screen title, hero heading             | `colorPrimary`, `textTitle` or `textHeading`, largest size, highest emphasis                   |
| **Secondary**  | Supporting actions and information. User's second attention.         | Section headings, card titles, secondary buttons, metadata | `colorTextPrimary`, `textSubhead` or `textBodyMedium`, `colorPrimary` only for selected states |
| **Supporting** | Context, descriptions, additional details. Read when needed.         | Helper text, description paragraphs, timestamp labels      | `colorTextSecondary`, `textBody` or `textBodyLarge`                                            |
| **Tertiary**   | Lowest emphasis. Visual noise reduction.                             | Placeholders, disabled text, captions, legal text          | `colorTextTertiary`, `textCaption`                                                             |
| **Disabled**   | Unavailable interaction. Reduced visibility.                         | Disabled buttons, disabled chips, disabled fields          | `opacityDisabled` (38%), `colorTextTertiary`                                                   |
| **Focus**      | Active keyboard or screen reader focus.                              | Focus ring on text fields, focus indicator on buttons      | 2px `colorPrimary` border, `elevationLg`                                                       |

### 17.2 Priority Rules

- Each screen has exactly **one** primary element. Never two.
- Primary elements use `colorPrimary` sparingly — one element per screen.
- Secondary elements never use saturated colors (`colorPrimary`, `colorSecondary`) for their background.
- Supporting elements never use bold weight (600+).
- Tertiary elements are the smallest size (`textCaption`, 12px) and lightest color (`colorTextTertiary`).
- Disabled elements never appear without a visual explanation (contextual text or tooltip).

### 17.3 Visual Weight Formula

Priority = Size (px) × Weight Multiplier × Color Contrast

| Level      | Typical Size      | Weight            | Color Contrast (vs `colorSurface`) | Weight Multiplier |
| ---------- | ----------------- | ----------------- | ---------------------------------- | ----------------- |
| Primary    | 20–24px           | 600               | 16:1 (`colorTextPrimary`)          | 1.0               |
| Secondary  | 14–18px           | 500               | 16:1 (`colorTextPrimary`)          | 0.75              |
| Supporting | 14–16px           | 400               | 8:1 (`colorTextSecondary`)         | 0.5               |
| Tertiary   | 12px              | 400               | 5:1 (`colorTextTertiary`)          | 0.3               |
| Disabled   | (inherits parent) | (inherits parent) | (inherits parent) × 0.38 opacity   | —                 |

---

## 18. Component Composition Rules

### 18.1 Card Composition

```
┌─────────────────────────────┐
│  Card                        │  ← Container: colorSurface, radiusMd, elevationSm
│  ┌───────────────────────┐   │
│  │  Header (optional)     │  │  ← textSubhead or textBodyMedium
│  │  ───────────────────── │  │  ← optional divider
│  │  Body (required)       │  │  ← Main content: text, chips, list
│  │  ───────────────────── │  │  ← optional divider
│  │  Footer (optional)     │  │  ← Actions: icon row, button, metadata
│  └───────────────────────┘   │
└─────────────────────────────┘
```

**Rules:**

- Padding: `spacingMd` (16dp) all sides for content.
- Between header/body/footer: `spacingSm` (12dp).
- Dividers between sections: optional 1px `colorBorder`.
- Footers containing actions: `spacingSm` top gap from body.

### 18.2 Video Card Composition

```
┌─────────────────────────────┐
│  Video Card                  │  ← Container: colorSurface, radiusMd
│  ┌───────────────────────┐   │
│  │  Thumbnail (9:16)      │  │  ← radiusMd top-left and top-right
│  │  Duration badge [00:45]│  │  ← bottom-right overlay
│  │  Play overlay ▶️       │  │  ← center overlay on default state
│  └───────────────────────┘   │
│  ┌───────────────────────┐   │
│  │  Metadata              │  │  ← spacingSm top gap
│  │  Clip Title            │  │  ← textBodyMedium
│  │  Subtitles ✓           │  │  ← AppStatusBadge (success)
│  │  Metadata row          │  │  ← textBody, colorTextSecondary
│  └───────────────────────┘   │
│  ┌───────────────────────┐   │
│  │  Actions               │  │  ← spacingSm top gap
│  │  [Preview] [Download]  │  │  ← icon-only buttons, 48dp touch
│  │            [Share]     │  │
│  └───────────────────────┘   │
└─────────────────────────────┘
```

### 18.3 Progress Card Composition

```
┌─────────────────────────────┐
│  Progress Card               │  ← Container: colorSurface, radiusMd
│  ┌───────────────────────┐   │
│  │  Progress Ring         │  │  ← Center: determinate circular, animated
│  │        45%             │  │  ← Label in center: textH2, colorPrimary
│  └───────────────────────┘   │
│  ┌───────────────────────┐   │
│  │  Current Step Label    │  │  ← textBodyLarge, spacingSm below ring
│  │  Estimated Time        │  │  ← textBody, colorTextSecondary
│  └───────────────────────┘   │
│  ┌───────────────────────┐   │
│  │  Pipeline Steps        │  │  ← spacingSm top gap
│  │  ● Downloading         │  │  ← Active: colorPrimary, pulsing dot
│  │  ○ Transcribing        │  │  ← Pending: colorTextTertiary, circle
│  │  ✓ Detecting Highlights│  │  ← Done: colorSuccess, check icon
│  └───────────────────────┘   │
│  ┌───────────────────────┐   │
│  │  Cancel Button         │  │  ← AppSecondaryButton (destructive)
│  └───────────────────────┘   │
└─────────────────────────────┘
```

### 18.4 Dialog Composition

```
┌─────────────────────────────┐
│  Scrim overlay               │  ← colorOverlay
│  ┌───────────────────────┐   │
│  │  Dialog                │  │  ← Centered, colorSurface, radiusLg, elevationDialog
│  │                        │  │
│  │  ⚠️ Icon (optional)    │  │  ← Centered, iconHero, colorWarning/Error
│  │                        │  │
│  │  Title                 │  │  ← textTitle, centered
│  │                        │  │
│  │  Message               │  │  ← textBody, centered, colorTextSecondary
│  │                        │  │
│  │  ──────────────────    │  │  ← spacingMd gap
│  │                        │  │
│  │  [ Cancel ] [ Confirm ]│  │  ← Secondary + Primary, side by side
│  └───────────────────────┘   │
└─────────────────────────────┘
```

### 18.5 Bottom Sheet Composition

```
┌─────────────────────────────┐
│  Scrim overlay               │  ← colorOverlay
│  ┌───────────────────────┐   │
│  │  ─────────────         │  │  ← Drag handle (center, 32×4, colorBorder, pill)
│  │                        │  │
│  │  Title                 │  │  ← textSubhead, spacingLg top padding
│  │                        │  │
│  │  ── Action Item 1      │  │  ← 56dp height, icon + label
│  │  ── Action Item 2      │  │  ← Optional trailing chevron
│  │  ── Action Item 3      │  │
│  │  ...                   │  │
│  │                        │  │
│  └───────────────────────┘   │
└─────────────────────────────┘
```

### 18.6 Empty State Composition

```
┌─────────────────────────────┐
│  (Centered vertically)       │
│  ┌───────────────────────┐   │
│  │  Illustration (120dp)  │  │  ← SVG or Lottie, or icon fallback
│  │                        │  │
│  │  Title                 │  │  ← textHeading, colorTextPrimary
│  │                        │  │
│  │  Description           │  │  ← textBodyLarge, colorTextSecondary
│  │                        │  │
│  │  [ Primary Action ]    │  │  ← AppPrimaryButton (optional)
│  │  Secondary Action      │  │  ← AppSecondaryButton (optional)
│  └───────────────────────┘   │
└─────────────────────────────┘
```

### 18.7 Composition Rules

- **Header** is always optional. If absent, the body content begins at the top padding.
- **Footer** is always optional. If absent, the card ends after body.
- **Dividers** between sections are optional. Use only when sections contain distinct content types.
- **Actions** are always at the bottom of the component (footer).
- **Metadata** is always after the primary visual (image, video, icon) and before actions.
- Never place actions above content in a card.

---

## 19. Layout Rules

### 19.1 Maximum Content Width

- Phone: full screen width (safe area insets)
- Tablet: 840dp maximum content width, centered
- Desktop: 1200dp maximum content width, centered

### 19.2 Safe Areas

- Top safe area: respected for device notch/status bar.
- Bottom safe area: respected for home indicator.
- Left/right safe area: respected on notched devices.
- Content should extend into safe areas only for background colors (`colorBackground`), not for content or interactive elements.
- Primary CTA bottom position: safe area bottom + `spacingMd` (16dp).

### 19.3 Page Padding

| Breakpoint | Horizontal Padding   | Top Padding (below AppBar) | Bottom Padding (above CTA) |
| ---------- | -------------------- | -------------------------- | -------------------------- |
| Phone      | 24dp (`spacingXl`)   | 24dp (`spacingXl`)         | 24dp (`spacingXl`)         |
| Tablet     | 40dp (`spacingXxxl`) | 24dp (`spacingXl`)         | 24dp (`spacingXl`)         |
| Desktop    | 40dp (`spacingXxxl`) | 32dp (`spacingXxl`)        | 24dp (`spacingXl`)         |

### 19.4 Section Spacing

| Between                        | Gap                 |
| ------------------------------ | ------------------- |
| Section heading and first item | 12dp (`spacingSm`)  |
| Between two sections           | 32dp (`spacingXxl`) |
| Section and divider            | 8dp (`spacingXs`)   |
| Last section and bottom CTA    | 24dp (`spacingXl`)  |

### 19.5 Card Spacing

| Context                            | Gap                 |
| ---------------------------------- | ------------------- |
| Between cards in horizontal scroll | 12dp (`spacingSm`)  |
| Between cards in vertical list     | 32dp (`spacingXxl`) |
| Between cards in grid (both axes)  | 12dp (`spacingSm`)  |
| Card inner padding (all sides)     | 16dp (`spacingMd`)  |

### 19.6 Grid Rules

| Breakpoint | Columns | Gutter | Margin                      |
| ---------- | ------- | ------ | --------------------------- |
| Phone      | 4       | 24dp   | 24dp                        |
| Tablet     | 8       | 32dp   | 32dp                        |
| Desktop    | 12      | 40dp   | 40dp (centered, max 1200dp) |

### 19.7 Scrollable Areas

- Body content uses `SingleChildScrollView` for simple layout, `CustomScrollView` with slivers for complex layouts (Home screen).
- Never nest `ListView` inside `ListView` or `SingleChildScrollView` inside `ListView`.
- Lists should use `ListView.builder` for performance.
- Never use `Column` + `SingleChildScrollView` for long lists — use `ListView`.

### 19.8 Sticky Actions

- Primary CTA (when fixed at bottom) is positioned above the bottom safe area.
- Fixed bottom CTA has a `spacingXl` (24dp) padding top and bottom.
- Fixed bottom CTA should have a subtle top border (1px `colorBorder`) or shadow to separate from content.
- Fixed bottom CTA never overlaps with the last content item — content bottom padding accounts for it.

---

## 20. Asset Standards

### 20.1 Logo

- Style: Monochromatic SVG. Single color, responds to theme.
- Light mode color: `colorTextPrimary` (`#1A1A2E`).
- Dark mode color: `colorTextPrimary` (`#F5F5F7`).
- Splash screen size: 48dp height.
- App bar representation: text-only ("Klip Clipper") in `textSubhead` weight. No icon required.

### 20.2 Illustrations

- Style: Monochromatic line-art, 2px stroke, rounded corners.
- Max color count: 1 color (`colorTextTertiary` or `colorPrimary`).
- Max size: 120×120dp (phone), 160×160dp (tablet).
- Format: SVG (preferred), Lottie `.json` for animated variants.
- No complex gradients.
- No human faces (culture-agnostic).
- SVG attribute: use `currentColor` for stroke/fill to inherit theme color.

### 20.3 SVG Standards

- Optimized (remove unused viewBox elements, no embedded raster images).
- Use `currentColor` for stroke and fill.
- Default package: `flutter_svg`.

### 20.4 Lottie Standards

- File size limit: < 50KB per animation.
- Loop: only if appropriate (e.g., processing animation). Success animations play once.
- Default package: `lottie`.

### 20.5 Image Standards

- Thumbnails: WebP format, max 240×426dp (9:16 at 240px width).
- No raster images except user-generated content (none in MVP).

### 20.6 Thumbnail Standards

- Aspect ratio: 9:16 (vertical video, clip output).
- Fit: `BoxFit.cover`.
- Fallback: `colorSurfaceVariant` background with centered `Film` icon (48dp, `colorTextTertiary`).

### 20.7 Avatar (Future)

- Size: 40dp diameter.
- Fallback: user initials on `colorPrimaryContainer` background.
- No avatar in MVP.

### 20.8 App Icon

- Style: Minimal, single symbol (scissors or film clipper), gradient background (primary → secondary).
- Platform sizes: iOS (1024×1024 inclusive), Android (adaptive: 108dp / 432px).
- Symbol: within 60% of icon bounds, centered.
- No text on app icon.

### 20.9 Splash Logo

- 48dp height, monochromatic SVG.
- Same as app logo, centered on splash screen.
- No animation on splash logo.

---

## 21. Theme Scalability

### 21.1 Adding a New Theme

To add a new theme (e.g., brand theme, seasonal theme, enterprise theme):

1. Create a new `ThemeData` instance that references the same `ThemeExtension` classes.
2. Provide light and dark color palettes for all 18 color tokens.
3. All other tokens (spacing, radius, typography, animation) remain unchanged.
4. Register the theme in the app's theme provider.
5. Ensure all color tokens pass WCAG AA contrast checks for the new palette.

### 21.2 Brand Themes (Future)

Different color schemes for branded deployments:

- Light and dark palettes for each brand.
- All brands share the same spacing, radius, typography, elevation, and motion tokens.
- Only the 18 color tokens change per brand.
- `colorPrimary` and `colorSecondary` define brand identity.

### 21.3 Seasonal Themes (Future)

- Limited-time color variations (holiday, event).
- Apply via a `ThemeMode`-like selector in settings.
- Deprecate after the season ends — remove from codebase.

### 21.4 Enterprise Themes (Future)

- Accessibility-focused high-contrast theme.
- Increase contrast ratios: all text ≥ 7:1.
- Increase touch targets: `touchMin` to 56dp.
- Remove opacity on disabled states (use full opacity with pattern overlay instead).

### 21.5 Theme Fallback Chain

When resolving a color value, the application uses:

1. Active theme (light/dark/brand)
2. If a token is missing from the active theme → M3 `ColorScheme` fallback
3. If M3 fallback missing → hardcoded default value from token definition

---

## 22. Documentation Rules

### 22.1 Adding a New Design Token

1. Determine which token category it belongs to (color, spacing, radius, etc.).
2. Follow the naming convention (§16).
3. Add the token to this `design_system.md` document in the appropriate section.
4. Add a table row with all required fields (purpose, value, usage, do, don't).
5. Add usage references to `ui.md` if the token is used in component or screen specifications.
6. Mark the token with version `1.x.0` where `x` is incremented.

### 22.2 Deprecating a Token

1. Mark the token as **DEPRECATED** in this document with a clear deprecation notice.
2. Provide the replacement token name and migration date.
3. Leave the token in the `ThemeExtension` class for one full version cycle.
4. Remove the token from `ThemeExtension` in the next major version.
5. Update `ui.md` to remove all references to the deprecated token.
6. Deprecation notice format:

```
> **DEPRECATED** in v1.1.0 — Use `colorPrimaryContainer` instead. Will be removed in v2.0.0.
```

### 22.3 Versioning

| Version       | Change Type    | Example                                     |
| ------------- | -------------- | ------------------------------------------- |
| 1.0.0 → 1.1.0 | Minor addition | New color token added                       |
| 1.0.0 → 1.2.0 | Minor addition | New component standard added                |
| 1.0.0 → 2.0.0 | Major change   | Token deprecated and removed                |
| 1.0.0 → 1.0.1 | Patch          | Token value corrected (contrast adjustment) |

Version history is maintained at the bottom of this document.

### 22.4 Document Maintenance Rules

- This document is the **single source of truth** for the visual language.
- Every change to the visual language must be reflected here before implementation.
- `ui.md` is the **component and screen specification** — it references tokens defined here.
- When updating a token value, update this document first, then `ui.md`.
- When adding a new component standard, add it to §9 (this document) and to the Component Catalog in `ui.md`.
- Keep tables consistent: same column format, same terminology, same token names.

### 22.5 Consistency Checks

Before finalizing any design system change, verify:

- Token names match the naming convention (§16).
- All values are correct for both light and dark modes (colors).
- Contrast ratios meet WCAG AA minimums.
- `ui.md` references are updated.
- The change is versioned in this document's history.

---

## Version History

| Version | Date       | Changes                                                                                                                                                                  |
| ------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1.0.0   | 2026-07-03 | Initial release. 18 color tokens, 10 spacing tokens, 5 radius tokens, 6 elevation tokens, 10 typography tokens, 6 animation tokens, 15 component standards, 22 sections. |

---

> **End of Design System.**
>
> This document is the single source of truth for the AI YouTube Clipper visual language. Every design decision, token, and rule is documented to production detail. All values are identical to the tokens used in `ui.md` (screen and component specifications).
>
> **Next:** Implement design tokens as Flutter `ThemeExtension` classes. Build components per §9 standards. Assemble screens per `ui.md` specifications.
