import SwiftUI
import Charts

// CODM Rank Tracker v0.4.0 — rank and XP are read-only, sourced from an unofficial service.
private enum Theme {
    static let ink = Color(red: 0.032, green: 0.041, blue: 0.066)
    static let card = Color(red: 0.090, green: 0.114, blue: 0.158)
    static let elevated = Color(red: 0.125, green: 0.157, blue: 0.204)
    static let yellow = Color(red: 1.00, green: 0.766, blue: 0.251)
    static let orange = Color(red: 1.00, green: 0.49, blue: 0.20)
    static let green = Color(red: 0.35, green: 0.92, blue: 0.68)
    static let red = Color(red: 1.00, green: 0.42, blue: 0.46)
    static let secondary = Color(red: 0.63, green: 0.70, blue: 0.78)
    static let line = Color.white.opacity(0.11)
}

private struct RemoteLevel: Decodable {
    let current: Int?
    let image: String?
}
private struct RemoteRank: Decodable {
    let multiplayerRank: String?
    let rating: Int?
    let image: String?
    let rankClass: Int?
    private enum CodingKeys: String, CodingKey {
        case multiplayerRank, rating, image
        case rankClass = "class"
    }
}
private struct RemoteProfile: Decodable {
    let success: Bool
    let nickname: String?
    let pic: String?
    let countryCode: String?
    let countryId: Int?
    let shortId: String?
    let level: RemoteLevel?
    let rank: RemoteRank?
    // A state-changing dailyGift URL may appear; intentionally never fetched.
}
private struct Player: Codable {
    let nickname: String
    let level: Int?
    let rank: String
    let xp: Int
    let checkedAt: Date
    let rankImageURL: String?
    let avatarURL: String?
    let levelImageURL: String?
    let countryCode: String?
    let countryId: Int?
    let shortId: String?
    let rankClass: Int?
}
private struct Point: Codable, Identifiable {
    let id: UUID
    let date: Date
    let xp: Int
    let rank: String
}
private struct Change: Identifiable {
    let id: UUID
    let date: Date
    let xp: Int
    let difference: Int
    let rank: String
}
private struct Tier: Identifiable {
    let title: String
    let shortName: String
    let threshold: Int
    var id: Int { threshold }
}
private let rankTiers: [Tier] = [
    Tier(title: "Grand Master II", shortName: "GM II", threshold: 6400),
    Tier(title: "Grand Master III", shortName: "GM III", threshold: 6800),
    Tier(title: "Grand Master IV", shortName: "GM IV", threshold: 7200),
    Tier(title: "Grand Master V", shortName: "GM V", threshold: 7600),
    Tier(title: "Legendary", shortName: "LEGEND", threshold: 8001)
]

@MainActor
private final class RankStore: ObservableObject {
    @Published var player: Player?
    @Published var points: [Point] = []
    @Published var loading = false
    @Published var errorText: String?
    private var activeUID = ""

    func load(uid: String) {
        activeUID = uid
        errorText = nil
        let prefs = UserDefaults.standard
        player = prefs.data(forKey: "codm.player.\(uid)").flatMap {
            try? JSONDecoder().decode(Player.self, from: $0)
        }
        points = prefs.data(forKey: "codm.history.\(uid)").flatMap {
            try? JSONDecoder().decode([Point].self, from: $0)
        } ?? []
    }

