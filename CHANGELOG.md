# KickNotes changelog

## 0.3.0

### Added
- Learned-mechanics system.
- Right-click mechanic rows to mark learned/unlearned.
- Account-wide learning state across alts.
- Dim, Hide and Show modes for learned mechanics.
- Configurable learned-row opacity.
- Learning progress in the reminder header.
- Learning status/instructions in row tooltips.
- Dedicated Learning settings page.
- Reset-current-content and reset-all learning controls with confirmation.
- `/kn learning` command and mode shortcuts.
- Stable generated IDs for every bundled mechanic.

### Release polish
- Empty hidden-learning lists now report that all matching mechanics are learned.
- Saved-variable defaults are migration-safe from 0.2.x.
- All bundled Lua files pass syntax validation.
- Current bundled data contains unique stable IDs for 101 mechanics/reminders.

## 0.2.4
- Added separate MUST STOP severity highlighting.
- Added configurable MUST STOP warning color and row treatment.
- Kept MUST STOP separate from general Essential/Important priority.

## 0.2.3
- Fixed first-render wrapping/height calculation by applying scale before measurement and performing a deferred layout pass.

## 0.2.2
- Made friendly dispels debuff-type aware.
- Removed Priest-specific instructional wording from generic mechanic notes.

## 0.2.1
- Added Full/Mini toggle directly to the reminder window.

## 0.2.0
- Major settings and UI pass with tabs, priority filters, auto-zip, separate Full/Mini styling, boss highlighting, max-height scrolling and preview controls.
