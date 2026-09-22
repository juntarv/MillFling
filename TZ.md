**Concept:** MillFling is an offline one-thumb arcade game where you let seed pods fly off the turning sails of a folk windmill and burst them in mid-air, so the scattering seeds land on every plot of a bright blue-and-gold field.

## 1. Game in one loop

1. A seed pod rides the tip of a turning windmill sail.
2. **Tap #1 — release.** The pod leaves on the tangent of the sail; release angle and sail speed decide the whole trajectory (early = high and short, late = flat and far).
3. **Tap #2 — burst.** In flight the pod splits into 3–6 seeds in a fan; the later the burst, the tighter the spread and the further downrange it lands.
4. Wind drags every airborne seed sideways. A seed landing on an unsown plot sows it; seeds landing on ponds, stone walls, roads or in a crow's path are lost.
5. Sow the field's plot quota before the pods run out. Leftover pods, "true sows" (dead-centre hits) and an unbroken scoring streak decide the 1–3 ribbon stars.

One thumb, portrait, no timers to read, no text to parse mid-flight.

## 2. Screens

| # | Screen | Purpose |
|---|--------|---------|
| 1 | **Onboarding** (3 steps) | Teaches release, burst and wind in three illustrated steps; sets `firstLaunchCompleted`. |
| 2 | **Mill Hill** (main menu) | The home scene: the mill, the hand-painted SOW sign that resumes the current field, and diegetic navigation objects (staked rosette → Ribbon Wall, map board on a post → Field Map, seed crate → Almanac, tool basket → Settings), with lifetime stats embroidered on a towel hung across the hill. |
| 3 | **Field Map** | Vertically scrolling path of 36 field nodes grouped in 4 regions; shows stars per field, the current field, locked fields and the star gate to the next region. |
| 4 | **Sowing Run** (gameplay) | The single `SKScene` in a `SpriteView` with a SwiftUI HUD: score, plot quota bar, pods left, wind readout, streak flag, pause. |
| 5 | **Sails Held** (pause overlay) | SwiftUI overlay over the paused scene: run stats, Resume / Restart / Field Map, haptics switch. |
| 6 | **Harvest Report** (results) | End-of-run overlay in two states — *Field sown* (stars, score roll-up, new-best stamp, ribbon earned, Next Field) and *Field left fallow* (what was missed, Try Again / Field Map). |
| 7 | **Seed Almanac** | Catalogue of 12 seed varieties: the featured seed in the hopper with its stat bars and lore, plus the rest of the crate with unlock requirements. Choosing a seed really changes flight. |
| 8 | **Ribbon Wall** (achievements) | 16 ribbons pinned on the barn door: newest ribbon highlighted, overall progress, earned vs. locked rosettes with their goals. |
| 9 | **Settings** | Haptics, Animations, seed-in-hopper and mill-paint shortcuts, replay the tour, Reset progress (confirmed). |
| 10 | **Field Briefing** (overlay on the Field Map) | Before every campaign run: plot-grid preview, quota / pods / sail speed, wind profile, hazards, the three star targets, your record and last five runs on that field, seed-in-hopper switcher, SOW. |
| 11 | **Daily Sowing** | One date-seeded field per calendar day, day streak with 3/7/14/30 milestones, two-week calendar, daily results; completed-today state with countdown. |
| 12 | **Farm Book** | Overview (farmer rank + bushels, rank ladder, 12 lifetime stats, 8 region progress bars, closest ribbons) and Ledger (every run, filters All/Sown/Fallow/Daily, run detail with replay). |
| 14 | **Region Detail** | One region in depth: completion ring, stars / three-star count / clear bonus, its nine fields with mini plot previews and best scores (tap → Field Briefing), region records (best total, tries, sown rate, favourite seed, last played). Reached from the map's region gates and header, and the Farm Book region list. Locked and not-yet-sown states. |
| 15 | **Field Guide** | Library of 13 entries on four shelves (Plots, Hazards, Air, Skills). Entries are discovered when the field they first appear on is reached; the spotlight shows the explanation, a tip, the matching lifetime stat and "Practise on field N". Reached from Settings, the Farm Book and every Field Briefing. |
| 16 | **Seed Detail** | One variety's page: lore and trait, an animated flight profile (its burst fan vs Rye's, with wind drift), Mass / Spread / Drift / Bloom bars, your runs / plots / best with it, its share of all runs, its three best fields (tap → briefing) and recent runs; put-in-hopper, locked and never-sown states. Opened from the Almanac's featured card, Run Detail's seed row and Harvest Charts. |
| 17 | **Harvest Charts** | Trends from the ledger: stat tiles (average of last 12, sown rate, best streak, most-played region), recent scores (sown cobalt vs fallow slate, tap-to-inspect callout), stars by region, plots sown per day (14 days), seeds used most; Charts/Table switch; "charts grow as you sow" empty state. Opened from the Farm Book overview and ledger. |
| 13 | **Paint Shed** | Ten mill paints unlocked by farmer rank; live painted-mill preview; the chosen paint colours the sails on Mill Hill and in every run. |
| — | **SplashView** | MANDATORY dormant loader screen (logo lockup, turning-sail loader, themed sky) — compiles, referenced from nowhere, never deleted. |

