import SwiftUI

@main
struct DeepGemsApp: App {
    @StateObject private var game = GameStore()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(game).preferredColorScheme(.dark).tint(.deepGold)
                .onChange(of: scenePhase) { _, phase in if phase != .active { game.save() } }
        }
    }
}
