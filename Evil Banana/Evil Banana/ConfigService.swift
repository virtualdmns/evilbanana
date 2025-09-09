//
//  ConfigService.swift
//  Evil Banana
//

import Foundation

struct AppConfig: Codable {
    var apiKey: String
}

final class ConfigService {
    static let shared = ConfigService()
    private init() {}

    private func configURL() -> URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let dir = appSupport.appendingPathComponent("EvilBanana", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }

    func load() -> AppConfig? {
        guard let url = configURL(), FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppConfig.self, from: data)
    }

    func save(_ config: AppConfig) {
        guard let url = configURL() else { return }
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: url)
        }
    }
}


