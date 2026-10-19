import SwiftUI
import Charts

private enum Palette {
    static let background = Color(red: 0.045, green: 0.055, blue: 0.08)
    static let panel = Color(red: 0.11, green: 0.13, blue: 0.17)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.25)
    static let muted = Color(red: 0.68, green: 0.72, blue: 0.78)
}
private struct RemoteLevel: Decodable { let current: Int? }
private struct RemoteRank: Decodable {
    let multiplayerRank: String?
    let rating: Int?
}
private struct RemoteProfile: Decodable {
    let success: Bool
    let nickname: String?
    let level: RemoteLevel?
    let rank: RemoteRank?
}
private struct Player: Codable {
    let nickname: String
    let level: Int?
    let rank: String
    let xp: Int
    let checkedAt: Date
}
private struct Point: Codable, Identifiable {
    let id: UUID
    let date: Date
    let xp: Int
    let rank: String
}

@MainActor
private final class RankState: ObservableObject {
    @Published var player: Player?
    @Published var points: [Point] = []
    @Published var loading = false
    @Published var errorText: String?
    private var loadedUID = ""

    func load(uid: String) {
        loadedUID = uid
        errorText = nil
        let defaults = UserDefaults.standard
        player = defaults.data(forKey: "codm.player.\(uid)").flatMap { try? JSONDecoder().decode(Player.self, from: $0) }
        points = defaults.data(forKey: "codm.history.\(uid)").flatMap { try? JSONDecoder().decode([Point].self, from: $0) } ?? []
    }

    func refresh(uid: String) async {
        guard !loading else { return }
        guard Self.validUID(uid) else {
            errorText = "Enter your numeric COD Mobile UID."
            return
        }
        loading = true
        defer { loading = false }
        do {
            guard let url = URL(string: "https://callofdutymobile.vercel.app/user/\(uid)") else { return }
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "CODM", code: 1, userInfo: [NSLocalizedDescriptionKey: "Stats service returned an HTTP error."])
            }
            guard data.count < 64000 else { throw NSError(domain: "CODM", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unexpectedly large response."]) }
            let remote = try JSONDecoder().decode(RemoteProfile.self, from: data)
            guard remote.success, let name = remote.nickname,
                  let rank = remote.rank?.multiplayerRank, let xp = remote.rank?.rating, xp >= 0 else {
                throw NSError(domain: "CODM", code: 3, userInfo: [NSLocalizedDescriptionKey: "Stats were unavailable or their format changed."])
            }
            guard loadedUID == uid else { return }
            let updated = Player(nickname: name, level: remote.level?.current, rank: rank, xp: xp, checkedAt: Date())
            player = updated
            if points.last?.xp != xp || points.last?.rank != rank {
                points.append(Point(id: UUID(), date: updated.checkedAt, xp: xp, rank: rank))
                if points.count > 500 { points.removeFirst(points.count - 500) }
            }
            let encoder = JSONEncoder()
            UserDefaults.standard.set(try encoder.encode(updated), forKey: "codm.player.\(uid)")
            UserDefaults.standard.set(try encoder.encode(points), forKey: "codm.history.\(uid)")
            errorText = nil
        } catch {
            errorText = "Could not refresh: \(error.localizedDescription)"
        }
    }

    static func validUID(_ uid: String) -> Bool {
        (12...22).contains(uid.count) && uid.utf8.allSatisfy { (48...57).contains($0) }
    }

    var lastChange: Int? {
        guard points.count >= 2 else { return nil }
        return points[points.count - 1].xp - points[points.count - 2].xp
    }
}

@main
struct CODMRankApp: App {
    var body: some Scene { WindowGroup { Dashboard().preferredColorScheme(.dark) } }
}

private struct Dashboard: View {
    @AppStorage("codm.uid") private var uid = ""
    @AppStorage("codm.consent") private var consent = false
    @Environment(\.scenePhase) private var phase
    @StateObject private var state = RankState()
    @State private var draftUID = ""
    @State private var showSettings = false

