<p align="center">
  <img src="Evil Banana/Evil BananaIcons/AlphaBanana.png" alt="Evil Banana" width="220"/>
</p>

<p align="center">
  <b>Evil Banana</b><br/>
  macOS (SwiftUI) AI image playground — by <b>virtualdmns</b>
</p>

---

### ✨ What is this?
Evil Banana is a native macOS app for rapid, iterative image generation and editing with Google Gemini (nano banana). It’s fast, dark, and opinionated: split-screen canvas (sources/doodle on the left, results on the right), compare slider, history, and buttery drag‑and‑drop.

### ⚙️ Requirements
- macOS 14+ (Apple Silicon)
- Gemini API key

### 🍌 Download Evil Banana App
1) Grab v1.0 Release "Evil Banana.app"

   or

### 🛠️ Build Yourself
1) Open Xcode project: `evilbanana/Evil Banana/Evil Banana.xcodeproj`.

  then
  
2) Build & run the “Evil Banana” target (My Mac).
3) Preferences → paste your Gemini API key → “Save to Config”.
4) Drop up to 3 images into the Assets sidebar, write a prompt, hit Generate (⌘R).

### 🖥️ UI Primer
- Left Pane: Sources and Doodle (mode switch). Drop images or click “Add Image”.
- Right Pane: Result (with Compare slider option against the source composite).
- Bottom Bar: Generate/Regenerate, Swap Result → Base, Save PNG.
- Conversation snippets surface in the right panel without blocking controls.

### 🧪 Features
- Multi‑image inputs (≤3); side‑by‑side preview; same array sent to the API.
- Doodle overlay: brush/eraser/size/color/undo/redo; always included in generation if non‑empty (even if Doodle tab isn’t active).
- Compare slider: overlay result on source composite and scrub visually.
- History: saved to `~/Pictures/EvilBanana/runs/<timestamp_id>/` with `metadata.json`, inputs, `output_0.png`.
- Restore: File → History (⌘Y) → click a run to reload prompt & inputs.
- Save: ⌘S or right‑click result → Save PNG.

### ⌨️ Shortcuts
- ⌘R: Generate / Regenerate
- ⌘S: Save PNG
- ⌘Y: Open History

### 🔐 Settings & Storage
- Preferences → API key stored in `~/Library/Application Support/EvilBanana/config.json`.
- App Sandbox enabled; Network Client and User‑Selected File Read/Write entitlements configured.

### 🧰 Troubleshooting
- “No image / black result”: confirm API key, network; errors are shown in alerts.
- Drag & Drop blocked: try Finder export; or use Add Image (file importer).
- Save panel issues: Files & Folders permissions may need approval in System Settings.

### 🌓 Theme & Performance
- Global dark scheme with evil‑red tint.
- Cached image decoding (NSCache) to avoid re‑loading from disk.
- Import pipeline downsizes large images and writes temp PNGs for stability.

### 📜 License & Credits
- © virtualdmns. All rights reserved.
- App icons and `AlphaBanana.png` included in `evilbanana/Evil Banana/Evil BananaIcons/`.

### 🗺️ Roadmap Ideas
- Draggable compare handle polish, overlay presets, prompt bookmarks.
- Full session restore including doodle overlay.

---

Built with love, caffeine, and a little evil.