    func refresh(uid: String) async {
        guard !loading else { return }
        guard Self.validUID(uid) else { errorText = "A numeric COD Mobile UID is required."; return }
        loading = true
        defer { loading = false }
        do {
            guard let url = URL(string: "https://callofdutymobile.vercel.app/user/\(uid)") else { return }
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "CODM", code: 1, userInfo: [NSLocalizedDescriptionKey: "The rank service returned an HTTP error."])
            }
            guard data.count < 64_000 else {
                throw NSError(domain: "CODM", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unexpected response size."])
            }
            let remote = try JSONDecoder().decode(RemoteProfile.self, from: data)
            guard remote.success, let name = remote.nickname,
                  let rank = remote.rank?.multiplayerRank, let xp = remote.rank?.rating, xp >= 0 else {
                throw NSError(domain: "CODM", code: 3, userInfo: [NSLocalizedDescriptionKey: "Rank data is unavailable or its format changed."])
            }
            guard activeUID == uid else { return }
            let updated = Player(
                nickname: name,
                level: remote.level?.current,
                rank: rank, xp: xp, checkedAt: Date(),
                rankImageURL: remote.rank?.image,
                avatarURL: remote.pic,
                levelImageURL: remote.level?.image,
                countryCode: remote.countryCode,
                countryId: remote.countryId,
                shortId: remote.shortId,
                rankClass: remote.rank?.rankClass
            )
            player = updated
            // Record changes, not individual matches. A delta can cover multiple games.
            if points.last?.xp != xp || points.last?.rank != rank {
                points.append(Point(id: UUID(), date: updated.checkedAt, xp: xp, rank: rank))
                if points.count > 1000 { points.removeFirst(points.count - 1000) }
            }
            let encoder = JSONEncoder()
            UserDefaults.standard.set(try encoder.encode(updated), forKey: "codm.player.\(uid)")
            UserDefaults.standard.set(try encoder.encode(points), forKey: "codm.history.\(uid)")
            errorText = nil
        } catch {
            errorText = "Live stats unavailable: \(error.localizedDescription). Showing the last saved reading."
        }
    }

    static func validUID(_ uid: String) -> Bool {
        (12...22).contains(uid.count) && uid.utf8.allSatisfy { (48...57).contains($0) }
    }

    var changes: [Change] {
        guard points.count >= 2 else { return [] }
        return (1..<points.count).map { index in
            let now = points[index]
            return Change(id: now.id, date: now.date, xp: now.xp,
                          difference: now.xp - points[index - 1].xp, rank: now.rank)
        }
    }
    var latestChange: Int? { changes.last?.difference }
    var highXP: Int? { points.map(\.xp).max() }
    var totalPositive: Int { changes.filter { $0.difference > 0 }.reduce(0) { $0 + $1.difference } }
    var totalNegative: Int { changes.filter { $0.difference < 0 }.reduce(0) { $0 + $1.difference } }
    var bestIncrease: Int? { changes.map(\.difference).filter { $0 > 0 }.max() }
    var positiveAverage: Int? {
        let positives = changes.filter { $0.difference > 0 }
        guard !positives.isEmpty else { return nil }
        return Int((Double(positives.reduce(0) { $0 + $1.difference }) / Double(positives.count)).rounded())
    }
    var todayNet: Int? {
        let today = points.filter { Calendar.current.isDateInToday($0.date) }
        guard today.count > 1, let first = today.first, let last = today.last else { return nil }
        return last.xp - first.xp
    }
    var weekNet: Int? {
        let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
        let filtered = points.filter { $0.date >= cutoff }
        guard filtered.count > 1, let first = filtered.first, let last = filtered.last else { return nil }
        return last.xp - first.xp
    }
    var netRecorded: Int? {
        guard let first = points.first, let last = points.last, points.count > 1 else { return nil }
        return last.xp - first.xp
    }
    var largestDrop: Int? { changes.map(\.difference).filter { $0 < 0 }.min() }
    var firstDate: Date? { points.first?.date }

    var historyCSV: String {
        let formatter = ISO8601DateFormatter()
        var output = ["timestamp_utc,multiplayer_xp,rank,change_since_previous_reading"]
        for (index, point) in points.enumerated() {
            let delta = index == 0 ? "" : String(point.xp - points[index - 1].xp)
            // Only locally generated fields go into this export.
            let safeRank = "\"" + point.rank.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            output.append("\(formatter.string(from: point.date)),\(point.xp),\(safeRank),\(delta)")
        }
        return output.joined(separator: "\n")
    }
}

@main
struct CODMRankApp: App {
    var body: some Scene { WindowGroup { Dashboard().preferredColorScheme(.dark) } }
}

private enum IntelPage: String, CaseIterable, Identifiable {
    case command = "COMMAND"
    case identity = "PLAYER"
    case analytics = "ANALYTICS"
    case archive = "HISTORY"
    var id: String { rawValue }
    var iconName: String {
        switch self {
        case .command: return "scope"
        case .identity: return "person.crop.square.fill"
        case .analytics: return "chart.xyaxis.line"
        case .archive: return "clock.arrow.circlepath"
        }
    }
}

private enum HistoryPeriod: String, CaseIterable, Identifiable {
    case week = "7 DAYS"
    case all = "ALL"
    var id: String { rawValue }
}

