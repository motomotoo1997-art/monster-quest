# Gold Rush Roguelike Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a launchable Godot 4.7.x 2D top-down roguelike shooter vertical slice with real-time tower-defense construction, five handcrafted arenas, four normal enemy archetypes, three defenses, run upgrades, and the Gold Bar Tank boss.

**Architecture:** Keep gameplay actor logic component-based. Moving actors own focused controller scripts while reusable combat behavior lives in components such as `HealthComponent`, `TeamComponent`, `WeaponComponent`, `TargetingComponent`, and `GoldDropComponent`. `RunController` owns the run state, while `ArenaController`, `WaveDirector`, `BuildController`, `UpgradeController`, and `EconomyController` coordinate subsystems by signals instead of hard references wherever practical.

**Tech Stack:** Godot 4.7.x, GDScript 2.0, CharacterBody2D, Area2D, AnimatedSprite2D, AnimationPlayer, CanvasLayer, Resource data objects, headless Godot smoke tests, Python/Pillow only for offline sprite-sheet preprocessing.

**Spec:** `gold-rush-roguelike/docs/superpowers/specs/2026-09-19-gold-rush-roguelike-design.md`

## Global Constraints

- Engine target is Godot 4.7.x.
- Gameplay is 2D top-down with pseudo-depth, Y-sorting, soft shadows and hand-painted sprite presentation.
- Tower-defense construction stays available during active combat.
- Player controls are WASD movement, mouse aim, LMB fire, Space/RMB dash, Q/E/R abilities/build slots and 1/2/3 defense selection.
- First slice has exactly one playable Prospector, four normal enemy archetypes, one Gold Bar Tank boss, three defenses and five handcrafted arenas.
- Run failure occurs when player HP or Gold Core HP reaches zero.
- Victory occurs after Gold Bar Tank dies while the Gold Core is alive.
- Do not modify the existing web game outside `gold-rush-roguelike/`.
- Do not ship raw debug circles/rectangles as final visual presentation.
- Frequently spawned projectiles/VFX remain unpooled until profiling proves pooling is necessary.

---

## File Map

```text
gold-rush-roguelike/
  project.godot
  icon.svg
  assets/
    source/
    sprites/player/
    sprites/enemies/
    sprites/defenses/
    sprites/props/
    vfx/
    audio/
  data/
    upgrades/
    enemies/
    defenses/
  scenes/
    main/Main.tscn
    player/Prospector.tscn
    objectives/GoldCore.tscn
    combat/Projectile.tscn
    enemies/GoldHopper.tscn
    enemies/GoldCoinSentinel.tscn
    enemies/FlyingGoldDisc.tscn
    enemies/MoltenGoldSlime.tscn
    enemies/GoldBarTank.tscn
    defenses/MagneticTurret.tscn
    defenses/CactusSentry.tscn
    defenses/TNTBarrel.tscn
    arenas/Arena01.tscn ... Arena05.tscn
    ui/HUD.tscn
    ui/UpgradeOverlay.tscn
    ui/RunEndOverlay.tscn
    vfx/HitFlash.tscn
    vfx/Explosion.tscn
  scripts/
    components/health_component.gd
    components/team_component.gd
    components/hurtbox_component.gd
    components/hitbox_component.gd
    components/weapon_component.gd
    components/projectile_component.gd
    components/targeting_component.gd
    components/gold_drop_component.gd
    components/status_effect_component.gd
    player/prospector.gd
    objectives/gold_core.gd
    enemies/enemy_base.gd
    enemies/gold_hopper.gd
    enemies/gold_coin_sentinel.gd
    enemies/flying_gold_disc.gd
    enemies/molten_gold_slime.gd
    enemies/gold_bar_tank.gd
    defenses/defense_base.gd
    defenses/magnetic_turret.gd
    defenses/cactus_sentry.gd
    defenses/tnt_barrel.gd
    systems/run_controller.gd
    systems/arena_controller.gd
    systems/wave_director.gd
    systems/build_controller.gd
    systems/economy_controller.gd
    systems/upgrade_controller.gd
    systems/camera_effects_controller.gd
    ui/hud.gd
    ui/upgrade_overlay.gd
    ui/run_end_overlay.gd
  tests/
    test_health_and_teams.gd
    test_weapon_and_projectile.gd
    test_economy_and_building.gd
    test_upgrades.gd
    test_run_flow.gd
    smoke_main_scene.gd
  tools/
    slice_reference_sheets.py
```

