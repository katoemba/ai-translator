//
//  AI_TranslatorApp.swift
//  AI Translator
//
//  Created by Berrie Kremers on 28/03/2026.
//

import SwiftUI

@main
struct AI_TranslatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            FileCommands()
        }

        Settings {
            SettingsView()
        }
    }
}
