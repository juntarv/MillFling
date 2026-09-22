import SwiftUI

enum Route: Equatable {
    case onboarding(replay: Bool)
    case menu
    case fields(briefing: Int?)
    case game
    case almanac
    case ribbons
    case settings
    case daily
    case farmBook(ledger: Bool)
    case paints
    case region(RegionKey)
    case guide
    case seed(String)
    case charts
}

/// Orchestrates onboarding → Mill Hill and every screen after it, plus the `-screenshotTour` loop.
struct HomeView: View {
    @StateObject private var store = FarmStore(controller: LaunchOptions.screenshotTour ? .tour : .shared)
    @StateObject private var game = GameViewModel()
    @State private var route: Route?
    /// Screens to return to with the back plates (never contains the game or onboarding).
    @State private var history: [Route] = []

    var body: some View {
        let motion = store.preference.animationsOn
        ZStack {
            Palette.blue900.ignoresSafeArea()
            if let route {
                screen(for: route)
                    .transition(motion ? .asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.02)),
                                                     removal: .opacity) : .identity)
                    .id(routeID(route))
            }
        }
        .animation(motion ? .easeInOut(duration: 0.28) : nil, value: route)
        .environment(\.motionEnabled, motion)
        .environmentObject(store)
        .environment(\.managedObjectContext, store.context)
        .preferredColorScheme(.light)
        .onAppear(perform: boot)
        .task { await runScreenshotTour() }
    }

    @ViewBuilder
    private func screen(for route: Route) -> some View {
        switch route {
        case .onboarding(let replay):
            OnboardingView(replay: replay) {
                if !replay { store.completeOnboarding() }
                if replay { back() } else { root(.menu) }
            }
        case .menu:
            MillHillView(
                onSow: { target in
                    switch target {
                    case .field(let index): play(field: index)
                    case .gated: open(.fields(briefing: nil))
                    case .allSown: open(.daily)
                    }
                },
                onFields: { open(.fields(briefing: nil)) },
                onRibbons: { open(.ribbons) },
                onAlmanac: { open(.almanac) },
                onSettings: { open(.settings) },
                onDaily: { open(.daily) },
                onFarmBook: { open(.farmBook(ledger: false)) })
        case .fields(let briefing):
            FieldMapView(onBack: back,
                         onPlay: { play(field: $0) },
                         onAlmanac: { open(.almanac) },
                         onRegion: { open(.region($0)) },
                         onGuide: { open(.guide) },
                         initialBriefing: briefing)
        case .game:
            GameContainerView(
                vm: game,
                onFieldMap: { leaveGame(to: .fields(briefing: nil)) },
                onMenu: { leaveGame(to: .menu) },
                onPlayField: { play(field: $0) },
                onDaily: { leaveGame(to: .daily) })
        case .almanac:
            SeedAlmanacView(onBack: back, onSeed: { open(.seed($0)) })
        case .ribbons:
            RibbonWallView(onBack: back)
        case .settings:
            SettingsView(
                onBack: back,
                onAlmanac: { open(.almanac) },
                onPaints: { open(.paints) },
                onGuide: { open(.guide) },
                onReplayTour: { open(.onboarding(replay: true)) },
                onResetDone: { root(.onboarding(replay: false)) })
        case .daily:
            DailySowingView(onBack: back, onSow: { playDaily(dayKey: $0) })
        case .farmBook(let ledger):
            FarmBookView(startOnLedger: ledger,
                         onBack: back,
                         onPaints: { open(.paints) },
                         onPlayField: { play(field: $0) },
                         onDaily: { open(.daily) },
                         onRegion: { open(.region($0)) },
                         onGuide: { open(.guide) },
                         onCharts: { open(.charts) },
                         onSeed: { open(.seed($0)) })
        case .paints:
            PaintShedView(onBack: back)
        case .region(let key):
            RegionDetailView(regionKey: key,
                             onBack: back,
                             onPlay: { play(field: $0) },
                             onAlmanac: { open(.almanac) },
                             onGuide: { open(.guide) })
        case .guide:
            FieldGuideView(onBack: back, onPlay: { play(field: $0) })
        case .seed(let key):
            SeedDetailView(seedKey: key, onBack: back, onBriefing: { open(.fields(briefing: $0)) })
        case .charts:
            HarvestChartsView(onBack: back, onSeed: { open(.seed($0)) }, onPlay: { play(field: $0) })
        }
    }

    private func routeID(_ route: Route) -> String {
        switch route {
        case .onboarding(let replay): return replay ? "tour-replay" : "tour"
        case .menu: return "menu"
        case .fields(let briefing): return "fields-\(briefing.map { "\($0)" } ?? "map")"
        case .game: return "game"
        case .almanac: return "almanac"
        case .ribbons: return "ribbons"
        case .settings: return "settings"
        case .daily: return "daily"
        case .farmBook(let ledger): return ledger ? "farmbook-ledger" : "farmbook"
        case .paints: return "paints"
        case .region(let key): return "region-\(key.rawValue)"
        case .guide: return "guide"
        case .seed(let key): return "seed-\(key)"
        case .charts: return "charts"
        }
    }

    // MARK: navigation

    private func boot() {
        guard route == nil else { return }
        game.attach(store: store)
        Haptics.shared.enabled = store.preference.hapticsOn
        if LaunchOptions.screenshotTour {
            store.seedTourProgress()
            route = .menu
        } else {
            route = store.preference.firstLaunchCompleted ? .menu : .onboarding(replay: false)
        }
    }

    /// Forward navigation: remembers where we came from.
    private func open(_ next: Route) {
        if let current = route, current != next, current != .game, !isOnboarding(current) {
            if history.last != current { history.append(current) }
            if history.count > 12 { history.removeFirst(history.count - 12) }
        }
        if route == .game && next != .game { game.leave() }
        route = next
    }

    /// Back plates: return to the previous screen, or Mill Hill.
    private func back() {
        if route == .game { game.leave() }
        route = history.popLast() ?? .menu
    }

    /// Replace the whole stack (menu after onboarding, reset, tour).
    private func root(_ next: Route) {
        history.removeAll()
        if route == .game && next != .game { game.leave() }
        route = next
    }

    private func isOnboarding(_ r: Route) -> Bool {
        if case .onboarding = r { return true }
        return false
    }

    private func play(field index: Int) {
        guard store.isUnlocked(field: index) || LaunchOptions.demoMode else { return }
        game.start(fieldIndex: index)
        if let current = route, current != .game, !isOnboarding(current), history.last != current {
            history.append(current)
        }
        route = .game
    }

    private func playDaily(dayKey: String) {
        game.startDaily(dayKey: dayKey)
        if let current = route, current != .game, history.last != current { history.append(current) }
        route = .game
    }

    private func leaveGame(to next: Route) {
        game.leave()
        if let last = history.last, last == next { history.removeLast() }
        route = next
    }

    // MARK: screenshot tour — 3 s per screen, looping, zero interaction

    private func runScreenshotTour() async {
        guard LaunchOptions.screenshotTour else { return }
        try? await Task.sleep(nanoseconds: 600_000_000)
        let briefingField = store.currentFieldIndex
        let currentRegion = FieldCatalog.field(briefingField).region.key
        let steps: [Route] = [.menu, .game, .fields(briefing: nil), .fields(briefing: briefingField), .region(currentRegion),
                              .daily, .farmBook(ledger: false), .farmBook(ledger: true), .charts, .ribbons, .almanac,
                              .seed(store.selectedSeed.key), .guide, .paints, .settings]
        var index = 0
        while !Task.isCancelled {
            let step = steps[index % steps.count]
            await MainActor.run {
                if step == .game {
                    game.startDemo()
                    route = .game
                } else {
                    root(step)
                }
            }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            index += 1
        }
    }
}
