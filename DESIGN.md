**Art direction:** Embroidered Sunfield — a vivid folk-textile countryside at high noon, where cobalt sky meets saturated sunflower-gold fields and every surface is hand-painted signage, woven linen or cross-stitch ornament outlined in deep navy.

Not a glow game, not a paper game. Everything is drawn like a village fair: thick navy outlines, hard offset shadows the way painted wood casts them, red cross-stitch diamonds as the only third colour. Colour is loud on purpose — the blue is real cobalt, the yellow is real sunflower, and cream linen is a *surface*, never the mood.

Explicitly banned in this system: Inter/Roboto as the type voice, purple-indigo gradients on white, rows of identical rounded cards as a layout, near-black-plus-neon "premium dark", and ivory/cream serif-editorial minimalism.

## Colour palette

Exactly as in `design-tokens.css` (project root) — one dominant colour, one accent, everything else supporting.

| Token | Hex | Role |
|---|---|---|
| `--blue-950` | `#061F5C` | top of the sky, vignette, deepest shade |
| `--blue-900` | `#0B3C9E` | sky upper band, mill cap, dark plates |
| **`--blue-700`** | **`#1763DE`** | **DOMINANT** — sky body, blue plates, ornament bands, ponds |
| `--blue-500` | `#3D86F0` | sky near the horizon, highlights on dark art |
| `--blue-300` | `#8FC0FF` | haze at the horizon, locked-state text |
| `--blue-100` | `#D6E8FF` | map board paper, water highlights |
| `--sun-600` | `#F09A0C` | plank underside, furrow shade, bar ticks |
| **`--sun-500`** | **`#FFC01F`** | **ACCENT** — sails, primary buttons, sown plots, stars |
| `--sun-300` | `#FFDE6A` | sun disc, field highlight, burst pod |
| `--sun-100` | `#FFF0BE` | paths, inset wells inside linen cards |
| `--linen` | `#FFF6E4` | card / towel / banner surface |
| `--linen-2` | `#F3E2BF` | linen fold and card gradient foot |
| `--ink` | `#0E2350` | every outline (3–4 px) and all dark text |
| `--ink-soft` | `#3C5688` | secondary text on linen |
| `--stitch-red` | `#D9342B` | cross-stitch diamonds, "step" labels, stars, destructive action |
| `--leaf` | `#2F8F5B` | sprouts and stems only |
| `--soil` | `#6B4A2A` | unsown furrows, posts, crate wood |

Shadows: `--shadow-hard: 0 6px 0 rgba(14,35,80,.45)` (painted-wood offset) + `--shadow-soft: 0 14px 28px rgba(6,31,92,.32)`. Text over sky or field always gets `--shadow-text` (`0 2px 0 rgba(14,35,80,.6), 0 8px 18px rgba(6,31,92,.4)`) or a container — never naked.

## Typography

**Avenir Next** throughout (ships with iOS and macOS; `.system(design: .rounded)` is the fallback). Only extreme weights are used — Heavy for every label, Ultra Light for every number. Nothing in between.

| Token | Size | Weight | Use |
|---|---|---|---|
| `--fs-micro` | 11 pt | 800, tracking `.20em`, uppercase | button labels, stat captions, pills |
| `--fs-small` | 14 pt | 800 | list rows, table values |
| `--fs-body` | 18 pt | 500 | reading copy on linen cards |
| `--fs-title` | 34 pt | 800, tracking `.03em` | screen titles, sign lettering |
| `--fs-display` | 54 pt | 800 | logo lettering, result headline |
| `--fs-hero` | 96 pt | 200, tracking `-.02em` | the big harvest numeral |

The statement scale is 12 → 34 → 96 (roughly 3× per step); 14 and 18 exist only as reading sizes. Numerals are always Ultra Light and tabular (`t-num`), labels are always Heavy and uppercase — that contrast *is* the type system. Tight labels get `.minimumScaleFactor(0.75)` + `.lineLimit(1)`.

Spacing is an 8 px scale (4 / 8 / 16 / 24 / 32 / 48 / 64 / 96). Radii: 8 small, 18 cards, 28 large, 999 pills.

## Components

- **Linen card** — `#FFF6E4 → #FBEDD3` gradient, 3 px navy border, 18 px radius, hard shadow + soft ambient, and an inset dashed navy stitch line 5 px in. Every text surface.
- **Plank button** (primary) — yellow gradient plate, 3 px navy border, `0 7px 0 #A8650A` underside; pressed = translateY(4px), shadow to 3 px, plus haptic.
- **Blue plate** (secondary) — cobalt gradient, navy border, navy underside; used for navigation labels and secondary actions.
- **Sky pill** — translucent navy `rgba(6,31,92,.62)` with a 2 px linen border; the only control allowed to float over art.
- **Cross-stitch band** — 16 px diagonal yellow/red weave, pinned to the top of every screen; a 6 px dashed red rule separates blocks inside cards.
- **Rosette** — layered disc + swallow-tail ribbon; gold + red diamond when earned, grey-blue when locked.
- Every tappable control is ≥ 44 × 44 pt; interactive elements stay clear of the notch and home indicator.

