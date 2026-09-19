# Gold Rush Roguelike Visual Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the approved 2.5D visual overhaul by replacing the remaining prototype-looking enemies, defenses, arenas, VFX and HUD while preserving the already-GREEN gameplay architecture.

**Architecture:** Keep the Godot 4.7.2 2D runtime, existing collision/Y-sort/gameplay APIs, and five-arena progression. Visual work is isolated to sprite/scene presentation, atmosphere and event-synchronized VFX; behavioral changes are allowed only when a regression test proves a presentation blocker such as invisible spawns or unstable animation.

**Tech Stack:** Godot 4.7.2, GDScript 2.0, SVG/transparent 2D sprite assets, AnimatedSprite2D, Polygon2D, Line2D, PointLight2D used sparingly, GitHub Actions headless tests/captures, Windows x86_64 export.

**Spec:** `gold-rush-roguelike/docs/superpowers/specs/2026-09-19-visual-overhaul-design.md`

## Global Constraints

- Runtime remains Godot 2D; no conversion to runtime 3D.
- Preserve current gameplay collision shapes unless a mismatch is proven by a failing test.
- Preserve current Y-sort/z-index contracts and persistent-actor reparenting.
- Actor pivot is the ground-contact point; FlyingGoldDisc uses projected ground center.
- Primary warm key is upper-left; cyan is friendly/tech energy; orange-red is danger.
- No rectangular cutout artifacts, crude geometric placeholders, cropped animation frames, or mismatched front-on/top-down projection.
- Dynamic PointLight2D is reserved for meaningful emissive elements and short bursts.
- VFX self-clean and may not leak nodes between waves.
- Existing gameplay, economy, wave, upgrade, boss-state and export contracts remain GREEN.
- Final Windows x86_64 export must succeed.

## Current Baseline

Already completed and verified before this plan:
- Prospector run preserved, idle planted, firing recoil stabilized.
- Production opening wave visibly spawns enemies.
- Arena01 rebuilt as a frontier main street with Saloon, Sheriff Office, Bank and General Store.
- Boss replaced by Frontier Juggernaut with dedicated boss projectile and clean warning/beam Line2D presentation.
- CI run 35464374648 is GREEN on commit 19cb299e9003c352c7da9faa9ebb87f3e1ff0b0e.

## File Map

```text
assets/sprites/enemies/          normal enemy replacement atlas
assets/sprites/defenses/         defense replacement art
assets/environment/              arena02-05 environment art
assets/vfx/                      projectile/impact/pickup/ambient art
scenes/enemies/                  enemy visual integration
scenes/defenses/                 defense visual integration
scenes/arenas/                   arena identity integration
scenes/ui/                       HUD and upgrade visual integration
scripts/enemies/                 animation state hooks only when required
scripts/defenses/                animation state hooks only when required
scripts/vfx/                     self-cleaning effect timing
tests/                           visual/runtime regression contracts
.github/workflows/gold-rush-godot-ci.yml  headless gates and captures
```

## Review Focus

1. Dense mixed waves: all four normal enemy silhouettes remain distinguishable against warm sand and gold props.
2. Enemy attack anticipation: Sentinel/Disc/Slime/Hopper presentation must communicate the attack before damage/release.
3. Defense placement: new art must not move gameplay footprints or hide the player/core/build zone.
4. Arena transitions: Arena02-05 must keep player/core/spawn/build markers valid after environment replacement.
5. Effects under load: repeated projectiles, deaths, pickups and explosions must self-clean without persistent lights/effect nodes.

---

### Task 1: Normal Enemy Roster Visual Rebuild

**Files:**
- Create: `assets/sprites/enemies/enemies_frontier_v6.svg`
- Modify: `scenes/enemies/GoldHopper.tscn`
- Modify: `scenes/enemies/GoldCoinSentinel.tscn`
- Modify: `scenes/enemies/FlyingGoldDisc.tscn`
- Modify: `scenes/enemies/MoltenGoldSlime.tscn`
- Modify: `tests/test_enemy_animation_contract.gd`
- Create: `tests/test_enemy_visual_overhaul.gd`
- Modify: `.github/workflows/gold-rush-godot-ci.yml`

**Interfaces:**
- Consumes: existing EnemyBase gameplay, current enemy scripts and animation names.
- Produces: four readable normal-enemy scenes using the replacement v6 atlas without changing collision or public gameplay methods.

