import SwiftUI

@main
struct RPApp: App {
var bleManager:RPBLEManager = RPBLEManager()
    var body: some Scene {
        WindowGroup {
          ContentView(bleManager: bleManager)
        }
    }
}