---

### Task 1: Bootable Godot project and deterministic test harness

**Files:**
- Create: `gold-rush-roguelike/project.godot`
- Create: `gold-rush-roguelike/scenes/main/Main.tscn`
- Create: `gold-rush-roguelike/scripts/systems/run_controller.gd`
- Create: `gold-rush-roguelike/tests/smoke_main_scene.gd`

**Interfaces:**
- Produces: `RunController.start_new_run()`, `RunController.fail_run(reason: String)`, `RunController.win_run()`.
- Produces signals: `run_started`, `run_failed(reason)`, `run_won`.

- [ ] **Step 1: Create the Godot project settings with 1280x720 viewport, stretch mode `canvas_items`, the input actions from the spec, and `Main.tscn` as the run scene.**

`project.godot` must include actions `move_left`, `move_right`, `move_up`, `move_down`, `fire`, `dash`, `ability_q`, `ability_e`, `ability_r`, `build_1`, `build_2`, `build_3`, and `pause`.

- [ ] **Step 2: Write a failing headless smoke test.**

```gdscript
extends SceneTree

func _init() -> void:
    var scene := load("res://scenes/main/Main.tscn") as PackedScene
    assert(scene != null, "Main scene must load")
    var root := scene.instantiate()
    assert(root != null, "Main scene must instantiate")
    root.queue_free()
    quit(0)
```

- [ ] **Step 3: Run the smoke test and verify it fails before the main scene exists.**

Run from repository root:

```bash
godot --headless --path gold-rush-roguelike --script res://tests/smoke_main_scene.gd
```

Expected: non-zero exit or assertion because `Main.tscn` is absent.

- [ ] **Step 4: Implement `RunController` and `Main.tscn`.**

Core `RunController` contract:

```gdscript
extends Node
class_name RunController

signal run_started
signal run_failed(reason: String)
signal run_won

var is_run_active := false
var is_run_complete := false

func start_new_run() -> void:
    is_run_active = true
    is_run_complete = false
    run_started.emit()

func fail_run(reason: String) -> void:
    if not is_run_active or is_run_complete:
        return
    is_run_active = false
    is_run_complete = true
    run_failed.emit(reason)

func win_run() -> void:
    if not is_run_active or is_run_complete:
        return
    is_run_active = false
    is_run_complete = true
    run_won.emit()
```

- [ ] **Step 5: Run headless smoke test until exit code is 0.**

- [ ] **Step 6: Commit.**

```bash
git add gold-rush-roguelike
git commit -m "feat: bootstrap Gold Rush Godot project"
```

---

### Task 2: Shared combat components

**Files:**
- Create: `scripts/components/health_component.gd`
- Create: `scripts/components/team_component.gd`
- Create: `scripts/components/hurtbox_component.gd`
- Create: `scripts/components/hitbox_component.gd`
- Create: `scripts/components/status_effect_component.gd`
- Create: `tests/test_health_and_teams.gd`

**Interfaces:**
- Produces `HealthComponent.damage(amount: float)`, `heal(amount: float)`, `reset_health()`, `is_dead() -> bool`.
- Produces signals `health_changed(current: float, maximum: float)` and `died`.
- Produces `TeamComponent.Team { PLAYER, ENEMY, NEUTRAL }` and `is_hostile_to(other: TeamComponent) -> bool`.
- `HurtboxComponent.receive_hit(damage: float, source_team: TeamComponent.Team, knockback: Vector2)` ignores friendly hits and forwards hostile damage to `HealthComponent`.

- [ ] **Step 1: Write the failing component test.**

```gdscript
extends SceneTree

func _init() -> void:
    var health := HealthComponent.new()
    health.max_health = 100.0
    add_child(health)
    health.reset_health()
    health.damage(25.0)
    assert(is_equal_approx(health.current_health, 75.0))
    health.heal(10.0)
    assert(is_equal_approx(health.current_health, 85.0))

    var player := TeamComponent.new()
    player.team = TeamComponent.Team.PLAYER
    var enemy := TeamComponent.new()
    enemy.team = TeamComponent.Team.ENEMY
    assert(player.is_hostile_to(enemy))
    assert(not player.is_hostile_to(player))
    quit(0)
```