- [x] **Step 1: Write failing visual contract.** Instantiate all four scenes and assert each visible AnimatedSprite2D/Sprite2D resolves to `enemies_frontier_v6.svg`, each has a non-empty ground shadow, and FlyingGoldDisc keeps a separated projected shadow.
- [x] **Step 2: Add the test to CI and run it.** Expected: FAIL because the v6 atlas does not exist / scenes still reference prior art.
- [x] **Step 3: Create the replacement atlas.** Hopper = compact faceted nugget creature; Sentinel = plated coin-machine with readable emitter; Disc = gold/steel saucer with cyan emitter; Slime = molten asymmetric body with bright inner core. Keep transparent canvas, consistent 3/4 projection and warm upper-left highlight.
- [x] **Step 4: Integrate the atlas into the four scenes.** Preserve collision shapes and gameplay node paths; update only SpriteFrames/visual child nodes, shadow scale/offset and presentation-only particles/lights.
- [x] **Step 5: Verify animation states.** Existing `idle/move/attack/hit/death` contracts must remain valid where supported; attack visuals must not shift the ground anchor.
- [x] **Step 6: Run targeted tests and full CI.** Expected: enemy visual contract GREEN, animation contract GREEN, production enemy visibility GREEN.
- [x] **Step 7: Commit.** `art: rebuild normal enemy roster`

### Task 2: Defense Roster Visual Rebuild

**Files:**
- Create: `assets/sprites/defenses/defenses_frontier_v6.svg`
- Modify: `scenes/defenses/MagneticTurret.tscn`
- Modify: `scenes/defenses/CactusSentry.tscn`
- Modify: `scenes/defenses/TNTBarrel.tscn`
- Create: `tests/test_defense_visual_overhaul.gd`
- Modify: `tests/test_defense_animation_contract.gd`

**Interfaces:**
- Consumes: current targeting, weapon and TNT behavior.
- Produces: three distinct defenses with unchanged build footprint/cost/gameplay APIs.

- [x] **Step 1: Write failing defense visual contract.** Require replacement atlas, readable ground shadow, MagneticTurret cyan coil/head, CactusSentry weapon/recoil visual, TNT fuse/danger visual.
- [x] **Step 2: Run RED.** Expected: old assets fail replacement-path assertions.
- [x] **Step 3: Draw and integrate replacement defense atlas.** Keep all gameplay nodes and collision shapes unchanged.
- [x] **Step 4: Synchronize firing/arming presentation to existing gameplay events.** No cosmetic animation may fire a projectile or apply damage itself.
- [x] **Step 5: Run defense animation, economy/building and visual tests GREEN; run full CI.**
- [x] **Step 6: Commit.** `art: rebuild frontier defenses`

### Task 3: Arena02-Arena04 Distinct Environment Identities

**Files:**
- Create: `assets/environment/arena02_mining_yard_v6.svg`
- Create: `assets/environment/arena03_rail_explosives_v6.svg`
- Create: `assets/environment/arena04_elite_canyon_v6.svg`
- Create: `assets/environment/frontier_props_v6.svg`
- Modify: `scenes/arenas/Arena02.tscn`
- Modify: `scenes/arenas/Arena03.tscn`
- Modify: `scenes/arenas/Arena04.tscn`
- Create: `tests/test_arena_identity_overhaul.gd`

**Interfaces:**
- Consumes: arena marker groups and Y-sort hierarchy.
- Produces: three visually distinct arenas with unchanged spawn/player/core/build marker contracts.

- [x] **Step 1: Write failing arena identity contract.** Require unique v6 backdrop path and a unique landmark node in each arena; assert all required marker groups still exist.
- [x] **Step 2: Run RED.**
- [x] **Step 3: Build Arena02 mining yard.** Hoist, ore crusher, timber shed, mine supports, carts/rails near edges.
- [x] **Step 4: Build Arena03 rail/explosives yard.** Rail junction, TNT depot, loading platform and warning props with readable central combat lane.
- [x] **Step 5: Build Arena04 elite canyon/extraction site.** Derrick/extraction rig, harsher canyon walls, reinforced barricades and elite landmark.
- [x] **Step 6: Run arena identity, run-flow, depth-sort and build-zone tests GREEN; run full CI.**
- [x] **Step 7: Commit.** `art: give arenas 02-04 distinct frontier identities`

**Progress evidence:** Tasks 1-3 GREEN through CI run `35466282491`; Windows export succeeded.

### Task 4: Arena05 Foundry Boss Environment

**Files:**
- Create: `assets/environment/arena05_molten_foundry_v6.svg`
- Create: `assets/environment/foundry_props_v6.svg`
- Modify: `scenes/arenas/Arena05.tscn`
- Modify: `scenes/enemies/GoldBarTank.tscn`
- Create: `tests/test_arena05_boss_environment.gd`
- Modify: `tests/test_boss_presentation.gd`

