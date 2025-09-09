//
//  GenAIClient.swift
//  Evil Banana
//
//  Stub client for Gemini integration. Will wrap GoogleGenerativeAI SDK.
//

import Foundation
import AppKit

enum GenAIClientError: Error {
    case missingApiKey
    case invalidResponse
    case requestFailed(String)
    
    var userFriendlyMessage: String {
        switch self {
        case .missingApiKey:
            return "❌ API Key Missing: Please set your Gemini API key in Preferences (Cmd+,)"
        case .invalidResponse:
            return "❌ Invalid Response: The API returned an unexpected response format"
        case .requestFailed(let message):
            return "❌ API Error: \(message)"
        }
    }
}

struct GenAIResponse: Sendable {
    let imageData: Data?
    let text: String?
}

final class GenAIClient {
    static let shared = GenAIClient()

    private init() {}

    func generate(prompt: String, images: [NSImage], overlay: NSImage?) async throws -> GenAIResponse {
        // REST fallback implementation using Gemini API
        let apiKey = ConfigService.shared.load()?.apiKey ?? KeychainService.shared.readString(service: "EvilBanana", account: "GeminiAPIKey")
        guard let apiKey, !apiKey.isEmpty else {
            throw GenAIClientError.missingApiKey
        }

        let model = "gemini-2.5-flash-image-preview"
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var parts: [[String: Any]] = []
        // Text part
        parts.append(["text": prompt])

        // Image parts
        for image in images.prefix(3) {
            if let encoded = ImageProcessor.encodeForGemini(image: image) {
                let b64 = encoded.data.base64EncodedString()
                parts.append([
                    "inline_data": [
                        "mime_type": encoded.mime,
                        "data": b64
                    ]
                ])
            }
        }

        // Overlay part (optional)
        if let overlay = overlay, let encoded = ImageProcessor.encodeForGemini(image: overlay) {
            let b64 = encoded.data.base64EncodedString()
            parts.append([
                "inline_data": [
                    "mime_type": encoded.mime,
                    "data": b64
                ]
            ])
        }

        let payload: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": parts
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GenAIClientError.invalidResponse }
        guard 200..<300 ~= http.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Gemini error status: \(http.statusCode) body: \(message)")
            throw GenAIClientError.requestFailed(message)
        }

        // Parse response for base64 image and/or text
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let outParts = content["parts"] as? [[String: Any]] {
            var imageData: Data? = nil
            var texts: [String] = []
            for part in outParts {
                if let txt = part["text"] as? String {
                    texts.append(txt)
                }
                // Support both inline_data (snake_case) and inlineData (camelCase)
                if let inline = part["inline_data"] as? [String: Any] ?? part["inlineData"] as? [String: Any],
                   let b64 = inline["data"] as? String,
                   let bytes = Data(base64Encoded: b64) {
                    imageData = bytes
                }
            }
            return GenAIResponse(imageData: imageData, text: texts.isEmpty ? nil : texts.joined())
        }

        // If we cannot parse, return error for UI
        let bodyStr = String(data: data, encoding: .utf8) ?? ""
        print("Gemini response parse failure: \(bodyStr)")
        throw GenAIClientError.invalidResponse
    }
}