- [ ] **Step 2: Verify the test fails because classes are missing.**

```bash
godot --headless --path gold-rush-roguelike --script res://tests/test_health_and_teams.gd
```

- [ ] **Step 3: Implement components with exported tuning values, typed signals and null-safe dependencies.**

`damage()` must clamp at zero, emit `died` once per reset and reject negative damage. `heal()` must clamp to `max_health`.

- [ ] **Step 4: Run component test to green.**

- [ ] **Step 5: Commit.**

```bash
git add gold-rush-roguelike/scripts/components gold-rush-roguelike/tests/test_health_and_teams.gd
git commit -m "feat: add reusable combat components"
```

---

### Task 3: Projectile weapon pipeline and Prospector controller

**Files:**
- Create: `scripts/components/weapon_component.gd`
- Create: `scripts/components/projectile_component.gd`
- Create: `scenes/combat/Projectile.tscn`
- Create: `scripts/player/prospector.gd`
- Create: `scenes/player/Prospector.tscn`
- Create: `tests/test_weapon_and_projectile.gd`

**Interfaces:**
- `WeaponComponent.try_fire(origin: Vector2, direction: Vector2, owner_team: TeamComponent.Team) -> bool`.
- `ProjectileComponent.configure(direction: Vector2, speed: float, damage: float, owner_team: TeamComponent.Team) -> void`.
- `Prospector` exposes `get_aim_direction() -> Vector2`, `request_dash()`, `set_input_enabled(enabled: bool)`.
- Prospector signal: `player_died`.

- [ ] **Step 1: Write the failing weapon test using a fake projectile PackedScene.**

```gdscript
extends SceneTree

func _init() -> void:
    var weapon := WeaponComponent.new()
    weapon.cooldown_sec = 0.25
    add_child(weapon)
    assert(weapon.can_fire())
    weapon.mark_fired()
    assert(not weapon.can_fire())
    quit(0)
```

- [ ] **Step 2: Run and confirm failure.**

- [ ] **Step 3: Implement projectile movement and hostile-only hit handling.**

Projectile must move in `_physics_process(delta)` with `global_position += direction * speed * delta`, expire after exported lifetime, and call `receive_hit()` on compatible hostile hurtboxes.

- [ ] **Step 4: Implement Prospector movement using Godot 4.7 `Input.get_vector()` and `move_and_slide()` with no arguments.**

Required movement skeleton:

```gdscript
func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var target_velocity := input_dir * move_speed
    velocity = velocity.move_toward(target_velocity, acceleration * delta)
    if input_dir == Vector2.ZERO:
        velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
    move_and_slide()
```

Implement aim toward `get_global_mouse_position()`, LMB shooting and dash with exported speed, duration, cooldown and invulnerability window.

- [ ] **Step 5: Build `Prospector.tscn` from editable nodes, not code-generated visuals: CharacterBody2D + CollisionShape2D + visual pivot + AnimatedSprite2D + soft-shadow Sprite2D + Health/Team/Hurtbox/Weapon child nodes.**

- [ ] **Step 6: Run weapon test and launch the scene manually; verify WASD, aim, fire and dash.**

- [ ] **Step 7: Commit.**

```bash
git add gold-rush-roguelike/scripts/components gold-rush-roguelike/scripts/player gold-rush-roguelike/scenes/player gold-rush-roguelike/scenes/combat gold-rush-roguelike/tests/test_weapon_and_projectile.gd
git commit -m "feat: add Prospector movement shooting and dash"
```

---

### Task 4: Gold Core and four normal enemy archetypes

**Files:**
- Create: `scripts/objectives/gold_core.gd`
- Create: `scenes/objectives/GoldCore.tscn`
- Create: `scripts/enemies/enemy_base.gd`
- Create: `scripts/enemies/gold_hopper.gd`
- Create: `scripts/enemies/gold_coin_sentinel.gd`
- Create: `scripts/enemies/flying_gold_disc.gd`
- Create: `scripts/enemies/molten_gold_slime.gd`
- Create: four corresponding `.tscn` scenes

**Interfaces:**
- `EnemyBase.set_targets(player: Node2D, core: Node2D) -> void`.
- `EnemyBase.choose_target() -> Node2D`.
- Enemy signal: `enemy_died(enemy: Node, gold_value: int)`.
- `GoldCore` signal: `core_destroyed`.