## 3. Features per screen

### 3.1 Onboarding
- Three steps, each an illustrated scene + linen text card: **Release on the right beat**, **Burst where the plots are**, **Read the wind before you throw**.
- Progress dots (the active one is a stretched plank), `NEXT` plank button, `Skip the tour` pill.
- Last step writes `PreferenceEntity.firstLaunchCompleted = true` and seeds default content (36 fields locked except field 1, 12 seeds with 3 unlocked, 16 ribbons at zero progress).
- Reachable again from Settings → *Replay the three-step tour* (does not wipe progress).

### 3.2 Mill Hill (main menu)
- Full-bleed sky → golden hill scene; nothing is a floating widget, every control is an object on the hill.
- **SOW sign** (primary): opens the current field directly; shows region + field number; pressed state = scale 0.96 + haptic.
- **Rosette on a stake** → Ribbon Wall (label shows `earned/16`).
- **Map board on a post** → Field Map.
- **Seed crate** → Seed Almanac.
- **Tool basket** → Settings.
- **Embroidered sun** above the mill → Daily Sowing (label shows the day streak or "sown").
- **The towel** is itself a button → Farm Book (rank tag pinned on it).
- SOW sign states: next field · "N more stars for <region>" (opens the map) · "All 72 sown · today's field" (opens Daily). First run shows a coach pill pointing at the sign.
- **Embroidered towel** across the hill shows lifetime `seeds sown`, `best streak`, `fields sown x/36` from `FarmStatsEntity` (`.contentTransition(.numericText)` on return from a run).
- Sails turn slowly (animation gated on `animationsOn`); a pod arc drifts across the sky every few seconds.

### 3.3 Field Map
- `ScrollView` with a painted path; 36 nodes in 4 regions, region header card + star counter, region gate banner ("Terraced Slopes — opens at 34 stars").
- Node states: completed (gold, 1–3 red stars), current (large, ring of rays, `SOW NEXT` ribbon), locked (blue, padlock, shows its number).
- Tapping a completed node replays it; tapping a locked node shakes it and shows the star requirement; tapping the current node starts the run.
- Scroll auto-centres on the current field on appear.

