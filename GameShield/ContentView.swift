import SwiftUI

struct ContentView: View {
    @State private var showInstructions = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label("GameShield", systemImage: "shield.lefthalf.filled")
                        .font(.largeTitle.bold())
                    Text("Game ad filtering setup")
                        .font(.title3)
                    Text("This app does not claim to block ads by itself. Configure a trusted DNS blocker in iOS Settings to filter known ad domains across games.")
                    .foregroundStyle(.secondary)
                    GroupBox("Protection status") {
                        Label("Not verified — check iOS DNS settings", systemImage: "exclamationmark.shield")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button("Show setup instructions") { showInstructions.toggle() }
                        .buttonStyle(.borderedProminent)
                    if showInstructions {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("1. Choose a reputable encrypted DNS filtering provider.")
                            Text("2. Install its iOS DNS configuration profile using its official instructions.")
                            Text("3. Approve the profile in Settings. iOS requires your permission.")
                            Text("4. Test your games, notifications, and messaging. Remove the DNS profile if anything breaks.")
                        }.font(.body)
                    }
                    Divider()
                    Text("Limitations").font(.headline)
                    Text("DNS blocking may not remove all ads or reward screens. Filtering is not per-game and can affect other apps. This app does not read messages, calls, or notifications.")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("GameShield")
        }
    }
}
