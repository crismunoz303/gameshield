import SwiftUI

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @State private var completedSetup = false
    @State private var messagingChecked = false
    @State private var gameChecked = false

    private let providerURL = URL(string: "https://adguard-dns.io/en/public-dns.html")!
    private let settingsURL = URL(string: UIApplication.openSettingsURLString)!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Label("GameShield", systemImage: "shield.lefthalf.filled")
                        .font(.largeTitle.bold())
                    Text("Free DNS-based game ad filtering")
                        .font(.headline)
                    Text("Set up a trusted filtering DNS profile to block many known advertising domains. GameShield cannot activate DNS filtering by itself.")
                        .foregroundStyle(.secondary)

                    GroupBox("Actual protection status") {
                        Label("Not independently verified", systemImage: "questionmark.shield")
                            .foregroundStyle(.orange)
                        Text("iOS does not expose the active DNS profile status to this app. Check Settings to confirm your selected profile is enabled.")
                            .font(.footnote)
                    }

                    GroupBox("1 · Install filtering DNS") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Open the official AdGuard public DNS instructions. Choose the default ad-blocking server, follow the iOS instructions, and approve the profile in Settings.")
                            Button {
                                openURL(providerURL)
                            } label: {
                                Label("Open official DNS setup", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(.borderedProminent)
                            Text("This opens a third-party provider. Its DNS privacy policy applies. No paid subscription is required for its public DNS.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    GroupBox("2 · Verify and test") {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                openURL(settingsURL)
                            } label: {
                                Label("Open iOS Settings", systemImage: "gearshape")
                            }
                            Text("Confirm the DNS profile is active in Settings. Then test a game and your usual messaging apps.")
                            Toggle("I confirmed DNS setup in Settings", isOn: $completedSetup)
                            Toggle("Messages and notifications work", isOn: $messagingChecked)
                            Toggle("I tested an ad-supported game", isOn: $gameChecked)
                            if completedSetup && messagingChecked && gameChecked {
                                Label("Manual checks complete — filtering effectiveness varies by game", systemImage: "checkmark.circle")
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    GroupBox("Disable or troubleshoot") {
                        Text("If a game, website, or notification fails, disable or remove the DNS profile in iOS Settings. Closing or deleting GameShield does not disable an installed DNS profile.")
                    }

                    Text("Limits: DNS filtering is not game-specific; some ads and rewarded ads will remain. It cannot remove ads delivered from the same domain as gameplay. GameShield does not access calls, messages, or notifications.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("GameShield")
        }
    }
}