### 3.4 Sowing Run (gameplay)
- One `SKScene` (`scaleMode = .resizeFill`), created once and held by `GameViewModel`; pause via `scene.isPaused` in `onChange(of:)`.
- Controls: tap anywhere = release (when a pod is on the sail) / burst (when a pod is airborne). No other input.
- Scene contents: mill with turning sails, pod on the sail tip, airborne pod + seeds, plot grid in perspective, hazards (pond, stone wall, road strip, crow, hay cart in later regions), drifting chaff showing wind direction and strength.
- HUD (SwiftUI overlays, never `SKLabelNode`): score with roll-up, `plots x/y` + progress bar, pods remaining as pod pips, wind readout with a vane, streak flag, pause plate (≥44×44).
- Juice: haptic on release / burst / sow / crow-steal, screen shake on a lost pod, white hit-flash on the crow and on hazards, particle burst of husk on each burst and a sprout pop on each sown plot.
- Fail state: pods exhausted with the quota unmet → Harvest Report in *fallow* state.

### 3.5 Sails Held (pause)
- Resume (plank), Restart field, Field map, plus an inline haptics switch; shows current score / plots / pods.
- Opening pause pauses the scene; closing resumes it — the `SpriteView` is never rebuilt.

### 3.6 Harvest Report
- Star ribbons (1–3) animate in one by one; score rolls up; `New best` stamp when the field's best score is beaten.
- Rows: plots sown, pods left, best streak, seeds landed, seed used.
- Earned-ribbon strip when the run completed an achievement.
- Actions: **Next field** (unlocks and opens the next node), Replay field, Field map. In fallow state: **Try again**, Field map.
- This is the only place (with checkpoints) where Core Data is written: `FieldProgressEntity`, `RunRecordEntity`, `RibbonEntity`, `FarmStatsEntity`, `SeedEntity.timesUsed`.

### 3.7 Seed Almanac
- Featured card: seed art, name, lore line, three stat bars (Mass / Spread / Drift), `In the hopper` stamp, "Keep in hopper" action, times sown.
- Grid of the remaining varieties with mini stat bar and either their trait or the unlocking field.
- Selecting a seed writes `PreferenceEntity.selectedSeedKey`; the scene reads mass, spread (seeds per burst), drift and bloom bonus from it.

### 3.8 Ribbon Wall
- Header with `earned/16` and a progress bar; newest ribbon card with its goal text.
- Grid of 16 rosettes, pinned at slight angles: earned ones gold with a plank name plate, locked ones grey-blue with the goal in the plate.
- Tapping a rosette flips a small detail plate with progress ("14 / 20 true sows").

### 3.9 Settings
- **Haptics** switch → `PreferenceEntity.hapticsOn`.
- **Animations** switch → `PreferenceEntity.animationsOn` (sail spin, shake, roll-ups).
- **Seed in the hopper** row → Seed Almanac.
- **Replay the three-step tour** → onboarding, progress untouched.
- **Reset progress** → confirmation alert → wipes fields, runs, ribbons, seed unlocks and stats, re-seeds defaults, sets `firstLaunchCompleted = false` and returns to onboarding.
- Version line. Nothing store-unsafe: no links, accounts, sharing, notifications, language or icon pickers.

### 3.10 Motion & polish (all screens)
- `motionEnabled` environment mirrors **Settings → Animations**; every decorative loop, entrance and roll-up checks it (off = static, instant).
- Entrances: each screen's sections rise in with a staggered spring. Numbers roll up from zero with `.contentTransition(.numericText())` (stat wells, towel, streaks, bushels, scores, map chips) and tick over when they change.
- At least one ambient loop per screen: running cross-stitch band, drifting pollen motes, turning sails, swaying pinned rosettes, bobbing seed/guide art, breathing primary actions, rotating sun rays on the Harvest Report.
- Every tappable element has a spring press state and a light haptic (plank / plate / art / row styles, toggles, segments, map nodes, scrims).
- Layout rhythm on the 8-pt scale (16-pt gutters, shared `SectionHeader` pills for dividers over art), friendly copy in every empty state.
- Back plates return to the previous screen (navigation history), not always to Mill Hill.
- Charts follow the dataviz method: bars ≤ 24 pt, square baseline + 4 pt rounded data end, hairline solid gridlines, clean axis maxima, one callout value instead of labels on every bar, legend only for two series, text in ink tokens. Colours validated on the linen surface: cobalt #1763DE + slate #7486A3 (≥ 3:1 contrast, CVD ΔE 15.7, normal ΔE 17.4); a Table view carries every value without colour.

