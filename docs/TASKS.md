### Evil Banana — macOS (Swift) Tasks & Milestones

#### Scope decisions (locked for MVP)
- **Platform**: SwiftUI, macOS 14+, Apple Silicon only.
- **Model**: `gemini-2.5-flash-image-preview` via GoogleGenerativeAI Swift SDK (fallback REST if needed).
- **Inputs**: Up to 3 uploads at once (drag-drop or picker).
- **Doodle**: Raster overlay with brush/erase/color/undo/redo.
- **Compression**: Auto-compress when >5MB and conform to Gemini max resolution.
- **Exports**: PNG only for MVP.
- **History**: Save runs under `~/Pictures/EvilBanana` (JSON metadata + PNGs).
- **API key**: Stored in Keychain; managed in-app Preferences. Optional one-time import from `.env` `GEMINI_API_KEY` if present.
- **Design**: Dark, high-contrast “evil” aesthetic (black-on-black, neon accents) with tasteful animations.
- **Distribution**: Local/private builds (Developer ID signing can be deferred).

#### Core components (architecture anchors)
- **GenAIClient**: SDK wrapper (auth, content assembly for text-to-image and image-edit, progress, error mapping, rate-limit handling; REST fallback).
- **ImageProcessor**: Import, downscale/compress, color space normalization, doodle compositing.
- **DoodleCanvasView**: Brush engine, eraser, color picker, undo/redo stack, export overlay as PNG with alpha.
- **HistoryManager**: File I/O under `~/Pictures/EvilBanana/runs/<timestamp_id>/`, metadata.json (prompt, inputs, settings), thumbnails.
- **AppState**: Observable app model (prompt, uploads, doodle layer, results, run metadata).

---

## Milestone: MVP — Core App (upload → doodle → prompt → generate → preview → save/swap)

### User stories
- As a user, I can drop up to 3 images, add an optional doodle, enter a prompt, and generate a result using Gemini.
- As a user, I can preview the result, save it as PNG, and swap the result into the base slot for iteration.
- As a user, I can set my API key in Preferences and use the app entirely locally.

### Tasks
1) Project scaffolding
   - Create SwiftUI app target (macOS 14+, Apple Silicon only), bundle id, app icon placeholder.
   - Add GoogleGenerativeAI SDK and any REST fallback dependencies.
   - App lifecycle with `NavigationSplitView` skeleton: sidebar (Assets), center (Canvas tabs), right panel (Prompt/Actions).

2) Preferences & Keychain
   - Build Preferences window with API key field (show/hide toggle), validate with test call.
   - Store/retrieve via Keychain (kSecClassGenericPassword), namespaced to `EvilBanana`.
   - Optional: on first launch, detect `.env` and offer one-time import of `GEMINI_API_KEY`.

3) Assets & uploads (max 3)
   - Drag-drop from Finder and file picker support; show thumbnails in sidebar with drag-reorder and delete.
   - Validate image formats (PNG/JPEG/WEBP/TIFF), convert to working RGBA.
   - Auto-downscale to Gemini max resolution and auto-compress >5MB.

4) Doodle canvas (basic)
   - Raster brush with size 1–50, color picker, eraser, undo/redo.
   - Export overlay as PNG with alpha; composite preview atop base.

5) Prompt & actions
   - Prompt `TextEditor`, character count, basic validation.
   - Actions: Generate, Regenerate, Swap Result → Base, Save PNG.
   - Keyboard shortcuts: Cmd+R (generate), Cmd+S (save), Cmd+Z (undo doodle).

6) Gemini integration
   - `GenAIClient` with `generateContent(prompt: String, images: [NSImage], overlay: NSImage?)`.
   - Progress reporting, cancellation, error surfaces (rate limits, invalid key, safety blocks).
   - Result parsing to `NSImage`; variant support (start with 1 image per request for MVP).

7) History & persistence
   - Write outputs to `~/Pictures/EvilBanana/runs/<timestamp_id>/` with `metadata.json` and `output_0.png`.
   - Store prompt, input file names, compression info, app version, timestamp.

8) UI polish — dark “evil” theme
   - Global dark theme tokens; neon accent for focus/selection.
   - Subtle transitions: sidebar add/remove, canvas tab switch, result appear.
   - Inline error toasts, non-blocking spinners during generation.

9) QA & packaging (local)
   - Manual test matrix on Apple Silicon (min macOS 14).
   - App sandbox settings (no network restrictions), file permissions prompts as needed.
   - Local run instructions; optional ad-hoc signing for smoother launch.

### Acceptance criteria
- App launches on Apple Silicon macOS 14+, shows three-pane UI.
- Up to 3 images can be dropped/selected, visually ordered, and removed.
- Doodle tools work (brush/eraser/color/undo/redo); overlay composites on preview.
- Generate calls Gemini and returns a valid image for text-to-image and image-edit.
- Save PNG writes to selected location; History also written to `~/Pictures/EvilBanana/...` with metadata.
- Swap Result → Base updates base image slot instantly.
- API key is stored securely in Keychain and survives relaunch.
- Errors are user-friendly (API key missing, rate limited, invalid images).

---

## Milestone: M2 — Multi-asset ergonomics & drag-reorder finesse

### Goals
- Refine multi-upload flow; improve drag/drop affordances and visual feedback.
- Add quick-clear, replace-in-place, and file reveal in Finder.