- [ ] **Step 1: Add a deterministic target-choice test to `tests/test_run_flow.gd`.**

Use a basic enemy with `prefer_core_weight = 1.0` and assert it selects a valid supplied target; then remove the player and assert it falls back to the core.

- [ ] **Step 2: Implement `EnemyBase` with target references, health/death wiring, navigation-free steering for the first slice, separation force, and exported speed/damage/attack_range values.**

- [ ] **Step 3: Implement archetypes.**

Gold Hopper: timed hop burst toward target and contact attack.

Gold Coin Sentinel: keep-distance steering, visible telegraph timer, then projectile fire.

Flying Gold Disc: ignores ground prop collision layer and strafes around target while firing short bursts.

Molten Gold Slime: slow pursuit; periodically spawns an Area2D puddle with timed hostile damage.

- [ ] **Step 4: Build each enemy as editable `.tscn` scene with its components and AnimatedSprite2D placeholder frame source.**

- [ ] **Step 5: Run the target test and manually spawn one of each enemy with player/core. Verify no parser errors and valid attacks.**

- [ ] **Step 6: Commit.**

```bash
git add gold-rush-roguelike/scripts/enemies gold-rush-roguelike/scripts/objectives gold-rush-roguelike/scenes/enemies gold-rush-roguelike/scenes/objectives gold-rush-roguelike/tests/test_run_flow.gd
git commit -m "feat: add Gold Core and enemy roster"
```

---

### Task 5: Gold economy and real-time defense building

**Files:**
- Create: `scripts/components/gold_drop_component.gd`
- Create: `scripts/systems/economy_controller.gd`
- Create: `scripts/systems/build_controller.gd`
- Create: `scripts/defenses/defense_base.gd`
- Create: `scripts/defenses/magnetic_turret.gd`
- Create: `scripts/defenses/cactus_sentry.gd`
- Create: `scripts/defenses/tnt_barrel.gd`
- Create: three defense `.tscn` scenes
- Create: `tests/test_economy_and_building.gd`

**Interfaces:**
- `EconomyController.add_gold(amount: int)`, `can_afford(cost: int) -> bool`, `spend_gold(cost: int) -> bool`.
- Signal `gold_changed(total: int)`.
- `BuildController.select_defense(slot: int)`, `begin_preview()`, `confirm_build(world_position: Vector2) -> bool`, `cancel_build()`.
- `DefenseBase.get_build_cost() -> int`.

- [ ] **Step 1: Write failing economy test.**

```gdscript
extends SceneTree

func _init() -> void:
    var economy := EconomyController.new()
    add_child(economy)
    economy.add_gold(100)
    assert(economy.can_afford(60))
    assert(economy.spend_gold(60))
    assert(economy.gold == 40)
    assert(not economy.spend_gold(50))
    assert(economy.gold == 40)
    quit(0)
```

- [ ] **Step 2: Implement economy and a gold pickup Area2D that credits currency on collection.**

- [ ] **Step 3: Implement build preview as a semi-transparent scene instance snapped to allowed placement zones; invalid positions render as invalid and cannot spend gold.**

- [ ] **Step 4: Implement defenses.**

Magnetic Turret: TargetingComponent finds nearest hostile in range, rotates aim pivot, WeaponComponent fires.

Cactus Sentry: shorter range, faster inexpensive shots.

TNT Barrel: arms after placement, explodes on hostile overlap or player trigger; radial hitbox damages enemies only and destroys barrel.

- [ ] **Step 5: Run economy test and manually verify placing each defense deducts exactly its exported cost while gameplay remains active.**

- [ ] **Step 6: Commit.**

```bash
git add gold-rush-roguelike/scripts/systems gold-rush-roguelike/scripts/defenses gold-rush-roguelike/scripts/components/gold_drop_component.gd gold-rush-roguelike/scenes/defenses gold-rush-roguelike/tests/test_economy_and_building.gd
git commit -m "feat: add gold economy and real-time defenses"
```

---

### Task 6: Arena controller, wave director and five-scene run flow

**Files:**
- Create: `scripts/systems/arena_controller.gd`
- Create: `scripts/systems/wave_director.gd`
- Create: `scenes/arenas/Arena01.tscn` through `Arena05.tscn`
- Modify: `scenes/main/Main.tscn`
- Extend: `tests/test_run_flow.gd`