## 4. Content plan

### 4.1 Fields — 72 levels in 8 regions (9 each)
| Region | Fields | Opens at | Grid | Mechanic introduced |
|---|---|---|---|---|
| Meadow Rise | 1–9 | 0★ | 3×5 | calm air, first crow at 7 |
| Lakeside Strips | 10–18 | 8★ | 4×5 | ponds, crosswind |
| Terraced Slopes | 19–27 | 34★ | 4×6 | stone walls, one wind shift |
| Storm Ridge | 28–36 | 62★ | 5×6 | road + hay cart, crow pairs, wind every 6 s |
| Sunflower Coast | 37–45 | 84★ | 4×6 | **golden plots (+250)**, steady sea breeze |
| Orchard Rows | 46–54 | 106★ | 5×6 | tree trunks, two crows, wind every 10 s |
| Linen Valley | 55–63 | 128★ | 5×6 | two roads + two carts, faster sails |
| Harvest Crown | 64–72 | 150★ | 5×6 | three crows, two carts, gusts every 5 s |

Fields 1–36 keep their original seeds and layouts. Sail speed 1.6 → 3.8 rad/s over fields 1–36, then 3.4 → 4.4 for 37–72. 216 stars in total. Every soil plot on every field was verified reachable (no wind, smallest seed fan) on 375-, 390- and 440-pt screens.

### 4.2 Seeds — 24 varieties
| Seed | Unlocks | Mass | Seeds/burst | Drift | Trait |
|---|---|---|---|---|---|
| Rye | start | 0.55 | 3 | 0.45 | the dependable all-rounder |
| Sunflower | start | 0.90 | 3 | 0.20 | heavy, ignores wind, drops steep |
| Flax | start | 0.34 | 4 | 0.86 | light, rides the gust |
| Poppy | field 6 | 0.40 | 5 | 0.62 | widest fan, short range |
| Barley | field 10 | 0.62 | 4 | 0.38 | long flat throws |
| Clover | field 14 | 0.30 | 6 | 0.74 | six tiny seeds, tiny bloom bonus |
| Buckwheat | field 19 | 0.70 | 3 | 0.30 | +50% bloom bonus on true sows |
| Millet | field 22 | 0.44 | 5 | 0.55 | balanced spread |
| Mustard | field 25 | 0.38 | 4 | 0.80 | curves hard downwind |
| Lupin | field 28 | 0.82 | 3 | 0.24 | punches through a crow without being stolen |
| Vetch | field 31 | 0.48 | 5 | 0.66 | second burst allowed once per run |
| Oat | field 34 | 0.58 | 4 | 0.42 | +1 pod at the start of every field |
| Cornflower | field 37 | 0.36 | 4 | 0.70 | light, holds its line |
| Chamomile | field 40 | 0.32 | 5 | 0.78 | floats far, small bloom |
| Marigold | field 42 | 0.50 | 4 | 0.50 | golden plots pay double |
| Pea | field 45 | 0.78 | 3 | 0.28 | sails turn 15% slower |
| Lentil | field 48 | 0.66 | 5 | 0.34 | skids straight |
| Canola | field 51 | 0.42 | 6 | 0.62 | wide fan |
| Sesame | field 54 | 0.28 | 6 | 0.90 | featherlight |
| Lavender | field 57 | 0.46 | 4 | 0.58 | first empty throw keeps the streak |
| Pumpkin | field 60 | 0.98 | 2 | 0.12 | two seeds, huge bloom |
| Quinoa | field 63 | 0.50 | 5 | 0.52 | tidy spread |
| Spelt | field 66 | 0.64 | 4 | 0.40 | golden plots pay double |
| Sorghum | field 69 | 0.86 | 4 | 0.22 | crow-proof |

