//
//  HistoryWindow.swift
//  Evil Banana
//

import SwiftUI

struct HistoryItem: Identifiable {
    let id = UUID()
    let folder: URL
    let image: NSImage?
    let prompt: String
}

final class HistoryViewModel: ObservableObject {
    @Published var items: [HistoryItem] = []

    func load() {
        guard let base = HistoryManager.baseRunsDirectory() else { return }
        let fm = FileManager.default
        if let folders = try? fm.contentsOfDirectory(at: base, includingPropertiesForKeys: nil) {
            let runs = folders.sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
            self.items = runs.compactMap { dir in
                let out = dir.appendingPathComponent("output_0.png")
                let meta = dir.appendingPathComponent("metadata.json")
                let img = NSImage(contentsOf: out)
                var prompt = ""
                if let data = try? Data(contentsOf: meta),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    prompt = (json["prompt"] as? String) ?? ""
                }
                return HistoryItem(folder: dir, image: img, prompt: prompt)
            }
        }
    }
}

struct HistoryWindow: View {
    @StateObject var vm = HistoryViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                ForEach(vm.items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        if let image = item.image {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8).fill(.quaternary).frame(height: 160)
                        }
                        Text(item.prompt)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(6)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        restore(item)
                    }
                }
            }
            .padding(12)
        }
        .frame(minWidth: 640, minHeight: 480)
        .onAppear { vm.load() }
    }

    private func restore(_ item: HistoryItem) {
        // Load metadata and input files
        let metaURL = item.folder.appendingPathComponent("metadata.json")
        var prompt = ""
        var inputs: [URL] = []
        if let data = try? Data(contentsOf: metaURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            prompt = (json["prompt"] as? String) ?? ""
            if let inputNames = json["inputs"] as? [String] {
                inputs = inputNames.map { item.folder.appendingPathComponent($0) }
            }
        }
        // Update app state
        appState.prompt = prompt
        appState.uploads = inputs
    }
}