**Interfaces:**
- `ArenaController.load_arena(index: int)`, `complete_current_arena()`.
- Signals `arena_started(index: int)`, `arena_completed(index: int)`, `all_arenas_completed`.
- `WaveDirector.start_wave(definition: Array[Dictionary])`, `stop_spawning()`, `get_alive_enemy_count() -> int`.
- Signals `wave_started(number: int)`, `wave_completed(number: int)`.

- [ ] **Step 1: Write test asserting the arena index progresses 1 -> 5 and then emits completion instead of loading index 6.**

- [ ] **Step 2: Implement wave spawn marker contract.**

Every arena must expose child groups `enemy_spawn`, `player_spawn`, `core_spawn`, and `build_zone`.

- [ ] **Step 3: Build five handcrafted `.tscn` arenas from editable Node2D/TileMapLayer/Polygon2D/Sprite2D/Marker2D objects.**

Arena 1 teaches shooting and Hopper enemies.
Arena 2 unlocks Magnetic Turret.
Arena 3 mixes Sentinel/Disc and requires TNT.
Arena 4 is elite pressure with Slimes.
Arena 5 is boss arena.

- [ ] **Step 4: Wire RunController -> ArenaController -> WaveDirector. Arena completion pauses spawning and requests upgrade choice before advancing.**

- [ ] **Step 5: Run flow test and perform a no-art gameplay pass through all five arenas with debug spawn counts visible only through editor/output, not final HUD.**

- [ ] **Step 6: Commit.**

```bash
git add gold-rush-roguelike/scripts/systems gold-rush-roguelike/scenes/arenas gold-rush-roguelike/scenes/main gold-rush-roguelike/tests/test_run_flow.gd
git commit -m "feat: add five-arena wave progression"
```

---

### Task 7: Roguelike upgrade resources and 1-of-3 selection

**Files:**
- Create: `scripts/systems/upgrade_controller.gd`
- Create: `scripts/ui/upgrade_overlay.gd`
- Create: `scenes/ui/UpgradeOverlay.tscn`
- Create: `data/upgrades/*.tres`
- Create: `tests/test_upgrades.gd`

**Interfaces:**
- `UpgradeController.roll_choices(count: int = 3) -> Array[Resource]` returns distinct available definitions.
- `UpgradeController.apply_upgrade(id: StringName) -> void`.
- Signal `upgrade_selected(id: StringName)`.

- [ ] **Step 1: Write a failing test that uses a fixed RNG seed, requests three upgrades and asserts three unique IDs.**

- [ ] **Step 2: Create upgrade definitions for weapon damage, fire rate, projectile speed, max HP, dash recovery, turret damage, turret fire rate, defense max HP, gold pickup value and crit chance.**

Each `.tres` stores `id`, `display_name`, `description`, `stat_key`, `operation`, `amount`, and icon path.

- [ ] **Step 3: Implement stat modifier application through explicit methods on player/run stats; do not use arbitrary string `set()` against gameplay nodes.**

- [ ] **Step 4: Implement UpgradeOverlay as three keyboard/mouse-selectable cards; gameplay pauses during selection and resumes after one choice.**

- [ ] **Step 5: Run upgrade test and verify every upgrade changes the intended stat in a live run.**

- [ ] **Step 6: Commit.**

```bash
git add gold-rush-roguelike/scripts/systems/upgrade_controller.gd gold-rush-roguelike/scripts/ui/upgrade_overlay.gd gold-rush-roguelike/scenes/ui/UpgradeOverlay.tscn gold-rush-roguelike/data/upgrades gold-rush-roguelike/tests/test_upgrades.gd
git commit -m "feat: add roguelike upgrade choices"
```

---

### Task 8: Gold Bar Tank boss encounter

**Files:**
- Create: `scripts/enemies/gold_bar_tank.gd`
- Create: `scenes/enemies/GoldBarTank.tscn`
- Modify: `scenes/arenas/Arena05.tscn`
- Extend: `tests/test_run_flow.gd`

**Interfaces:**
- Boss state enum: `INTRO`, `CHASE`, `CHARGE_TELEGRAPH`, `CHARGE`, `BURST`, `SLAM`, `SPAWN_ADDS`, `DEAD`.
- Signals `boss_phase_changed(phase: int)`, `boss_died`.

