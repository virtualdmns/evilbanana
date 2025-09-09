//
//  ContentView.swift
//  Evil Banana
//
//  Created by DMNS on 2025-09-05.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

final class AppState: ObservableObject {
    @Published var prompt: String = ""
    @Published var uploads: [URL] = []
    @Published var resultImage: NSImage? = nil
    @Published var selectedCanvasTab: Int = 0
    @Published var isGenerating: Bool = false
    @Published var doodle = DoodleCanvasState()
}

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingImporter = false
    @State private var splitRatio: CGFloat = 0.55
    @State private var compareMode: Bool = false
    @State private var compareSlider: CGFloat = 0.5

    var body: some View {
        NavigationSplitView {
            // Sidebar: Assets/Uploads placeholder
            List {
                Section("Assets") {
                    if appState.uploads.isEmpty {
                        Label("Drop images here…", systemImage: "photo.on.rectangle")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(appState.uploads, id: \.self) { url in
                            HStack {
                                Image(systemName: "photo")
                                Text(url.lastPathComponent)
                                Spacer()
                                Button(role: .destructive) {
                                    if let idx = appState.uploads.firstIndex(of: url) {
                                        appState.uploads.remove(at: idx)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .help("Remove")
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Assets")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Add Image", systemImage: "plus")
                    }
                    .help("Add image(s)")
                }
            }
            .dropDestination(for: URL.self) { urls, _ in
                for url in urls {
                    let needs = url.startAccessingSecurityScopedResource()
                    importURL(url)
                    if needs { url.stopAccessingSecurityScopedResource() }
                }
                return true
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.image], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    for url in urls {
                        let needs = url.startAccessingSecurityScopedResource()
                        importURL(url)
                        if needs { url.stopAccessingSecurityScopedResource() }
                    }
                case .failure:
                    break
                }
            }
            // Restore session if PNG with embedded JSON is dropped selected: optional future
        } content: {
            // Center: Split-screen canvas (left: source/doodle, right: result)
            VStack(spacing: 8) {
                GeometryReader { outer in
                HStack(spacing: 8) {
                    // Left pane: Source or Doodle mode switch
                    VStack(spacing: 8) {
                        Picker("Mode", selection: $appState.selectedCanvasTab) {
                            Text("Source").tag(0)
                            Text("Doodle").tag(1)
                        }
                        .pickerStyle(.segmented)

                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.quaternary)
                            if appState.selectedCanvasTab == 1 {
                                VStack(spacing: 8) {
                                    GeometryReader { proxy in
                                        let size = proxy.size
                                        ZStack {
                                            if let base = compositeSourceImage() {
                                                Image(nsImage: base)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: size.width, height: size.height)
                                            } else {
                                                Text("Drop an image to begin")
                                                    .foregroundStyle(.secondary)
                                            }
                                            DoodleCanvasView(state: appState.doodle)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                    .frame(minHeight: 240)
                                    HStack {
                                        ColorPicker("Color", selection: $appState.doodle.brushColor)
                                            .labelsHidden()
                                        Slider(value: $appState.doodle.brushWidth, in: 1...50) { Text("Brush") }
                                            .frame(width: 140)
                                        Toggle("Eraser", isOn: $appState.doodle.isEraser)
                                        Spacer()
                                        Button("Undo") { appState.doodle.undo() }.disabled(appState.doodle.strokes.isEmpty)
                                        Button("Redo") { appState.doodle.redo() }.disabled(appState.doodle.undone.isEmpty)
                                        Button("Clear") { appState.doodle.clear() }
                                    }
                                }
                            } else if !appState.uploads.isEmpty {
                                GeometryReader { proxy in
                                    let size = proxy.size
                                    let images: [NSImage] = appState.uploads.compactMap { ImageProcessor.cachedImage(from: $0) }
                                    if !images.isEmpty {
                                        let count = CGFloat(images.count)
                                        let spacing: CGFloat = 8
                                        let totalSpacing = spacing * max(0, count - 1)
                                        let itemWidth = (size.width - totalSpacing) / count
                                        HStack(spacing: spacing) {
                                            ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                                                Image(nsImage: img)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: itemWidth, height: size.height)
                                            }
                                        }
                                    } else {
                                        Text("Drop an image to begin")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } else {
                                Text("Drop an image to begin")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Drag handle
                    Rectangle()
                        .fill(.separator)
                        .frame(width: 4)
                        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                            let totalWidth = max(outer.size.width, 1)
                            let delta = value.translation.width / totalWidth
                            splitRatio = min(0.8, max(0.2, splitRatio + delta))
                        })

                    // Right pane: Result / Compare
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary)
                        GeometryReader { proxy in
                            let size = proxy.size
                            if let result = appState.resultImage {
                                if compareMode, let srcComposite = compositeSourceImage() {
                                    // Base: source composite
                                    Image(nsImage: srcComposite)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: size.width, height: size.height)
                                    // Overlay: result clipped by slider
                                    Image(nsImage: result)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: size.width, height: size.height)
                                        .mask(
                                            Rectangle()
                                                .frame(width: size.width * compareSlider, height: size.height)
                                                .offset(x: -size.width / 2 + (size.width * compareSlider) / 2)
                                        )
                                    // Handle
                                    Rectangle()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: 2, height: size.height)
                                        .position(x: size.width * compareSlider, y: size.height / 2)
                                        .gesture(
                                            DragGesture(minimumDistance: 0).onChanged { value in
                                                let x = max(0, min(size.width, value.location.x))
                                                compareSlider = x / size.width
                                            }
                                        )
                                } else {
                                    Image(nsImage: result)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: size.width, height: size.height)
                                        .contextMenu {
                                            Button("Save PNG") { exporting = true }
                                        }
                                }
                            } else {
                                Text("No result yet")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(width: outer.size.width)
                .overlay(alignment: .leading) {
                    Color.clear.frame(width: outer.size.width * splitRatio)
                }
                }

                if appState.isGenerating {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                // Compare controls
                HStack(spacing: 12) {
                    Toggle("Compare slider", isOn: $compareMode)
                    if compareMode {
                        Slider(value: $compareSlider, in: 0...1)
                            .frame(maxWidth: 280)
                    }
                }
                .padding(.top, 4)
            }
            .padding()
            .navigationTitle("Canvas")
        } detail: {
            // Right panel: Convo (top) + Prompt anchored to bottom (1/5 height)
            GeometryReader { proxy in
                let promptArea: CGFloat = max(120, proxy.size.height * 0.20)
                VStack(alignment: .leading, spacing: 12) {
                    // Conversation history above
                    if !convoMessages.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(convoMessages.enumerated()), id: \.offset) { _, msg in
                                    Text(msg)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(6)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    Spacer(minLength: 0)
                    // Prompt area
                    Text("Prompt")
                        .font(.headline)
                    TextEditor(text: $appState.prompt)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(height: promptArea - 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.quaternary)
                        )
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
                .padding()
            }
            .navigationTitle("Prompt & Actions")
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button { generateAction() } label: { Label("Generate", systemImage: "wand.and.stars") }
                        .keyboardShortcut("r", modifiers: [.command])
                        .disabled(appState.isGenerating)
                    Button { generateAction() } label: { Label("Regenerate", systemImage: "arrow.clockwise") }
                        .disabled(appState.isGenerating)
                    Spacer()
                    Button { swapResultIntoBase() } label: { Image(systemName: "arrow.triangle.2.circlepath") }
                        .help("Swap Result → Base")
                        .disabled(appState.resultImage == nil)
                    Button { exporting = true } label: { Image(systemName: "square.and.arrow.down") }
                        .help("Save PNG")
                        .disabled(appState.resultImage == nil)
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
                .background(.bar)
            }
            .fileExporter(
                isPresented: $exporting,
                document: appState.resultImage.map { ResultImageDocument(image: $0) },
                contentType: .png,
                defaultFilename: "evilbanana_output"
            ) { _ in }
        }
    }

    @State private var exporting = false
    @State private var exportURL: URL? = nil

    private func generateAction() {
        let images: [NSImage] = appState.uploads.compactMap { url in
            if let img = ImageProcessor.cachedImage(from: url) {
                return ImageProcessor.downscaleIfNeeded(image: img, maxDimension: 2048)
            }
            return nil
        }
        guard !images.isEmpty else { 
            convoMessages.append("❌ Error: No images provided. Please add at least one image to generate.")
            return 
        }
        appState.isGenerating = true
        Task { @MainActor in
            defer { appState.isGenerating = false }
            do {
                let overlayImage: NSImage? = {
                    guard !appState.doodle.strokes.isEmpty else { return nil }
                    if let first = images.first { return appState.doodle.rasterizeOverlay(size: first.size) }
                    return nil
                }()
                let resp = try await GenAIClient.shared.generate(prompt: appState.prompt, images: images, overlay: overlayImage)
                if let text = resp.text, !text.isEmpty {
                    convoMessages.append(text)
                }
                if let bytes = resp.imageData, let result = NSImage(data: bytes) {
                    appState.resultImage = result
                    appState.selectedCanvasTab = 2
                    HistoryManager.writeRun(prompt: appState.prompt, inputURLs: appState.uploads, result: result)
                }
            } catch {
                // Add error to conversation history instead of just showing alert
                let errorText: String
                if let genAIError = error as? GenAIClientError {
                    errorText = genAIError.userFriendlyMessage
                } else {
                    errorText = "❌ Error: \(String(describing: error))"
                }
                convoMessages.append(errorText)
            }
        }
    }

    private func swapResultIntoBase() {
        guard let result = appState.resultImage else { return }
        if let url = ImageProcessor.writePNGToTemp(image: result) {
            if appState.uploads.isEmpty {
                appState.uploads = [url]
            } else {
                appState.uploads[0] = url
            }
            appState.selectedCanvasTab = 0
        } else {
            convoMessages.append("❌ Error: Failed to save result image to temporary file")
        }
    }

    private func importURL(_ url: URL) {
        guard appState.uploads.count < 3 else { 
            convoMessages.append("❌ Error: Maximum of 3 images allowed")
            return 
        }
        // Load and downscale, then write to temp and track temp URL
        if let img = ImageProcessor.cachedImage(from: url) {
            let scaled = ImageProcessor.downscaleIfNeeded(image: img, maxDimension: 2048)
            if let tmp = ImageProcessor.writePNGToTemp(image: scaled) {
                DispatchQueue.main.async {
                    if self.appState.uploads.count < 3 {
                        self.appState.uploads.append(tmp)
                    }
                }
            } else {
                convoMessages.append("❌ Error: Failed to process image file")
            }
        } else {
            convoMessages.append("❌ Error: Could not load image from \(url.lastPathComponent)")
        }
    }

    // Simple convo log state (right panel future chat)
    @State private var convoMessages: [String] = []

    private func exportSession() -> [String: Any] {
        return [
            "prompt": appState.prompt,
            "inputs": appState.uploads.map { $0.lastPathComponent },
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }

    private func compositeSourceImage() -> NSImage? {
        let images: [NSImage] = appState.uploads.compactMap { NSImage(contentsOf: $0) }
        guard !images.isEmpty else { return nil }
        return ImageProcessor.compositeImages(images)
    }
}

#Preview {
    ContentView()
}
