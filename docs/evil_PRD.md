## PRD: Evil Banana — macOS (Swift) Edition

### 1. Overview
- **Product Name**: Evil Banana
- **Platform**: Native macOS app built with Swift and SwiftUI (macOS 14+ for latest features like enhanced Canvas and drag-drop APIs).
- **Goal**: Forge a cybernetic oracle for Google's Gemini 2.5 Flash Image (aka "Nano Banana") API—enabling raw, iterative AI image generation and editing with doodle guidance, multi-image fusion, and consistent character design. Mirror the Gradio prototype's hacky charm but elevate it to a polished, feature-complete Mac app that feels like a natural extension of Finder and Photos: intuitive, responsive, and packed with power-user tools for your virtualdmns AI art workflows.
- **Scope**: Local-first, private tool—no cloud sync beyond API calls. User provides Gemini API key (stored securely). Start with MVP for immediate use (upload/doodle/prompt/generate/swap), then expand to epic: conversational chains, history with search, exports (PNG, PSD, OBJ for Houdini), and accessibility tweaks.
- **Target Audience**: AI rebels like you—coders, artists, machine art collectives blending manual doodles with AI chaos. Optimized for high-res screens (Retina+), Apple Silicon for snappy performance.
- **Differentiation**: Unlike web-based tools or clunky cross-platform crap, this is pure Mac magic: seamless drag-drop from Finder, native shortcuts, dark mode harmony, and zero bloat. It's the "best Nano Banana tool ever" but native, beautiful, and evil (subtle cyberpunk theme: neon accents, banana icons with devil horns).
- **Tech Stack**: Swift 5.10+, SwiftUI for UI, GoogleGenerativeAI SDK for API (fallback to URLSession REST if needed), Core Image for processing, Security.framework for Keychain.

### 2. Core Use Cases & Workflows
- **MVP (Minimum Functionality for Immediate Use)**: Mirror Gradio—upload image(s), doodle in any color (temp or saved), enter prompt, generate/edit via API, preview side-by-side, save/swap for iteration. Get this running first so you can edit pics today.
- **Epic Extensions**:
  - **Text-to-Image Generation**: Pure prompt to image, with variants (batch 3-5).
  - **Doodle-Guided Edits**: Scribble on canvas (any color, brush/erase), feed as input for refinement (e.g., "Realize this doodle as cyberpunk armor").
  - **Multi-Image Fusion**: Drag multiple elements (up to 5), fuse semantically (e.g., "Blend this banana into that mech scene, match lighting").
  - **Consistent Character Design**: Lock refs (e.g., face/outfit), generate across scenes with 95%+ fidelity via prompting (e.g., "Keep this exact character in desert, add doodle flames").
  - **Iterative/Conversational Workflow**: Multi-turn chat for refinements (e.g., "Make it darker," API caches context).
  - **History & Batch**: Browse past runs with thumbnails/search, re-run variants.
  - **Exports & Integrations**: Save as PNG/JPG/PSD, export doodles as vectors, OBJ for Houdini imports.

### 3. Functional Requirements
- **UI Structure (SwiftUI)**:
  - **Main Window**: NavigationSplitView for Mac elegance—left sidebar (Assets/Refs), center canvas (tabbed: Source/Doodle/Result), right panel (Prompt/Chat/Logs).
    - **Assets Sidebar**: ListView for base + refs (drag-reorder, up to 5). DropDestination for Finder drags. Thumbnails, delete/add buttons.
    - **Canvas Area**: TabView with:
      - Source: Image viewer (zoom/pan).
      - Doodle: Canvas overlay for freeform drawing (color picker, brush sizes 1-50, erase, undo/redo stack). Temp mode (in-memory) or save as layer.
      - Result: Side-by-side compare (split or overlay toggle), zoom sync.
    - **Prompt Panel**: TextEditor for prompts, dropdown templates (e.g., "Fuse refs: [base] + [ref1]"), auto-insert consistency phrasing if refs present. Chatbot-style for multi-turn.
  - **Toolbar**: New Session, History Browser, Save Output (PNG/PSD), Swap Result → Base, Export (OBJ), Undo/Redo.
  - **Preferences Window**: API key input, stored in Keychain. Theme toggles (evil neon accents).
  - **History Browser**: Separate window with GridView thumbnails, search by prompt/metadata, quick-open.