- [ ] **Step 1: Add a state-machine test that damages the boss below phase threshold and asserts it can transition out of phase one without invalid states.**

- [ ] **Step 2: Implement charge with visible telegraph and collision-safe stop.**

- [ ] **Step 3: Implement projectile burst, radial ground slam and add-spawn attack.**

- [ ] **Step 4: Use health thresholds to shorten cooldowns/add attack combinations without changing the external interface.**

- [ ] **Step 5: Connect `boss_died` to `RunController.win_run()` only when Gold Core remains alive.**

- [ ] **Step 6: Run boss encounter repeatedly; verify every attack is telegraphed and the fight can be won with only the base weapon plus one defense.**

- [ ] **Step 7: Commit.**

```bash
git add gold-rush-roguelike/scripts/enemies/gold_bar_tank.gd gold-rush-roguelike/scenes/enemies/GoldBarTank.tscn gold-rush-roguelike/scenes/arenas/Arena05.tscn gold-rush-roguelike/tests/test_run_flow.gd
git commit -m "feat: add Gold Bar Tank boss"
```

---

### Task 9: HUD, run-end screens, camera feedback and audio hooks

**Files:**
- Create: `scripts/ui/hud.gd`
- Create: `scripts/ui/run_end_overlay.gd`
- Create: `scripts/systems/camera_effects_controller.gd`
- Create: `scenes/ui/HUD.tscn`
- Create: `scenes/ui/RunEndOverlay.tscn`
- Create: `scenes/vfx/HitFlash.tscn`
- Create: `scenes/vfx/Explosion.tscn`
- Modify: `scenes/main/Main.tscn`

**Interfaces:**
- `HUD.bind_player(player)`, `bind_core(core)`, `bind_economy(economy)`, `set_arena(index: int)`, `show_boss(health_component)`.
- `CameraEffectsController.shake(strength: float, duration: float)`.
- `RunEndOverlay.show_failure(reason: String)` and `show_victory()`.

- [ ] **Step 1: Build HUD as CanvasLayer with player HP, core HP, gold, arena/wave, dash cooldown, three build slots and boss bar.**

- [ ] **Step 2: Bind HUD exclusively through signals so it does not poll actor state each frame except smooth visual interpolation.**

- [ ] **Step 3: Add VFX hooks: muzzle flash, hit flash, dust, gold particles, TNT explosion and strong-impact camera shake.**

- [ ] **Step 4: Configure audio buses `Master`, `Music`, `SFX`, `UI` and create event hook functions even where source clips are temporarily absent. Missing clips must fail silently, never produce missing-resource errors.**

- [ ] **Step 5: Implement death/victory overlay and restart button with `get_tree().reload_current_scene()`.**

- [ ] **Step 6: Run a complete no-art victory and failure pass. Confirm HUD and overlays update correctly.**

- [ ] **Step 7: Commit.**

```bash
git add gold-rush-roguelike/scripts/ui gold-rush-roguelike/scripts/systems/camera_effects_controller.gd gold-rush-roguelike/scenes/ui gold-rush-roguelike/scenes/vfx gold-rush-roguelike/scenes/main
git commit -m "feat: add HUD feedback and run-end presentation"
```

---

### Task 10: Reference-art preprocessing and sprite integration

**Files:**
- Create: `tools/slice_reference_sheets.py`
- Populate: `assets/source/` with the supplied reference sheets
- Populate: `assets/sprites/player/`, `assets/sprites/enemies/`, `assets/sprites/defenses/`, `assets/sprites/props/`
- Modify relevant `.tscn` files to use the sliced sprite assets

**Interfaces:**
- Tool CLI: `python tools/slice_reference_sheets.py --input <sheet> --output <dir> --prefix <name>`.
- Output PNGs use transparent backgrounds, consistent padding and bottom-center anchors documented in generated JSON metadata.

- [ ] **Step 1: Implement the slicer using Pillow.**

The tool must flood-fill near-uniform sheet background only from image edges, preserve internal light pixels, feather the alpha edge by 1-2 px, find disconnected foreground islands, reject tiny label/text components by minimum area, trim each sprite, and pad to a consistent canvas. Never use a simple rectangular crop as the final alpha source.

