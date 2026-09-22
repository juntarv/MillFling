import SwiftUI

/// One seeded field per calendar day, a day streak with milestones, and a two-week calendar.
struct DailySowingView: View {
    @EnvironmentObject private var store: FarmStore
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \DailyRunEntity.dayKey, ascending: false)])
    private var days: FetchedResults<DailyRunEntity>

    let onBack: () -> Void
    let onSow: (String) -> Void
    @State private var now = Date()
    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        let _ = store.revision
        let today = DailyRules.dayKey(for: now)
        let field = FieldCatalog.daily(dayKey: today)
        let todayEntry = days.first { $0.dayKey == today }
        let doneToday = todayEntry?.completed ?? false
        let completed = Set(days.filter(\.completed).compactMap(\.dayKey))
        let streak = DailyRules.streak(completed: completed, today: today)
        let best = max(Int(store.stats.bestDailyStreak), streak)

        ZStack(alignment: .top) {
            ArtBackdrop(image: "bg_onboarding", wash: 0.25)
            AmbientMotes(count: 14, color: Palette.sun100).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    ScreenHeader(kicker: streak > 0 ? "\(streak)-day streak" : "A new field every day",
                                 title: "Daily Sowing", onBack: onBack) {
                        SunBadge(done: doneToday, size: 44)
                    }
                    .entrance(0)

                    todayCard(field: field, today: today, entry: todayEntry, done: doneToday)
                        .padding(.top, Space.s1)
                        .entrance(1)

                    streakCard(streak: streak, best: best)
                        .entrance(2)

                    calendar(today: today, completed: completed)
                        .entrance(3)

                    history
                        .entrance(4)
                }
                .screenPadding()
            }

            TopStitchBand()
        }
        .onReceive(ticker) { now = $0 }
    }

    // MARK: today

    private func todayCard(field: FieldDefinition, today: String, entry: DailyRunEntity?, done: Bool) -> some View {
        LinenCard(padding: Space.s3) {
            VStack(alignment: .leading, spacing: 12) {
                MicroLabel(text: DailyRules.longLabel(today), color: Palette.stitchRed)
                Text(done ? "Today's field is sown" : "Today's field")
                    .font(Typo.heavy(28))
                    .foregroundColor(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(field.region.name) layout · \(field.hazardLines.joined(separator: " · "))")
                    .font(Typo.medium(14))
                    .foregroundColor(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                FieldPreview(field: field)
                    .frame(height: CGFloat(field.rows) * 24)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0xFFD873)))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.ink, lineWidth: 2.5))
                HStack(spacing: 8) {
                    StatWell(value: "\(field.quota)", label: "plots", size: 22)
                    StatWell(value: "\(field.pods)", label: "pods", size: 22)
                    StatWell(value: Format.wind(field.wind.base), label: "wind", size: 22)
                }
                if done, let entry {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(Palette.leaf).font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Best today \(Format.number(Int(entry.bestScore)))")
                                .font(Typo.heavy(15)).foregroundColor(Palette.ink)
                            MicroLabel(text: "New field in \(DailyRules.timeUntilTomorrow(from: now))", color: Palette.inkSoft)
                        }
                        Spacer()
                        StarDiamonds(stars: Int(entry.stars), size: 12)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Palette.sun100))
                    Button { onSow(today) } label: { Text("REPLAY FOR A BETTER SCORE") }
                        .buttonStyle(BluePlateButtonStyle())
                } else {
                    if let entry, entry.attempts > 0 {
                        MicroLabel(text: "\(entry.attempts) tr\(entry.attempts == 1 ? "y" : "ies") today — not sown yet", color: Palette.inkSoft)
                    }
                    Button { onSow(today) } label: {
                        HStack(spacing: 10) {
                            Text("SOW TODAY'S FIELD")
                            Image(systemName: "arrow.right").font(.system(size: 18, weight: .black))
                        }
                    }
                    .buttonStyle(PlankButtonStyle(fontSize: 20))
                    .breathe(0.02)
                    MicroLabel(text: "Sow before midnight · +70 bushels on the first clear", color: Palette.inkSoft,
                               size: 9.5, lines: 2, tracking: 1)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: streak

    private func streakCard(streak: Int, best: Int) -> some View {
        LinenCard(padding: Space.s2) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .bottom, spacing: 14) {
                    VStack(alignment: .leading, spacing: 0) {
                        RollingText(text: "\(streak)")
                            .font(Typo.thin(64))
                            .foregroundColor(Palette.ink)
                        MicroLabel(text: streak == 1 ? "day in a row" : "days in a row", color: Palette.inkSoft)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        MicroLabel(text: "Best streak", color: Palette.inkSoft)
                        RollingText(text: "\(best)").font(Typo.thin(30)).foregroundColor(Palette.ink)
                    }
                }
                if let next = DailyRules.nextMilestone(after: streak) {
                    StripedBar(value: Double(streak) / Double(next), height: 12)
                    MicroLabel(text: "\(next - streak) more day\(next - streak == 1 ? "" : "s") to the \(next)-day ribbon", color: Palette.inkSoft)
                } else {
                    MicroLabel(text: "Every streak ribbon is pinned — keep the mill turning", color: Palette.leaf)
                }
                HStack(spacing: 8) {
                    ForEach(DailyRules.milestones, id: \.self) { m in
                        VStack(spacing: 2) {
                            Rosette(earned: best >= m, size: 34)
                                .sway(best >= m ? 4 : 0, period: 2.2, phase: Double(m) * 0.05)
                            MicroLabel(text: "\(m) days", color: best >= m ? Palette.ink : Palette.inkSoft, size: 9)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: calendar

    private func calendar(today: String, completed: Set<String>) -> some View {
        let keys = DailyRules.recentKeys(count: 14, today: today)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "The last two weeks", trailing: "\(keys.filter { completed.contains($0) }.count)/14")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(keys, id: \.self) { key in
                    let entry = days.first { $0.dayKey == key }
                    let done = completed.contains(key)
                    let isToday = key == today
                    VStack(spacing: 3) {
                        MicroLabel(text: DailyRules.shortLabel(key), color: done ? Palette.ink : Palette.inkSoft, size: 8.5)
                        ZStack {
                            if done {
                                Image(systemName: "sun.max.fill").foregroundColor(Palette.sun600).font(.system(size: 18, weight: .bold))
                            } else if isToday {
                                Image(systemName: "circle.dotted").foregroundColor(Palette.ink).font(.system(size: 18, weight: .bold))
                            } else if entry != nil {
                                Image(systemName: "xmark").foregroundColor(Palette.stitchRed).font(.system(size: 14, weight: .black))
                            } else {
                                Circle().fill(Palette.ink.opacity(0.15)).frame(width: 8, height: 8)
                            }
                        }
                        .frame(height: 22)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(RoundedRectangle(cornerRadius: 10).fill(done ? Palette.sun100 : Palette.linen))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(isToday ? Palette.stitchRed : Palette.ink.opacity(0.35),
                                                                            lineWidth: isToday ? 3 : 1.5))
                    .breathe(isToday && !done ? 0.05 : 0)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(DailyRules.longLabel(key)): \(done ? "sown" : (isToday ? "open" : "not sown"))")
                }
            }
            .padding(10)
            .background(LinenSurface(radius: 16))
        }
    }

    // MARK: history

    @ViewBuilder
    private var history: some View {
        let played = days.filter { $0.attempts > 0 }
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Daily results")
            if played.isEmpty {
                EdgeStateCard(art: "icon_app_mark", title: "Your first sunrise",
                              message: "No daily fields yet — sow today's to start a streak. Each morning brings a fresh layout from somewhere in the valley.") {
                    EmptyView()
                }
            } else {
                LinenCard(padding: Space.s2) {
                    VStack(spacing: 0) {
                        ForEach(Array(played.prefix(10).enumerated()), id: \.element.objectID) { index, day in
                            HStack(spacing: 12) {
                                Image(systemName: day.completed ? "sun.max.fill" : "cloud.fill")
                                    .foregroundColor(day.completed ? Palette.sun600 : Palette.lockedArt)
                                    .font(.system(size: 20))
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(DailyRules.longLabel(day.dayKey ?? ""))
                                        .font(Typo.heavy(14)).foregroundColor(Palette.ink)
                                    MicroLabel(text: day.completed ? "Best \(Format.number(Int(day.bestScore))) · \(day.attempts) tr\(day.attempts == 1 ? "y" : "ies")"
                                                                   : "Left fallow · \(day.attempts) tr\(day.attempts == 1 ? "y" : "ies")",
                                               color: Palette.inkSoft, size: 9.5)
                                }
                                Spacer()
                                StarDiamonds(stars: Int(day.stars), size: 10)
                            }
                            .padding(.vertical, 8)
                            if index < min(played.count, 10) - 1 {
                                DashedRule(color: Palette.ink.opacity(0.25))
                            }
                        }
                    }
                }
            }
        }
    }
}

/// The small embroidered sun that stands for Daily Sowing on Mill Hill and in headers.
struct SunBadge: View {
    let done: Bool
    var size: CGFloat = 80
    @Environment(\.motionEnabled) private var motion
    @State private var turn = false

    var body: some View {
        ZStack {
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    Capsule()
                        .fill(Palette.sun500)
                        .overlay(Capsule().strokeBorder(Palette.ink, lineWidth: size * 0.025))
                        .frame(width: size * 0.09, height: size * 0.22)
                        .offset(y: -size * 0.4)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
            }
            .rotationEffect(.degrees(turn ? 30 : 0))
            Circle().fill(Palette.sun300)
                .overlay(Circle().strokeBorder(Palette.ink, lineWidth: size * 0.04))
                .frame(width: size * 0.62, height: size * 0.62)
            Circle()
                .strokeBorder(Palette.stitchRed, style: StrokeStyle(lineWidth: size * 0.025, dash: [size * 0.04, size * 0.04]))
                .frame(width: size * 0.48, height: size * 0.48)
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.24, weight: .black))
                    .foregroundColor(Palette.ink)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            guard motion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { turn = true }
        }
    }
}
