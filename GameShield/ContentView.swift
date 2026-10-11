import SwiftUI
import UIKit

private enum ShieldDNS {
    static let setup = URL(string: "https://adguard-dns.io/en/public-dns.html")!
    static let help = URL(string: "https://adguard-dns.io/en/support.html")!
    static let test = URL(string: "https://adguard.com/en/test.html")!
}

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("setupConfirmed") private var setupConfirmed = false
    @AppStorage("messagesTested") private var messagesTested = false
    @AppStorage("gameTested") private var gameTested = false
    @AppStorage("hasReadLimitations") private var hasReadLimitations = false
    @State private var showResetConfirmation = false

    private var checksComplete: Bool {
        setupConfirmed && messagesTested && gameTested
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("GameShield", systemImage: "shield.lefthalf.filled")
                        .font(.largeTitle.bold())
                    Text("Free game-ad DNS setup")
                        .font(.headline)
                    Label("DNS status cannot be read by this app", systemImage: "questionmark.shield")
                        .foregroundStyle(.orange)
                    Text("GameShield is a setup companion. A separately installed DNS profile performs the actual blocking. No VPN, special entitlements, account, or subscription is required by GameShield.")
                        .font(.subheadline)
                }
                Section("1 · Activate filtering") {
                    Text("Use the official AdGuard public DNS page. Select the default ad-blocking service (not the unfiltered server), follow its iOS configuration-profile instructions, and approve the profile in Settings.")
                    Button { openURL(ShieldDNS.setup) } label: {
                        Label("Official free DNS setup", systemImage: "safari")
                    }
                    Button { openURL(URL(string: UIApplication.openSettingsURLString)!) } label: {
                        Label("Open iPhone Settings", systemImage: "gearshape")
                    }
                    Text("DNS profiles require your approval. An ordinary app cannot install, activate, or remove one silently.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("2 · Check protection") {
                    Button { openURL(ShieldDNS.test) } label: {
                        Label("Open DNS/ad-block test page", systemImage: "checkmark.shield")
                    }
                    Text("A web test is only an indication; it cannot prove that all game ads are blocked.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Toggle("I enabled filtering DNS in iOS", isOn: $setupConfirmed)
                    Toggle("Calls, messages and notifications work", isOn: $messagesTested)
                    Toggle("I tested an ad-supported game", isOn: $gameTested)
                    Label(checksComplete ? "Manual checks complete" : "Manual checks incomplete", systemImage: checksComplete ? "checkmark.circle.fill" : "circle.dotted")
                        .foregroundStyle(checksComplete ? .green : .secondary)
                }
                Section("3 · Troubleshooting and recovery") {
                    Text("If an app, game, website, or notification fails, disable the DNS profile in iOS Settings. Removing GameShield alone will not remove the profile.")
                    Button { openURL(ShieldDNS.help) } label: {
                        Label("Provider support", systemImage: "questionmark.circle")
                    }
                    Button("Reset manual checklist", role: .destructive) {
                        showResetConfirmation = true
                    }
                }
                Section("Privacy and limitations") {
                    Toggle("I understand DNS filtering is system-wide", isOn: $hasReadLimitations)
                    Text("GameShield collects no account, traffic, messages, calls, or notification data. The chosen DNS provider handles DNS queries under its own privacy policy.")
                    Text("Some ads, rewarded videos, and first-party ad traffic will remain. DNS filtering is not per-game and may impact other apps. App Store and sideloaded games are subject to the same network limitations.")
                    Text("Checklist choices stay on this iPhone. They are not a measurement of active filtering.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Text("GameShield v1.0 · DNS companion edition")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("GameShield")
            .confirmationDialog("Reset manual checks?", isPresented: $showResetConfirmation) {
                Button("Reset checks", role: .destructive) {
                    setupConfirmed = false
                    messagesTested = false
                    gameTested = false
                    hasReadLimitations = false
                }
            } message: {
                Text("This does not change your iPhone DNS configuration.")
            }
        }
    }
}
