# C# UI Guide

## 1. Purpose

Defines UI requirements for WPF applications. Claude follows this guide when building UI unless the user specifies otherwise.

"I" and "me" in this guide refers to the human user.

---

## 2. Configuration Persistence

If a user can resize, move, collapse, or configure any UI element, that configuration MUST survive application restart.

When implementing any UI element with user-configurable state:
1. Save automatically when the user changes it
2. Restore automatically when the application starts
3. Store in AppSettings with a sensible default value

| UI Element | Properties to Persist |
|------------|----------------------|
| Resizable panels | Width/Height |
| Splitters/Dividers | Position |
| Collapsible sections | Expanded/Collapsed |
| Column widths | Width of each column |
| Tab selection | Active tab index |
| Sort order | Column and direction |
| Filter state | Active filters |
| Window | Size, Position, Maximized state |

---

## 3. System UI Components

Use system UI components whenever functionality is close to desired.

Examples:
- Font selection → system font dialog
- File selection → system file picker
- Color selection → system color picker

---

## 4. Honor All User Choices

When using option dialogs (file picker, font picker, color picker, etc.), ALL user selections MUST be captured and applied.

Example: If a font dialog allows selecting font family, size, and style — all three must be saved and used, not just the family name.

---

## 5. System Look and Feel

UI elements should match native Windows appearance.

- Use system icons (via Shell API)
- Use system colors
- Use default control styles
- Do not use custom styling that deviates from platform visual language

---

## 6. System Theme

All UI must match system theme.

- Use system colors, fonts, and visual styles
- Never hardcode colors
- Use system color resources (e.g., `SystemColors` in WPF) so UI automatically adapts to user's theme

---

## 7. Panels

Every panel must be:
- **Resizable** via splitter/drag handle
- **Collapsible** via toggle button or header click
- **Persistent** — size and collapsed state saved per Section 2

---

## 8. File Browser

Unless specified otherwise, a file browser must show the complete filesystem starting from root (drives on Windows).

The tree should expand to reveal the target location (last used folder or user's home directory by default).

Users should never be restricted to a subset of the filesystem.

Use the reusable file browser control from [ds_csharp_file_browser](https://github.com/dsodol/ds_csharp_file_browser) — a WPF TreeView-based component with system icons and on-demand loading.

---