private struct Dashboard: View {
    @AppStorage("codm.uid") private var uid = ""
    @AppStorage("codm.consent") private var consent = false
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = RankStore()
    @State private var showSettings = false
    @State private var draftUID = ""
    @State private var period: HistoryPeriod = .all
    @State private var projectedXP = 50
    @State private var selectedPage: IntelPage = .command

    private let legendary = 8001
    private var connected: Bool { consent && RankStore.validUID(uid) }
    private var xp: Int { store.player?.xp ?? 0 }
    private var remaining: Int { max(0, legendary - xp) }
    private var nextTier: Tier? { rankTiers.first { xp < $0.threshold } }
    private var overallProgress: Double { min(1, Double(xp) / Double(legendary)) }
    private var plotPoints: [Point] {
        if period == .all { return store.points }
        let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
        return store.points.filter { $0.date >= cutoff }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 19) {
                    header
                    if connected {
                        intelNavigation
                        if let player = store.player {
                            switch selectedPage {
                            case .command:
                                hero(player)
                                overview
                                climb
                                goalCalculator
                            case .identity:
                                identityPanel(player)
                                providerPanel(player)
                            case .analytics:
                                trends
                                historySummary
                                overview
                            case .archive:
                                historyArchive
                                history
                                providerPanel(player)
                            }
                        } else {
                            HStack(spacing: 12) {
                                ProgressView().tint(Theme.yellow)
                                Text("Retrieving your CODM rank…")
                            }.frame(maxWidth: .infinity).card()
                        }
                    } else { connectCard }
                    if let error = store.errorText {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote).foregroundStyle(Theme.orange).card()
                    }
                    Text("FAN PROJECT • ONE APP FOR AVAILABLE LIVE STATS + LOCAL XP HISTORY • Unofficial provider.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.secondary).padding(.horizontal, 4)
                        .padding(.bottom, 22)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
            }
            .background(OpsBackdrop().ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .refreshable { if connected { await store.refresh(uid: uid) } }
            .task(id: "\(uid):\(consent)") {
                draftUID = uid
                store.load(uid: uid)
                if connected { await store.refresh(uid: uid) }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active, connected else { return }
                if let last = store.player?.checkedAt, Date().timeIntervalSince(last) < 60 { return }
                Task { await store.refresh(uid: uid) }
            }
            .sheet(isPresented: $showSettings) { settings }
        }
    }

    private var intelNavigation: some View {
        HStack(spacing: 6) {
            ForEach(IntelPage.allCases) { page in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { selectedPage = page }
                } label: {
                    VStack(spacing: 7) {
                        Image(systemName: page.iconName)
                            .font(.system(size: 17, weight: .bold))
                        Text(page.rawValue)
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .minimumScaleFactor(0.7).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(selectedPage == page ? Theme.ink : Theme.secondary)
                    .background(selectedPage == page ? Theme.yellow : Theme.elevated,
                                in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show \(page.rawValue.lowercased()) dashboard")
            }
        }
        .padding(5)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.yellow.opacity(0.25)))
    }

    private var header: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Theme.yellow)
                    .frame(width: 49, height: 49)
                    .rotationEffect(.degrees(8))
                Image(systemName: "scope")
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(Theme.ink)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Rectangle().fill(Theme.yellow).frame(width: 17, height: 2)
                    Text("SENSEI  /  TACTICAL DATA")
                        .tracking(1.7)
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.yellow)
                }
                Text("RANK COMMAND")
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .tracking(-0.7)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            Spacer(minLength: 1)
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .frame(width: 45, height: 45)
                    .background(Theme.elevated, in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.yellow.opacity(0.3), lineWidth: 1))
            }
            .foregroundStyle(Theme.yellow)
            .accessibilityLabel("Account and settings")
        }
        .padding(.bottom, 3)
    }

    private func hero(_ player: Player) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 23)
                .fill(LinearGradient(colors: [
                    Color(red: 0.18, green: 0.20, blue: 0.21),
                    Theme.card,
                    Color(red: 0.12, green: 0.11, blue: 0.13)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
            DiagonalCut().stroke(Theme.yellow.opacity(0.07), lineWidth: 1)
                .clipShape(RoundedRectangle(cornerRadius: 23))
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 7) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .foregroundStyle(Theme.yellow)
                    Text("MULTIPLAYER  /  RANKED")
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.88))
                    Spacer()
                    Circle().fill(Theme.green).frame(width: 7, height: 7)
                    Text("CONNECTED")
                        .foregroundStyle(Theme.green)
                }
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                HStack(spacing: 5) {
                    RankMedal(image: player.rankImageURL, rank: player.rank)
                        .frame(width: 123, height: 128)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("CURRENT DIVISION")
                            .foregroundStyle(Theme.secondary)
                            .tracking(1.1)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                        Text(player.rank.uppercased())
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.yellow)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        Text(player.nickname)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        HStack(spacing: 5) {
                            Image(systemName: "person.crop.square.filled.and.at.rectangle")
                            Text("LVL \(player.level.map(String.init) ?? "—")")
                        }
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.secondary)
                    }
                    Spacer(minLength: 0)
                }
                Rectangle().fill(Theme.yellow.opacity(0.3)).frame(height: 1)
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CURRENT RANK XP")
                            .foregroundStyle(Theme.secondary)
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .tracking(1)
                        Text(xp.formatted())
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .contentTransition(.numericText())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    Spacer(minLength: 6)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("LEGENDARY")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Theme.secondary)
                        Text(legendary.formatted())
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.yellow)
                    }
                }
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule().fill(LinearGradient(colors: [Theme.yellow, Theme.orange],
                                                     startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, geometry.size.width * overallProgress))
                            .animation(.easeInOut(duration: 0.75), value: overallProgress)
                        ForEach([6400, 6800, 7200, 7600], id: \.self) { milestone in
                            Rectangle()
                                .fill(Theme.ink.opacity(0.65))
                                .frame(width: 3, height: 13)
                                .position(x: geometry.size.width * Double(milestone) / Double(legendary), y: 7)
                        }
                    }
                }.frame(height: 14)
                HStack(alignment: .center) {
                    Label("\(Int((overallProgress * 100).rounded()))% COMPLETE", systemImage: "bolt.fill")
                        .foregroundStyle(Theme.yellow)
                    Spacer()
                    Text("\(remaining.formatted()) XP TO LEGENDARY")
                        .foregroundStyle(.white.opacity(0.78))
                }
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                HStack(spacing: 9) {
                    Image(systemName: "target")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.yellow)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(nextTier?.title.uppercased() ?? "LEGENDARY UNLOCKED")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        Text(nextTier.map { "\($0.threshold - xp) XP until next promotion" } ?? "Maximum ranked division reached")
                            .font(.system(size: 10)).foregroundStyle(Theme.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.2").foregroundStyle(Theme.yellow)
                }
                .padding(11)
                .background(Theme.ink.opacity(0.58), in: RoundedRectangle(cornerRadius: 11))
                Button {
                    Task { await store.refresh(uid: uid) }
                } label: {
                    HStack {
                        if store.loading { ProgressView().tint(Theme.ink) }
                        else { Image(systemName: "arrow.triangle.2.circlepath") }
                        Text(store.loading ? "CONTACTING SERVICE…" : "SYNC LIVE XP")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 17)
                    .frame(height: 50)
                    .background(
                        LinearGradient(colors: [Theme.yellow, Color(red: 1, green: 0.65, blue: 0.13)],
                                       startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 11))
                }
                .disabled(store.loading)
                HStack(spacing: 5) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Last fetched: \(player.checkedAt.formatted(date: .abbreviated, time: .shortened))")
                    Spacer()
                    Text("V0.4")
                }
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.secondary)
            }
            .padding(18)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 23)
                .stroke(LinearGradient(colors: [Theme.yellow.opacity(0.65), Theme.yellow.opacity(0.04), Theme.yellow.opacity(0.28)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.25)
        )
        .shadow(color: Theme.yellow.opacity(0.08), radius: 20)
    }


    private var overview: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("PERFORMANCE SNAPSHOT", subtitle: "Based on recorded rank checks")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                stat("LATEST XP CHANGE", signed(store.latestChange), "arrow.up.right", Theme.yellow,
                     "Since previous changed reading")
                stat("TODAY'S NET XP", signed(store.todayNet), "sun.max.fill", Theme.green,
                     "Only checks recorded today")
                stat("7-DAY NET XP", signed(store.weekNet), "calendar", Theme.orange,
                     "Within stored 7-day checks")
                stat("HIGHEST OBSERVED", store.highXP.map { $0.formatted() } ?? "—",
                     "trophy.fill", Theme.yellow, "From saved readings")
                stat("TOTAL XP GAINED", store.changes.isEmpty ? "—" : "+\(store.totalPositive.formatted())",
                     "chart.line.uptrend.xyaxis", Theme.green, "Positive changes recorded")
                stat("TOTAL XP LOST", store.changes.isEmpty ? "—" : store.totalNegative.formatted(),
                     "chart.line.downtrend.xyaxis", Theme.red, "Negative changes recorded")
            }
        }
    }

    private func stat(_ title: String, _ number: String, _ symbol: String, _ accent: Color, _ info: String) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 17)
                .fill(LinearGradient(colors: [accent.opacity(0.16), Theme.card, Theme.card],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: symbol)
                .font(.system(size: 63, weight: .ultraLight))
                .foregroundStyle(accent.opacity(0.09))
                .offset(x: 8, y: 4)
                .clipped()
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Image(systemName: symbol)
                        .foregroundStyle(accent)
                        .font(.system(size: 17, weight: .bold))
                    Spacer()
                    Circle().fill(accent).frame(width: 5, height: 5)
                    Circle().fill(accent.opacity(0.4)).frame(width: 5, height: 5)
                }
                Spacer(minLength: 4)
                Text(number)
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(accent)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(info)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, minHeight: 151)
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(accent.opacity(0.23), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }


    private var climb: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("PROMOTION ROUTE", subtitle: "Five checkpoints to Legendary")
            if let next = nextTier {
                HStack(spacing: 12) {
                    Image(systemName: "scope")
                        .font(.system(size: 25, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 49, height: 49)
                        .background(Theme.yellow, in: RoundedRectangle(cornerRadius: 11))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NEXT RANK")
                            .tracking(1)
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Theme.secondary)
                        Text(next.title.uppercased())
                            .font(.system(size: 17, weight: .black, design: .rounded))
                    }
                    Spacer(minLength: 3)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(max(0, next.threshold - xp).formatted())")
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.yellow)
                        Text("XP LEFT")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Theme.secondary)
                    }
                }
                .padding(12)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 13))
            } else {
                Label("LEGENDARY REACHED", systemImage: "crown.fill")
                    .font(.title3.bold()).foregroundStyle(Theme.yellow)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(rankTiers) { tier in
                        let completed = xp >= tier.threshold
                        let upcoming = nextTier?.id == tier.id
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(completed ? Theme.green.opacity(0.18) : upcoming ? Theme.yellow.opacity(0.20) : Theme.elevated)
                                    .frame(width: 52, height: 52)
                                Circle()
                                    .stroke(completed ? Theme.green : upcoming ? Theme.yellow : Theme.line, lineWidth: 1.5)
                                    .frame(width: 52, height: 52)
                                Image(systemName: completed ? "checkmark.seal.fill" : tier.threshold == legendary ? "crown.fill" : "shield.fill")
                                    .font(.system(size: 23))
                                    .foregroundStyle(completed ? Theme.green : upcoming ? Theme.yellow : Theme.secondary)
                            }
                            Text(tier.shortName)
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(upcoming ? Theme.yellow : .white)
                            Text(tier.threshold.formatted())
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Theme.secondary)
                        }
                        .frame(width: 69)
                    }
                }
                .padding(.vertical, 5)
            }
            Text("Markers are the published rank-XP thresholds. Live rank comes from the provider.")
                .font(.system(size: 10)).foregroundStyle(Theme.secondary)
        }
        .card()
    }


    private var trends: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("XP TREND", subtitle: "\(store.points.count) saved readings with distinct XP/rank")
                Spacer()
                Picker("Time range", selection: $period) {
                    ForEach(HistoryPeriod.allCases) { item in Text(item.rawValue).tag(item) }
                }
                .pickerStyle(.segmented)
                .frame(width: 126)
            }
            if plotPoints.count > 1 {
                Chart(plotPoints) { point in
                    AreaMark(x: .value("Time", point.date), yStart: .value("Base", plotPoints.map(\.xp).min() ?? 0), yEnd: .value("XP", point.xp))
                        .foregroundStyle(LinearGradient(colors: [Theme.yellow.opacity(0.28), Theme.yellow.opacity(0.01)],
                                                        startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Time", point.date), y: .value("XP", point.xp))
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .foregroundStyle(Theme.yellow)
                    PointMark(x: .value("Time", point.date), y: .value("XP", point.xp))
                        .foregroundStyle(Theme.yellow)
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
                .frame(height: 205)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "waveform.path.ecg.rectangle")
                        .font(.system(size: 30)).foregroundStyle(Theme.yellow)
                    Text("Your XP trend builds as your rank changes.")
                        .multilineTextAlignment(.center).foregroundStyle(Theme.secondary)
                    Text("Play, then sync to add another reading.")
                        .font(.caption).foregroundStyle(Theme.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 170)
            }
            Rectangle().fill(Theme.line).frame(height: 1)
            HStack(spacing: 5) {
                compactMetric("BEST INCREASE", store.bestIncrease.map { "+\($0)" } ?? "—")
                compactMetric("AVG POSITIVE CHANGE", store.positiveAverage.map { "+\($0)" } ?? "—")
                compactMetric("RECORDED CHANGES", store.changes.count.formatted())
            }
            Text("Intervals between checks may include multiple matches. They are not win/loss or per-match statistics.")
                .font(.system(size: 10)).foregroundStyle(Theme.secondary)
        }.card()
    }

    private func compactMetric(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Text(name).font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.secondary).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var goalCalculator: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionTitle("LEGENDARY PLANNER", subtitle: "Hypothetical wins — not your actual match average")
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("ASSUMED XP PER WIN")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundStyle(Theme.secondary)
                    Text("+\(projectedXP)")
                        .font(.system(size: 32, weight: .black, design: .rounded)).foregroundStyle(Theme.yellow)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text("WINS TO LEGENDARY")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundStyle(Theme.secondary)
                    Text(remaining == 0 ? "0" : "\((remaining + projectedXP - 1) / projectedXP)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                }
            }
            HStack(spacing: 8) {
                ForEach([30, 40, 50, 60, 70], id: \.self) { gain in
                    Button("+\(gain)") { projectedXP = gain }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .foregroundStyle(projectedXP == gain ? Theme.ink : Theme.secondary)
                        .background(projectedXP == gain ? Theme.yellow : Theme.elevated,
                                    in: RoundedRectangle(cornerRadius: 9))
                }
            }
            Text("Winning XP varies; losses and bonuses change the total. This calculator uses your chosen XP assumption.")
                .font(.system(size: 10)).foregroundStyle(Theme.secondary)
        }.card()
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("RECENT RANK CHANGES", subtitle: "Saved automatically on this iPhone")
            if store.changes.isEmpty {
                Text("No XP changes saved yet. Your existing baseline is preserved; sync again after gaining or losing points.")
                    .font(.subheadline).foregroundStyle(Theme.secondary)
            } else {
                ForEach(Array(store.changes.suffix(8).reversed())) { change in
                    HStack(spacing: 12) {
                        Image(systemName: change.difference >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundStyle(change.difference >= 0 ? Theme.green : Theme.red)
                            .frame(width: 35, height: 35)
                            .background(Theme.elevated, in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(change.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12, weight: .semibold))
                            Text(change.rank).font(.system(size: 11)).foregroundStyle(Theme.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(signed(change.difference))
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(change.difference >= 0 ? Theme.green : Theme.red)
                            Text("\(change.xp.formatted()) XP")
                                .font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.secondary)
                        }
                    }
                    if change.id != store.changes.last?.id { Rectangle().fill(Theme.line).frame(height: 1) }
                }
            }
        }.card()
    }

    private var connectCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Image(systemName: "lock.shield.fill").font(.system(size: 36)).foregroundStyle(Theme.yellow)
            Text("CONNECT YOUR CODM ACCOUNT").font(.title2.bold())
            Text("Read your Multiplayer rank without a game password. Requires your numeric UID and your consent to contact the unofficial stats service.")
                .font(.subheadline).foregroundStyle(Theme.secondary)
            TextField("Enter player UID", text: $draftUID)
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
            Toggle("Allow sending my UID to the unofficial provider", isOn: $consent)
                .tint(Theme.yellow).font(.footnote)
            Button("CONNECT READ-ONLY") {
                uid = draftUID.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .disabled(!consent || !RankStore.validUID(draftUID))
            .frame(maxWidth: .infinity).padding(14)
            .font(.system(size: 14, weight: .heavy, design: .monospaced))
            .foregroundStyle(Theme.ink)
            .background(Theme.yellow, in: RoundedRectangle(cornerRadius: 11))
            .opacity(consent && RankStore.validUID(draftUID) ? 1 : 0.45)
            Text("The provider receives the UID and IP address. It is not affiliated with Activision. No account credentials are collected.")
                .font(.caption).foregroundStyle(Theme.secondary)
        }.card()
    }

    private var settings: some View {
        NavigationStack {
            Form {
                Section("Connected player") {
                    LabeledContent("Nickname", value: store.player?.nickname ?? "—")
                    LabeledContent("UID", value: uid.isEmpty ? "Not connected" : uid)
                    LabeledContent("Saved changes", value: store.changes.count.formatted())
                    Button("Disconnect lookup") {
                        consent = false
                        showSettings = false
                    }.foregroundStyle(.red)
                }
                Section("Data transparency") {
                    Text("Rank, XP and level are returned by a third-party API. Charts and snapshots use local saved readings. We cannot retrieve actual match results, K/D, win rate, or in-game leaderboard positions from this endpoint.")
                    Text("The service is unofficial and its availability and authorization are not guaranteed. It receives your UID and IP when you sync. No background polling or game modification.")
                    Link("Activision Terms", destination: URL(string: "https://www.activision.com/legal/terms-of-use")!)
                }
                Section("Version") { Text("CODM Rank Tracker v0.4.0") }
            }
            .navigationTitle("Tracker Settings")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showSettings = false } } }
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Rectangle()
                .fill(LinearGradient(colors: [Theme.yellow, Theme.orange],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 3, height: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.secondary)
            }
        }
    }


    private func signed(_ value: Int?) -> String {
        guard let value else { return "—" }
        return signed(value)
    }
    private func signed(_ value: Int) -> String {
        value > 0 ? "+\(value.formatted())" : value.formatted()
    }
}

