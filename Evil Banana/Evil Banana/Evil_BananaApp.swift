//
//  Evil_BananaApp.swift
//  Evil Banana
//
//  Created by DMNS on 2025-09-05.
//

import SwiftUI

@main
struct Evil_BananaApp: App {
    @State private var apiKey: String = ""
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .tint(Color(red: 1, green: 0.2, blue: 0.2))
                .preferredColorScheme(.dark)
        }
        .commands {
            CommandMenu("File") {
                Button("Save PNG") {
                    NotificationCenter.default.post(name: .evilBananaSavePNG, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command])
                Button("History") {
                    NotificationCenter.default.post(name: .evilBananaOpenHistory, object: nil)
                }
                .keyboardShortcut("y", modifiers: [.command])
            }
        }
        Settings {
            Form {
                LabeledContent("Gemini API Key") {
                    SecureField("Enter API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 360)
                }
                HStack(spacing: 12) {
                    Button("Save to Config") { ConfigService.shared.save(AppConfig(apiKey: apiKey)) }
                    Button("Load from Config") { apiKey = ConfigService.shared.load()?.apiKey ?? "" }
                    Button("Clear") { apiKey = ""; ConfigService.shared.save(AppConfig(apiKey: "")) }
                    Spacer()
                    Text("Stored in App Support config")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(minWidth: 420)
            .onAppear {
                apiKey = ConfigService.shared.load()?.apiKey ?? ""
            }
        }
        .onChange(of: NotificationCenter.default.publisher(for: .evilBananaOpenHistory)) { _ in }
        .windowStyle(.automatic)
        .handlesExternalEvents(matching: [])

        WindowGroup("History") {
            HistoryWindow()
                .environmentObject(appState)
        }
        .defaultSize(width: 720, height: 560)

        // Use default About panel
    }
}

extension Notification.Name {
    static let evilBananaSavePNG = Notification.Name("evilBananaSavePNG")
    static let evilBananaOpenHistory = Notification.Name("evilBananaOpenHistory")
}
