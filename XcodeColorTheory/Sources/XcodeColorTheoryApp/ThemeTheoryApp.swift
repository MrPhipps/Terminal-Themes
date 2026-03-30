import SwiftUI
import ThemeTheory

@main
struct ThemeTheoryApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(env)
                .task { await env.loadLibrary() }
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 700)
        #endif
    }
}