### 4.3 Ribbons — 40 achievements in 4 categories
The original 16, plus: Coastline Sower · Orchard Keeper · Linen Weaver · Crown Bearer (all 72) · Meadow Perfect · Still Waters (3★ regions) · Fifty / Hundred Stars · Star Field (200★) · Golden Touch (25 golden plots) · Gold Rush (every golden plot in a field) · Sunrise Sower · Three Suns · Week of Suns · Month of Suns (daily streaks) · Almanac of Days (20 dailies) · Furrow Hand · Sail Master · Mill Legend (ranks 5/10/20) · Painted Sails (5 paints) · Full Hopper (10 seed varieties sown) · Every Pod Counts · Big Bloom (10 000 in one field) · Long Season (100 runs). Almanac Filled now asks for all 24 seeds.

### 4.3b Progression & retention
- **Bushels (farm XP)** per run: sown = 30 + 15/star + 2/plot + 5/golden (+40 first clear, +30 daily, +40 first daily of the day); fallow = 6 + plots. Region clear bonus 60–220.
- **20 farmer ranks** (Sprout Hand → Mill Legend, 0 → 10 500 bushels); rank-ups are announced in the Harvest Report.
- **10 mill paints** unlocked at ranks 1, 3, 5 … 19.
- **Daily Sowing**: FNV-seeded field per day from region 2–7 templates, +1 pod, two golden plots; streak = consecutive completed days ending today (or yesterday while today is open).

### 4.4 Other content
- 3 onboarding steps, 4 region blurbs, 12 seed lore lines, 16 ribbon goal lines, 8 in-run tip lines (first appearance of each hazard).
- `-demoMode`: fixed RNG seed (`42`), a scripted field (region 2 layout, wind 1.6 E) and a fixed release/burst script so recorded frames are identical every run.
- `-screenshotTour`: skips onboarding, seeds an in-memory farm (23 fields sown, 36 ledger runs incl. 8 dailies, a 4-day streak, rank 10 with 5 paints, 14 ribbons, 8 seeds) and cycles every 3 s, looping: Mill Hill → Sowing Run (demo) → Field Map → Field Briefing → Region Detail → Daily Sowing → Farm Book → Ledger → Harvest Charts → Ribbon Wall → Seed Almanac → Seed Detail → Field Guide → Paint Shed → Settings. Tour seeding is a separate path; normal launches are untouched.
- **Edge states**: empty ledger / empty filters, first run (coach pill, "Start here" on the map, zero stats), daily sown today (countdown), no dailies yet, all fields sown, region complete, all seeds unlocked, all paints unlocked, all ribbons pinned.

## 5. Core Data model (version 2, lightweight migration from v1)

Every entity has `id: UUID` and `createdAt: Date`. Every FetchRequest carries `sortDescriptors`; `viewContext.save()` follows every mutation. Content seeding is additive (existing rows are kept and definitions synced), so new fields/seeds/ribbons never wipe progress.

v2 additions: PreferenceEntity `selectedPaintKey` · FieldProgressEntity `lastPlayedAt`, `bestTrueSows` · RunRecordEntity `dailyKey`, `bushels`, `goldenSown` · SeedEntity `bestScore` · RibbonEntity `category` · FarmStatsEntity `bushels`, `rank`, `dailyStreak`, `bestDailyStreak`, `lastDailyKey`, `dailyCompleted`, `goldenSown`, `totalWins`.

### DailyRunEntity *(one per played day)*
`id: UUID` · `createdAt: Date` · `dayKey: String` · `attempts: Int32` · `completed: Bool` · `bestScore: Int32` · `stars: Int16` · `completedAt: Date?` · `seedKey: String`