**Interfaces:**
- Consumes: Frontier Juggernaut state machine and existing boss telegraph nodes.
- Produces: foundry arena with clear safe playfield and boss contrast.

- [x] **Step 1: Write failing foundry contract.** Require foundry backdrop, furnace/gantry landmark, readable boss spawn clearance and preserved boss warning/beam nodes.
- [x] **Step 2: Run RED.**
- [x] **Step 3: Build molten-gold foundry backdrop and edge props.** Keep bright molten values away from the center so gold enemies/boss remain readable.
- [x] **Step 4: Refine Juggernaut contact shadow, emissive core and attack anticipation without changing attack damage/state logic.
- [x] **Step 5: Run boss laser, presentation, climax VFX and run-flow tests GREEN; capture boss preview.**
- [x] **Step 6: Commit.** `art: rebuild Arena05 molten foundry`

**Progress evidence:** Task 4 GREEN through CI run `35466741037`; Arena05 boss preview and Windows x86_64 export succeeded.

### Task 5: Combat VFX, Pickups and HUD Alignment

**Files:**
- Create/modify: `assets/vfx/*_v6.svg`
- Modify: `scenes/combat/Projectile.tscn`
- Modify: `scenes/combat/BossProjectile.tscn`
- Modify: `scenes/vfx/HitFlash.tscn`
- Modify: `scenes/vfx/Explosion.tscn`
- Modify: `scenes/pickups/GoldPickup.tscn` if present
- Modify: `scenes/ui/HUD.tscn`
- Modify: `scenes/ui/UpgradeOverlay.tscn`
- Create: `tests/test_visual_feedback_v6.gd`

**Interfaces:**
- Consumes: current combat signals, pickup collection, HUD bindings.
- Produces: compact synchronized VFX and coherent western HUD without gameplay polling changes.

- [x] **Step 1: Write failing feedback contract.** Assert player projectile, boss projectile, hit, explosion and pickup use distinct readable presentation; assert HUD player/core/boss panels remain separate and boss name is Frontier Juggernaut.
- [x] **Step 2: Run RED.**
- [x] **Step 3: Rebuild muzzle/projectile/impact/death/pickup effects.** Use compact sprite/polygon glow; avoid PointLight2D on every normal projectile.
- [x] **Step 4: Restyle HUD and upgrade cards with dark timber/metal/leather panel language, restrained gold trim, cyan friendly energy and orange-red boss danger.
- [x] **Step 5: Verify self-cleaning effect lifetime and HUD signal updates; run full CI.**
- [x] **Step 6: Commit.** `art: unify combat feedback and frontier HUD`

**Progress evidence:** Task 5 GREEN through CI run `35466995292`; v6 feedback regression, gameplay capture, boss capture and Windows export all succeeded.

### Task 6: Final Visual QA and Release Candidate

**Files:**
- Modify: `tests/capture_gameplay_preview.gd`
- Modify/Create capture scripts for dense combat, defenses, pickup, boss slam, upgrade UI, victory/defeat as needed.
- Modify: `.github/workflows/gold-rush-godot-ci.yml`
- Modify: `README.md` if controls/art status changed.

**Interfaces:**
- Consumes: all prior visual tasks.
- Produces: verified release-candidate captures and Windows x86_64 artifact.

- [ ] **Step 1: Add/extend capture coverage for the spec-required benchmark images.**
- [ ] **Step 2: Run the complete headless suite.** Expected: every test exits 0, no parser/missing-resource errors.
- [ ] **Step 3: Inspect gameplay and boss captures for crop rectangles, floating shadows, unreadable silhouettes, HUD overlap and excessive VFX.
- [ ] **Step 4: Fix only demonstrated Critical/Important visual regressions with RED→GREEN tests.
- [ ] **Step 5: Export Windows x86_64 and verify artifact creation.
- [ ] **Step 6: Commit.** `chore: verify visual overhaul release candidate`

## Self-Review

- Spec coverage: normal enemies, defenses, Arena02-05, boss refinement, VFX, HUD, captures and export are all owned by tasks.
- Existing completed Prospector/Arena01 work is explicitly baseline and is regression-checked rather than redundantly redone.
- No runtime 3D dependency is introduced.
- Shared interfaces are preserved: enemy/defense gameplay scripts and arena marker contracts remain authoritative.
- Performance risk is bounded by avoiding dynamic lights on every projectile and requiring VFX cleanup.
- Review-focus cases are attached to the owning tasks through explicit tests.