- [ ] **Step 2: Generate a contact sheet preview for each source sheet and inspect it before integration.**

Use the supplied Prospector, Gold Hopper/Nugget, Gold Bar Tank, Magnetic Turret and defense sheets. Keep one sprite family per output folder.

- [ ] **Step 3: Fix incorrect masks manually or with per-sheet threshold overrides until no obvious white/gray rectangles remain around actors.**

- [ ] **Step 4: Build SpriteFrames resources and named animations `idle`, `move`, `attack`, `hit`, `death` where the supplied frames support them. Do not invent missing frame sequences by duplicating a single frame more than necessary for placeholder idle.**

- [ ] **Step 5: Apply consistent bottom-center origins and shadow positions so enemies do not float or overlap HUD/build icons. Enable Y-sort containers in arenas.**

- [ ] **Step 6: Launch every arena and inspect scale consistency against the supplied reference battle scenes.**

- [ ] **Step 7: Commit.**

```bash
git add gold-rush-roguelike/assets gold-rush-roguelike/tools gold-rush-roguelike/scenes
git commit -m "art: integrate Gold Rush reference sprites"
```

---

### Task 11: Balance pass, regression tests and release smoke check

**Files:**
- Modify exported tuning values in scenes/resources as needed
- Modify tests if a discovered regression needs a permanent guard
- Create: `gold-rush-roguelike/README.md`

**Interfaces:**
- No new gameplay API. This task validates existing contracts.

- [ ] **Step 1: Run every automated headless test.**

```bash
godot --headless --path gold-rush-roguelike --script res://tests/test_health_and_teams.gd
godot --headless --path gold-rush-roguelike --script res://tests/test_weapon_and_projectile.gd
godot --headless --path gold-rush-roguelike --script res://tests/test_economy_and_building.gd
godot --headless --path gold-rush-roguelike --script res://tests/test_upgrades.gd
godot --headless --path gold-rush-roguelike --script res://tests/test_run_flow.gd
godot --headless --path gold-rush-roguelike --script res://tests/smoke_main_scene.gd
```

Expected: all exit 0 with no parser errors.

- [ ] **Step 2: Run Godot's editor import/headless project check.**

```bash
godot --headless --editor --path gold-rush-roguelike --quit
```

Expected: exit 0 and no critical missing-resource errors.

- [ ] **Step 3: Complete one full manual run using only base weapon + one defense and another run emphasizing three defenses.**

Verify: player movement/aim/fire/dash, enemy targeting, gold collection, build costs, all defense attacks, three-choice upgrades, all arena transitions, boss attacks, player/core failure, victory screen, restart.

- [ ] **Step 4: Tune only exported/resource values for first balance pass.**

Target first successful run length: roughly 12-20 minutes. Arena 1 should be survivable without building; boss should require movement and use of at least one learned system but not a specific mandatory upgrade roll.

- [ ] **Step 5: Write README with Godot version, launch instructions, controls, asset-source note and test commands.**

- [ ] **Step 6: Final visual QA.**

Check for visible crop rectangles, inconsistent sprite baselines, floating shadows, incorrect Y-sort, UI overlap, excessive screen shake, unreadable gold enemies against bright ground, and build-preview positions that block the player/core spawn.

- [ ] **Step 7: Commit.**

```bash
git add gold-rush-roguelike
git commit -m "chore: validate and balance Gold Rush vertical slice"
```

---

## Completion Gate

The vertical slice is complete only when all of these are true:

1. `project.godot` opens in Godot 4.7.x without parser errors.
2. Main scene launches and a complete five-arena run is possible.
3. Prospector can move, aim, shoot and dash.
4. All four normal enemy types spawn and can damage a valid hostile target.
5. Gold pickups increase spendable currency.
6. Magnetic Turret, Cactus Sentry and TNT Barrel can all be placed during active combat and function.
7. Upgrade overlay presents three distinct choices and selected upgrades alter run stats.
8. Gold Bar Tank uses charge, projectile burst, slam and add-spawn attacks and can be defeated.
9. Player or Gold Core death produces failure state.
10. Boss death with surviving Gold Core produces victory state.
11. No critical missing-resource messages occur in Godot output.
12. Integrated sprites have clean alpha edges and no visible rectangular sheet backgrounds.
13. Existing repository web files outside `gold-rush-roguelike/` remain unchanged.