### MillPaintEntity *(10 rows, seeded)*
`id: UUID` · `createdAt: Date` · `key: String` · `name: String` · `colorHex: Int64` · `unlockRank: Int16` · `isUnlocked: Bool` · `unlockedAt: Date?` · `sortIndex: Int16`

### PreferenceEntity *(singleton)*
`id: UUID` · `createdAt: Date` · `hapticsOn: Bool` · `animationsOn: Bool` · `firstLaunchCompleted: Bool` · `selectedSeedKey: String` · `lastFieldIndex: Int16`

### FieldProgressEntity *(72 rows, seeded)*
`id: UUID` · `createdAt: Date` · `fieldIndex: Int16` · `regionKey: String` · `isUnlocked: Bool` · `stars: Int16` · `bestScore: Int32` · `bestPodsLeft: Int16` · `bestStreak: Int16` · `attempts: Int32` · `completedAt: Date?`

### RunRecordEntity *(history, one per finished run)*
`id: UUID` · `createdAt: Date` · `fieldIndex: Int16` · `regionKey: String` · `score: Int32` · `plotsSown: Int16` · `plotsRequired: Int16` · `podsUsed: Int16` · `podsLeft: Int16` · `bestStreak: Int16` · `trueSows: Int16` · `seedsLost: Int16` · `seedKey: String` · `durationSeconds: Double` · `outcome: String` ("sown" | "fallow") · `starsEarned: Int16`

### SeedEntity *(24 rows, seeded)*
`id: UUID` · `createdAt: Date` · `key: String` · `name: String` · `lore: String` · `unlockField: Int16` · `isUnlocked: Bool` · `mass: Double` · `seedsPerBurst: Int16` · `drift: Double` · `bloomBonus: Int16` · `timesUsed: Int32` · `plotsSown: Int32`

### RibbonEntity *(40 rows, seeded)*
`id: UUID` · `createdAt: Date` · `key: String` · `title: String` · `detail: String` · `goal: Int32` · `progress: Int32` · `isEarned: Bool` · `earnedAt: Date?` · `sortIndex: Int16`

### FarmStatsEntity *(singleton)*
`id: UUID` · `createdAt: Date` · `totalSeedsSown: Int64` · `totalPodsFlung: Int64` · `totalPlotsSown: Int64` · `bestStreak: Int16` · `totalStars: Int16` · `fieldsSown: Int16` · `totalRuns: Int32` · `lastPlayedAt: Date?`

## 6. Architecture notes (binding for the build stage)

```
Game/
├── GameScene.swift        // the single SKScene: sails, pods, seeds, plots, hazards
├── PhysicsCategory.swift  // ALL bitmasks: seed, pod, plot, hazard, crow, ground
├── GameState.swift        // enum: idle, aiming, inFlight, resolving, paused, sown, fallow
├── GameViewModel.swift    // ObservableObject bridge; owns the scene, persists results
└── Entities/              // PodNode, SeedNode, PlotNode, CrowNode, MillNode + pools
```
- Pure testable structs outside SpriteKit: `FieldCatalog` (36 field definitions), `SeedCatalog` (12 seeds), `RibbonCatalog` (16 ribbons), `ScoreRules` (plot 100 · streak ×1…×4 in ¼ steps · true sow +75 · leftover pod +250), `DifficultyCurve` (sail speed / wind / quota per field), `TrajectorySolver` (tangent launch, gravity, wind drag, burst fan).
- No allocation inside `update(_:)`: pods, seeds, husk particles, chaff and crows are pre-allocated pools reused via `isHidden`.
- zPosition layers: background −100, entities 0, effects 50, HUD 100 (HUD itself is SwiftUI).
- The scene never touches Core Data; `GameViewModel` persists at run end.
- Layout: scene nodes positioned relative to `scene.size` with safe margins; SwiftUI shell uses flexible layout only — verified from 375×667 to 440×956.