    private let legendaryXP = 8001
    private var connected: Bool { consent && RankState.validUID(uid) }
    private var xp: Int { state.player?.xp ?? 0 }
    private var remaining: Int { max(0, legendaryXP - xp) }
    private var progress: Double { min(1, Double(xp) / Double(legendaryXP)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("SENSEI / RANK").font(.caption.monospaced().bold()).tracking(2).foregroundStyle(Palette.gold)
                            Text("CODM Rank Tracker").font(.system(size: 27, weight: .bold, design: .rounded))
                            Text("UNOFFICIAL MULTIPLAYER COMPANION").font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape").font(.title2).foregroundStyle(.white)
                        }
                        .accessibilityLabel("Settings")
                    }
                    if connected {
                        if let player = state.player {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(player.nickname).font(.title2.bold())
                                Text("\(player.rank)  •  Level \(player.level.map(String.init) ?? "—")")
                                    .foregroundStyle(Palette.muted)
                            }.panel()
                        } else {
                            Text("Connecting to your account…").foregroundStyle(Palette.muted).panel()
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            Text("RANKED XP").font(.caption.monospaced().bold()).foregroundStyle(Palette.muted)
                            HStack(alignment: .firstTextBaseline) {
                                Text(xp.formatted()).font(.system(size: 46, weight: .black, design: .rounded))
                                Spacer()
                                Text("/ \(legendaryXP.formatted())").foregroundStyle(Palette.muted)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(.white.opacity(0.12))
                                    Capsule().fill(Palette.gold).frame(width: max(0, geo.size.width * progress))
                                }
                            }.frame(height: 12)
                            HStack {
                                metric("TO LEGENDARY", remaining.formatted())
                                metric("LATEST CHANGE", state.lastChange.map { $0 > 0 ? "+\($0)" : "\($0)" } ?? "—")
                            }
                            Button {
                                Task { await state.refresh(uid: uid) }
                            } label: {
                                HStack {
                                    if state.loading { ProgressView().tint(.black) }
                                    else { Image(systemName: "arrow.clockwise") }
                                    Text(state.loading ? "Checking…" : "Refresh Live XP")
                                }
                                .frame(maxWidth: .infinity).padding(13).font(.headline)
                                .background(Palette.gold, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.black)
                            }.disabled(state.loading)
                            Text(state.player.map { "Last checked \($0.checkedAt.formatted(date: .abbreviated, time: .shortened))" } ?? "No successful lookup yet")
                                .font(.caption).foregroundStyle(Palette.muted)
                        }.panel()
                        VStack(alignment: .leading, spacing: 12) {
                            Text("XP HISTORY").font(.caption.monospaced().bold())
                            if state.points.count > 1 {
                                Chart(state.points) { point in
                                    LineMark(x: .value("Time", point.date), y: .value("XP", point.xp))
                                        .foregroundStyle(Palette.gold)
                                    PointMark(x: .value("Time", point.date), y: .value("XP", point.xp))
                                        .foregroundStyle(Palette.gold)
                                }
                                .chartYAxis { AxisMarks(position: .leading) }
                                .frame(height: 190)
                            } else {
                                Text("Refresh after your next XP change to start the chart.")
                                    .foregroundStyle(Palette.muted)
                            }
                            Text("Changes reflect the interval between checks, not necessarily one match.")
                                .font(.caption2).foregroundStyle(Palette.muted)
                        }.panel()
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Connect your COD Mobile UID").font(.title2.bold())
                            TextField("Numeric player UID", text: $draftUID)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            Toggle("I agree to send my UID to the unofficial stats provider", isOn: $consent)
                                .font(.subheadline)
                            Button("Connect Read-Only") {
                                uid = draftUID.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                            .disabled(!consent || !RankState.validUID(draftUID))
                            .font(.headline)
                            .foregroundStyle(Palette.gold)
                            Text("The provider is not affiliated with Activision. It receives your UID and IP address. No password is required. Activision restricts unauthorized data collection.")
                                .font(.caption).foregroundStyle(Palette.muted)
                        }.panel()
                    }
                    if let error = state.errorText {
                        Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange).font(.footnote).panel()
                    }
                    Text("Fan-made. No game modification, game traffic interception, account password collection, or background polling.")
                        .font(.caption2).foregroundStyle(Palette.muted)
                }
                .padding(20)
            }
            .background(Palette.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .refreshable { if connected { await state.refresh(uid: uid) } }
            .task(id: "\(uid):\(consent)") {
                state.load(uid: uid)
                draftUID = uid
                if connected { await state.refresh(uid: uid) }
            }
            .onChange(of: phase) { _, value in
                guard value == .active, connected else { return }
                if let checked = state.player?.checkedAt, Date().timeIntervalSince(checked) < 60 { return }
                Task { await state.refresh(uid: uid) }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    Form {
                        Section("Connected account") {
                            LabeledContent("UID", value: uid.isEmpty ? "Not set" : uid)
                            Button("Disconnect") { consent = false; showSettings = false }
                                .foregroundStyle(.red)
                        }
                        Section("About") {
                            Text("Information comes from callofdutymobile.vercel.app, an unofficial service. Availability and permission to use it are not guaranteed.")
                            Link("Activision Terms", destination: URL(string: "https://www.activision.com/legal/terms-of-use")!)
                        }
                    }
                    .navigationTitle("Settings")
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showSettings = false } } }
                }
            }
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(Palette.muted)
            Text(value).font(.system(size: 25, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Palette.background, in: RoundedRectangle(cornerRadius: 11))
    }
}

private extension View {
    func panel() -> some View {
        self.frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Palette.panel, in: RoundedRectangle(cornerRadius: 18))
    }
}