### Tasks
- Drag-reorder animations; keyboard selection + delete.
- Replace-in-place (drop on existing slot swaps).
- Quick actions: Clear all, Reveal in Finder, Open With.
- Thumbnail generation optimization and caching.

### Acceptance criteria
- Reordering is smooth with animated feedback; keyboard delete works.
- Replace-in-place is intuitive and undoable.
- Thumbnails generate instantly on repeated runs via cache.

---

## Milestone: M3 — Doodle enhancements & usability

### Tasks
- Pressure-adjusted brush (trackpad/pen), soft/round brush types.
- Eyedropper for color; configurable background checker for transparency.
- Constrain-to-line straight strokes (Shift), quick erase (E), brush size hotkeys ([ and ]).

### Acceptance criteria
- Users can switch brush types and sizes via UI or hotkeys.
- Eyedropper samples from composite preview correctly.

---

## Milestone: M4 — History browser (local)

### Tasks
- Grid view of runs from `~/Pictures/EvilBanana/runs/` with thumbnails and search by prompt.
- Quick-open a run to restore context (prompt + inputs + doodle overlay if saved).
- Batch delete and Reveal in Finder.

### Acceptance criteria
- Runs are discoverable and openable from the History window.
- Restored sessions faithfully match saved metadata.

---

## Milestone: M5 — Prompt bookmarks (optional)

### Tasks
- Bookmarks dropdown in prompt panel; add/remove/rename; persist to app support JSON.
- Insert selected bookmark into prompt editor with caret preservation.

### Acceptance criteria
- Users can save, select, and apply bookmarks across sessions.

---

## Milestone: M6 — Polish & stability

### Tasks
- App-wide error surfaces (retry, copy error details), non-blocking.
- Performance passes: image memory reuse, streaming decode, release unused.
- Accessibility: labels for controls, VoiceOver for images and prompts.
- Theming polish: ensure contrast and focus states in dark theme.

### Acceptance criteria
- No obvious UI hitches during typical workflows; memory stays bounded on large images.
- Accessibility checks pass for basic navigation/readouts.

---

## Milestone: M7 — PNG-embedded session metadata & drag-to-restore

### Goals
- Embed session JSON (prompt, inputs, overlay, model/settings, app version) inside exported PNGs.
- Allow users to drag a PNG back into the app to fully restore the workflow context.

### Tasks
- Define `session.json` schema and versioning strategy (v1: prompt, up to 3 input refs, overlay presence, timestamps, model, app version).
- Writer: Embed JSON into PNG using ImageIO (PNG iTXt/tEXt). Use a distinct key (e.g., `com.evilbanana.session`) and UTF-8 payload; compress if needed.
- Reader: On import/drag, detect and parse embedded JSON; validate version and compatibility.
- Restore: Reconstruct prompt, inputs (best-effort file resolution or embed small thumbnails), and doodle overlay if present.
- UX: Export toggle “Embed session metadata” (on by default); import banner “Session restored from PNG.”
- Security/Privacy: Warn that prompts may be embedded; provide “export without metadata.”
- Migration: Gracefully handle unknown versions and partial data.

### Acceptance criteria
- Exported PNGs contain a recoverable JSON block readable by the app.
- Dragging such PNGs into the app restores prompt and canvas state (including overlay), or provides clear partial-restore messaging.
- Users can opt out of embedding; files exported without metadata import as normal images.

---

## Technical implementation checklist

- Project
  - Swift package dependencies resolved; build targets set to Apple Silicon only.
  - App icon and branding assets stubbed.

- GenAIClient
  - Model name configurable; API key pulled from Keychain.
  - Content assembly supports prompt + up to 3 images + optional overlay.
  - Progress, cancellation, error mapping implemented; basic rate-limit backoff.
  - REST fallback utility (multipart/base64) behind feature flag.

- ImageProcessor
  - Auto-downscale to Gemini max; compress >5MB while maintaining quality.
  - Color space normalization to sRGB; metadata stripping.
  - Overlay compositing that preserves alpha and resolution.

- DoodleCanvasView
  - Brush engine with undo/redo stack; eraser and color picker.
  - Export overlay PNG; performance acceptable at large canvas.

- HistoryManager
  - Directory layout: `~/Pictures/EvilBanana/runs/<timestamp_id>/`.
  - `metadata.json` schema: prompt, input file refs, settings, timings, app version.
  - Thumbnail generation and caching.

- UI/UX
  - Three-pane layout with tabs: Source, Doodle, Result.
  - Dark theme styles; neon accent; focus/hover states.
  - Keyboard shortcuts wired and discoverable (menu hints, tooltips).

---

## Risks & mitigations
- SDK changes or instability → Maintain REST fallback; wrap in `GenAIClient` interface.
- Large image performance → Aggressive downscale/compress; lazy decoding; release caches.
- Safety filters blocking outputs → Expose actionable errors; allow prompt adjustments quickly.
- Keychain edge cases → Defensive reads; clear messaging and recovery workflow.

---

## Deliverables per milestone
- MVP: Running app with 3-upload flow, doodle basics, Gemini integration, PNG export, history writes.
- M2: Smooth multi-asset ergonomics and drag-reorder UX.
- M3: Upgraded doodle tools and usability.
- M4: History browser window with open/restore.
- M5: Prompt bookmarks.
- M6: Performance, accessibility, and theming polish.


