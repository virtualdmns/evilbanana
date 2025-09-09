//
//  HistoryManager.swift
//  Evil Banana
//
//  Writes runs to ~/Pictures/EvilBanana/runs/<timestamp_id>/
//

import Foundation
import AppKit

struct RunMetadata: Codable {
    let id: String
    let timestamp: String
    let prompt: String
    let inputs: [String]
    let appVersion: String
}

enum HistoryManager {
    static func baseRunsDirectory() -> URL? {
        guard let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first else { return nil }
        return pictures.appendingPathComponent("EvilBanana").appendingPathComponent("runs")
    }

    static func writeRun(prompt: String, inputURLs: [URL], result: NSImage) {
        guard let base = baseRunsDirectory() else { return }
        let id = "run_\(DateFormatter.cache.string(from: Date()))_\(Int.random(in: 100000...999999))"
        let dir = base.appendingPathComponent(id)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            // Save inputs (copy thumbnails) and result
            var inputNames: [String] = []
            for (idx, url) in inputURLs.enumerated() {
                let name = "input_\(idx).png"
                inputNames.append(name)
                if let img = NSImage(contentsOf: url), let data = ImageProcessor.pngData(img) {
                    try? data.write(to: dir.appendingPathComponent(name))
                }
            }
            if let data = ImageProcessor.pngData(result) {
                try data.write(to: dir.appendingPathComponent("output_0.png"))
            }
            // Metadata
            let meta = RunMetadata(
                id: id,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                prompt: prompt,
                inputs: inputNames,
                appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
            )
            let metaData = try JSONEncoder().encode(meta)
            try metaData.write(to: dir.appendingPathComponent("metadata.json"))
        } catch {
            // ignore for now
        }
    }
}

private extension DateFormatter {
    static let cache: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmmss"
        return df
    }()
}