## Per-screen layout

### Mill Hill — main menu (`design/menu.png`)
A scene, not a list. Full-bleed cobalt sky with a sun haze at upper-right; the golden hill takes the bottom 45% with perspective furrows and a pale path winding up to the mill. **Title** is a scalloped linen banner hung from a wooden rail at upper-left, rotated −4°, with a red stitch rule above and a blue one below; a sky pill beneath reads the tagline. The **windmill** stands right-of-centre, sails crossing into the sky; a dotted pod arc drifts from a sail tip down into the field, showing the verb before you press anything. Navigation lives on the hill: a **rosette on a stake** (Ribbon Wall) at mid-left, an **embroidered towel** strung across the slope carrying the three lifetime stats, the big **SOW plank sign** on two posts (primary, rotated −3°), a **map board on a post** (Field Map) to its right, and a **seed crate** and **tool basket** sitting on the soil at the bottom, with sunflowers bleeding off the lower-right corner. No corner circle buttons, no pill CTA, no card grid, no bottom stats strip. Mood: a bright fair day you want to walk into.

### Onboarding (`design/onboarding.png`)
Sky above, hill below. Upper two-thirds: a single illustrated scene (mill, pod, arc, burst, two sown plots) with the sun as a stitched disc. Lower third: a linen card with a red `STEP 1 OF 3` micro label, a two-line 34 pt title and 18 pt body. Under it, progress dots (the active dot is a stretched yellow plank) on the left and the `NEXT` plank on the right; a `Skip the tour` sky pill at the very bottom.

### Field Map (`design/fields.png`)
Sky only at the top, then the field fills the screen with wide furrow bands. A 26 px cream path snakes from the bottom-left upward; gold nodes carry the field number in a linen disc with up to three red stitch stars beneath. The **current** node is larger, ringed with rays and a red `SOW NEXT` ribbon below it; locked nodes are cobalt with a small padlock. A navy region-gate banner sits across the path where the next region begins. Floating above: a linen header card (back plate + region name + "fields 10–18") and two status chips — a blue plate and a yellow plank — deliberately different shapes.

### Sowing Run — gameplay (`design/gameplay.png`)
The scene runs edge to edge: cobalt sky with drifting chaff dashes showing wind, the mill anchored to the lower-left with sails part-cropped, a dotted release arc, a burst rosette of husk, three dotted seed trails, and the field of trapezoid plots in perspective (gold + sprout = sown, brown furrows = bare, blue ripples = pond, stone wall on top of a plot, a crow mid-flight). HUD on top: one wide linen card with `SCORE` (96-scale Ultra Light numeral) and `PLOTS 14/20`, a striped quota bar underneath, and a separate 56 pt linen pause plate; a second row with a blue wind pill (vane glyph + `Wind 2.4 E`) and pod pips; a small yellow streak plank below it; a sky-pill hint at the bottom. Nothing playable sits under the HUD or the home indicator.

### Sails Held — pause (`design/pause.png`)
The live scene dimmed to 50% navy. One centred linen card: field name in red micro, "Sails held" title, a row of three inset wells (score / plots / pods) on `#FFF0BE`, a full-width `RESUME` plank, two blue plates (Restart · Field map) and an inline haptics switch.

### Harvest Report — results (`design/results.png`)
Same dimmed scene. Three rosettes across the top with the middle one largest — earned ones gold, missed one grey-blue. A tall linen card: red micro breadcrumb, "Field sown" title, the 64 pt Ultra Light score with a rotated red `New best` stamp, a dashed red rule, then five stat rows in Heavy 14, then a dashed `#FFF0BE` strip announcing the ribbon earned. Below the card: a wide `NEXT FIELD` plank and two blue plates (Replay field · Field map). The fallow variant swaps the ribbons for a single grey rosette, the headline for "Field left fallow" and the plank for `TRY AGAIN`.

### Seed Almanac (`design/almanac.png`)
Sky with the hill peeking at the bottom. Header card, then a featured linen card: the seed's art in a framed `#FFF0BE` well on the left, name + trait + lore on the right, three striped stat bars (Mass / Spread / Drift), a rotated red `In the hopper` stamp overlapping the corner, and a plank + blue plate action row. Below a dashed section rule, the rest of the crate as six compact linen cards (two columns) — each with seed art, name, its trait or unlock field, and a mini progress bar; locked ones drop to 72% opacity with grey-blue art.

### Ribbon Wall (`design/ribbons.png`)
Header card, then the newest-ribbon linen card (84 pt rosette + title + goal + the 7/16 progress bar). Under a dashed rule, sixteen rosettes pinned in a three-column wall, each rotated a degree or two so the wall looks pinned rather than laid out; earned ones carry a yellow plank name plate, locked ones a blue plate.

### Settings (`design/settings.png`)
Three linen cards on the sky/hill backdrop: switches (Haptics, Animations) with descriptions and yellow toggles; navigation rows (seed in the hopper, replay the tour) with navy chevrons; and the destructive card — "Reset the whole farm", its consequences in micro type, and a red `#D9342B` plate with a dark red underside. Sunflowers at the bottom-left, a version sky pill at the bottom-right.