- **Image Handling**:
  - Upload: Drag-drop from Finder/Photos, or file picker. Auto-compress >5MB (Core Image: JPEG/WEBP, downscale to 1024x if needed while preserving aspect).
  - Doodle: Bitmap layer on CGContext, export as PNG overlay or composite.
  - Limits: 5 images total (API sweet spot).

- **API Integration**:
  - Use GoogleGenerativeAI Swift SDK: `import GoogleGenerativeAI; let model = GenerativeModel(name: "gemini-2.5-flash-image-preview", apiKey: key)`.
  - Methods: `generateContent(prompt: String, images: [UIImage?], safetySettings: ...)`—async with progress.
  - Multi-turn: Use chat sessions for context.
  - Fallback: URLSession REST if SDK quirks (JSON multi-part with base64 images).
  - Error Handling: Rate limits queue, vague prompt warnings.

- **Iteration & Advanced**:
  - Swap: One-click copy result to base slot.
  - Batch: Generate 3 variants via loop.
  - Shortcuts: Cmd+S save, Cmd+Z undo doodle, Cmd+R regenerate.

### 4. Non-Functional Requirements
- **Performance**: Async API calls (ProgressView spinner), <5s gens on M1+. Memory: Stream images, release unused.
- **Usability**: Native Mac feel—tool tips, accessibility (VoiceOver for prompts/images), dark/light mode auto.
- **Privacy/Security**: API key in Keychain (no plaintext). No telemetry. Offline UI works; API fails gracefully.
- **Compatibility**: macOS 14+, Intel/Apple Silicon. Test on Ventura+.
- **Theming**: Subtle "evil" aesthetic—neon borders, banana icon with horns.

### 5. Architecture
- **App Structure**: SwiftUI App lifecycle, @Observable for state (prompt, images, doodle, result, history).
- **Key Components**:
  - **GenAIClient**: SDK wrapper, handles auth/compression/multi-part.
  - **ImageProcessor**: Core Image for compress/convert/doodle composite.
  - **HistoryManager**: FileManager for `~/Library/Application Support/EvilBanana/runs/`—JSON metadata + PNGs.
  - **DoodleCanvasView**: Custom Canvas with GestureRecognizers for drawing.

### 6. Security & Keys
- Key input in Prefs, stored via Keychain Services API (kSecClassGenericPassword).
- Build flag for embedded key in private builds (debug only).

### 7. Milestones & Timeline
- **MVP (1-2 days)**: Scaffold app, API key setup, basic upload/prompt/generate/preview/swap (text-to-image + single edit).
- **M2 (Day 3)**: Multi-upload, fusion, drag-drop.
- **M3 (Day 4)**: Doodle canvas (color/brush), temp/save integration.
- **M4 (Day 5)**: Consistent char refs, multi-turn chat.
- **M5 (Day 6)**: History browser, batch variants.
- **M6 (Day 7)**: Polish—shortcuts, exports, error UX, theming.
- **M7**: Test/bug bash, package for distribution (notarized DMG).

### 8. Risks & Mitigations
- SDK changes: Fallback to REST.
- Memory for large images: Auto-downscale, GC monitoring.
- API costs/limits: UI warnings, queue system.
- Drawing precision: Haptic feedback on Apple Pencil/trackpad.

### 9. References
- Gemini Docs: https://ai.google.dev/gemini-api/docs/image-generation, https://ai.google.dev/gemini-api/docs/rest.
- Swift Tutorials: AppCoda Gemini Integration, Sketching App Medium, Apple Drag-Drop.