private extension View {
    func card() -> some View {
        self.frame(maxWidth: .infinity, alignment: .leading)
            .padding(17)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 21))
            .overlay(RoundedRectangle(cornerRadius: 21).stroke(Theme.line, lineWidth: 0.8))
    }
}


private struct DiagonalCut: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for x in stride(from: -rect.height, through: rect.width, by: 24.0) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.height))
        }
        return path
    }
}

private struct OpsBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Theme.ink
                RadialGradient(colors: [Theme.yellow.opacity(0.12), .clear],
                               center: .topTrailing, startRadius: 10, endRadius: 390)
                DiagonalCut()
                    .stroke(Theme.yellow.opacity(0.025), lineWidth: 0.8)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "scope")
                            .font(.system(size: 230, weight: .ultraLight))
                            .foregroundStyle(Theme.yellow.opacity(0.027))
                            .offset(x: 45, y: 20)
                    }
                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

private struct RankMedal: View {
    let image: String?
    let rank: String

    private var remoteURL: URL? {
        guard let image, let url = URL(string: image), url.scheme == "https",
              let hostname = url.host?.lowercased(),
              hostname == "codashop.com" || hostname.hasSuffix(".codashop.com") else { return nil }
        return url
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.yellow.opacity(0.3), Theme.yellow.opacity(0.02), .clear],
                                     center: .center, startRadius: 4, endRadius: 65))
                .frame(width: 128, height: 128)
            Circle()
                .trim(from: 0.05, to: 0.42)
                .stroke(Theme.yellow.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 105, height: 105)
                .rotationEffect(.degrees(-105))
            Circle()
                .trim(from: 0.1, to: 0.42)
                .stroke(Theme.orange.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 105, height: 105)
                .rotationEffect(.degrees(90))
            if let url = remoteURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let rendered):
                        rendered.resizable().scaledToFit().padding(4)
                    case .empty, .failure:
                        fallback
                    @unknown default:
                        fallback
                    }
                }
                .frame(width: 112, height: 112)
            } else {
                fallback.frame(width: 110, height: 110)
            }
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundStyle(Theme.yellow)
                .offset(y: 55)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current rank emblem: \(rank)")
    }

    private var fallback: some View {
        ZStack {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 75, weight: .light))
                .foregroundStyle(LinearGradient(colors: [Theme.yellow, Theme.orange, Theme.yellow],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Theme.yellow.opacity(0.35), radius: 6)
            Image(systemName: "star.circle.fill")
                .font(.system(size: 29))
                .foregroundStyle(.white)
                .shadow(color: Theme.ink.opacity(0.7), radius: 4)
        }
    }
}