### SplashView — dormant (`design/splash.png`)
Sky with two clouds, the golden hill and two sown plots at the foot. Centred: the full logo lockup (scalloped linen banner, 46 pt Heavy lettering, red and blue stitch rules, yellow diamonds), rotated −3°. Below it a loader built from the mill itself — a four-blade sail cross turning inside a cobalt ring with a yellow progress arc — and a `Waking the sails` sky pill. Cross-stitch bands top and bottom.

## Asset brief

Raster imagery to be generated at BUILD time (Ideogram) — only what CSS/vector harvesting cannot express. Everything else ships from `design/assets/`.

- `bg_sky_noon` — bg — all SwiftUI screens — Painterly cobalt-blue midday sky with a warm sunflower haze at the upper right and faint woven-linen texture, no objects, flat folk-illustration shading.
- `bg_field_rows` — bg — gameplay, field map — Painterly saturated golden wheat field in perspective with amber furrow bands and a soft cream footpath, hand-painted folk style, deep navy edge shading.
- `tex_linen_canvas` — bg — card surfaces — Seamless warm cream woven linen texture with a faint red and blue cross-stitch thread running through it, flat lighting.
- `tex_wood_plank` — bg — plank buttons and signs — Seamless hand-painted sunflower-yellow wooden plank texture with visible brush grain and navy-painted edge.
- `hero_mill_noon` — hero — splash, menu header art — A whitewashed folk windmill with bright yellow lattice sails and a blue ornament band on a golden hill under a cobalt sky, thick navy outlines, poster-flat colour.
- `icon_app_mark` — icon — app icon — A four-blade yellow windmill sail cross with a single cream seed pod at one tip on a deep cobalt square, thick navy outlines, folk cross-stitch diamonds in the corners.

## Harvested assets (`design/assets/`, transparent @3x — these ship inside the app)

**Mill Hill scene**
- `windmill_hero` — the mill with sails, ornament band and door; menu centrepiece, reused on splash.
- `title_banner` — the MILLFLING scalloped banner lockup (menu title).
- `sign_sow` — the primary SOW plank sign on two posts.
- `rosette_ribbon` — staked award rosette → Ribbon Wall entry point.
- `post_fields` — map board on a post → Field Map entry point.
- `crate_seeds` — seed crate → Seed Almanac entry point.
- `basket_tools` — tool basket → Settings entry point.
- `rushnyk_stats` — embroidered towel that frames the three lifetime stats.
- `sunflower_cluster`, `sunflower_pair` — foreground sunflowers (menu, settings).
- `cloud_puff` — outlined folk cloud, parallax layer on every sky.
- `stitch_border` — the cross-stitch band pinned to the top of every screen.
- `pod_seed` — the drifting pod used in the menu's ambient arc.

**Gameplay**
- `pod_on_sail` — pod riding the sail tip (the aiming state).
- `pod_burst` — the burst husk rosette (effects layer).
- `seed_grain` — the three airborne seeds after a burst.
- `plot_sown` — gold plot with a sprout; `plot_bare` — furrowed soil plot.
- `stone_wall` — stone hazard laid over a plot.
- `crow_hazard` — the crow that steals seeds mid-air.
- `windvane_icon` — wind direction glyph in the HUD pill.
- `pause_plate` — the linen pause button plate.

**Field Map**
- `field_node_current` — large ringed node with the SOW NEXT ribbon.
- `field_node_done` — gold node with its star row; `field_node_locked` — cobalt node with padlock.
- `region_gate` — navy banner announcing the next region and its star cost.
- `back_plate` — linen back button plate, reused on every sub-screen header.

**Almanac / Ribbons / Results / Splash**
- `seed_flax`, `seed_sunflower`, `seed_rye`, `seed_poppy` — seed variety art (the remaining eight follow the same construction).
- `ribbon_badge_hero`, `ribbon_badge`, `ribbon_badge_locked` — rosettes at three states/sizes.
- `star_ribbon` — the three-rosette results award row.
- `best_stamp` — the rotated red "New best" stamp.
- `pause_mark` — the round pause emblem on the pause card.
- `ob_scene_release` — the onboarding hero illustration (mill, arc, burst, sown plots).
- `logo_lockup` — the full splash logo banner.
- `loader_sails` — sail-cross loader with progress ring (splash only).

## Adaptive notes

Reference mockups are 390 × 844. Everything translates to flexible SwiftUI layout: backgrounds full-bleed with `.ignoresSafeArea`, content in `Spacer`/`maxWidth: .infinity` compositions, the field map and almanac in `ScrollView`, hill art anchored to the bottom edge and allowed to crop. On a 375 × 667 screen the mill scales with the sky and the bottom object row tightens its spacing; on 440 × 956 the hill grows and the objects keep their 8 px rhythm. The `SKScene` uses `.resizeFill` and positions the mill, plots and hazards relative to `scene.size`, keeping the top 150 pt clear of playable targets (HUD) and the bottom 40 pt clear of the home indicator.
