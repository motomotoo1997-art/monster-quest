# Gold Rush Roguelike

A Godot 4.7.2 top-down roguelike shooter with real-time tower-defense construction.

## Current vertical slice

The playable slice contains one Prospector, a protected Gold Core, five handcrafted desert/mining arenas, four normal gold-enemy archetypes, three buildable defenses, run-scoped 1-of-3 upgrades, and the Gold Bar Tank boss.

### Core loop

1. Enter an arena and protect the Gold Core.
2. Move and shoot continuously while enemies attack.
3. Pick up gold dropped by enemies.
4. Spend gold to place defenses during active combat.
5. Clear the arena and choose one of three roguelike upgrades.
6. Advance through five arenas.
7. Defeat the Gold Bar Tank while keeping the Prospector and Gold Core alive.

## Ready-to-run Windows build

Every successful CI run on `feature/gold-rush-vertical-slice` exports a Windows x86_64 build using the official Godot 4.7.2 export templates.

In GitHub Actions, open the latest successful **Gold Rush Godot CI** run and download the artifact:

`GoldRushRoguelike-Windows-x86_64`

The artifact contains `GoldRushRoguelike.exe`. The project uses an embedded PCK, so the executable is self-contained for this vertical slice.

## Requirements for editor development

- Godot **4.7.2** (standard GDScript build)
- Windows, Linux, or macOS editor supported by Godot
- Python 3 + Pillow only when using the optional reference-sheet slicer

## Launch in Godot

Open `project.godot` in Godot 4.7.2 and run the project. The configured main scene is:

`res://scenes/main/Main.tscn`

Command-line launch:

```bash
godot --path .
```

## Controls

| Input | Action |
| --- | --- |
| WASD | Move |
| Mouse | Aim |
| Left mouse | Fire / confirm build placement |
| Space or Right mouse | Dash |
| 1 / Q | Defense slot 1 |
| 2 / E | Defense slot 2 |
| 3 | Defense slot 3 |
| R | Trigger placed TNT when available |
| Esc | Pause |

The run starts with **Cactus Sentry** (slot 2). **Magnetic Turret** (slot 1) unlocks from Arena 2 and **TNT Barrel** (slot 3) unlocks from Arena 3.

## Enemies

- **Gold Hopper** — short-range chaser with an actual hop movement cycle and squash/stretch presentation.
- **Gold Coin Sentinel** — ranged enemy with a visible attack telegraph.
- **Flying Gold Disc** — fast hovering ranged harasser with strafe movement and hover/bank presentation.
- **Molten Gold Slime** — durable pursuer that leaves damaging molten puddles and visibly squashes while moving.
- **Gold Bar Tank** — multi-phase boss with charge, projectile burst, ground slam, and add-spawn attacks.

## Defenses

- **Cactus Sentry** — inexpensive short-range automatic defense with firing recoil.
- **Magnetic Turret** — longer-range automatic turret with idle magnetic hum/recoil motion.
- **TNT Barrel** — disposable area-damage trap with automatic or manual triggering and an armed pulse.

All build costs and most combat tuning values are exported in scenes/scripts, so balance changes do not require architecture changes.

## Roguelike upgrades

Current run-scoped upgrade pool includes weapon damage, fire rate, projectile speed, maximum HP, dash recovery, turret damage, turret fire rate, defense maximum HP, gold pickup value, and critical-hit chance.

There is no permanent metaprogression in this vertical slice.

## Visual pipeline

The visual-overhaul runtime now uses a crisp 2.5D western/mining presentation with dark silhouettes, warm sandstone/ochre environments, cyan energy accents, orange danger telegraphs, layered contact shadows and scene-editable props.

Current production art includes:

- detailed Prospector reference-frame animation set under `assets/sprites/player/reference_frames/`
- `assets/sprites/enemies/enemies_frontier_v6.svg` plus the refined Frontier Juggernaut boss presentation
- `assets/sprites/defenses/defenses_frontier_v6.svg`
- `assets/vfx/combat_feedback_v6.svg` for player/boss bolts, hit impacts, explosions and gold pickups
- distinct Arena01-Arena05 environment backdrops, including `arena05_molten_foundry_v6.svg`
- scene-editable foundry, mining, cactus, rock, rail, cart and gold-vein landmarks rather than a single baked gameplay screenshot

CI performs visual regression checks in addition to gameplay tests. Successful runs capture dense Arena01 combat, Arena05 laser telegraph, Arena05 slam telegraph and the upgrade-selection UI before exporting Windows x86_64. The slam benchmark specifically guards against warning VFX washing out the boss silhouette.

The optional concept-sheet preprocessing utility remains available for future high-resolution replacement art:

```bash
python tools/slice_reference_sheets.py \
  --input assets/source/example.jpeg \
  --output assets/sprites/generated/example \
  --prefix example
```

It removes only border-connected near-background pixels and normalizes extracted sprites to a shared bottom-center anchor. Any regenerated strip still needs visual QA before replacing production art.

## Automated tests and export

From the Godot project directory:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/test_health_and_teams.gd
godot --headless --path . --script res://tests/test_weapon_and_projectile.gd
godot --headless --path . --script res://tests/test_economy_and_building.gd
godot --headless --path . --script res://tests/test_upgrades.gd
godot --headless --path . --script res://tests/test_run_flow.gd
godot --headless --path . --script res://tests/smoke_main_scene.gd
```

The CI pipeline runs all of these checks with Godot 4.7.2, installs the matching official export templates, exports the `Windows Desktop` preset, verifies that the executable is non-empty, and uploads it as a GitHub Actions artifact.

## Project layout

- `scenes/arenas/` — five editable encounter layouts with separate collision and decoration.
- `scenes/environment/` — movable environment props.
- `scenes/player/`, `scenes/enemies/`, `scenes/defenses/` — gameplay actor scenes.
- `scenes/ui/`, `scenes/vfx/` — HUD, overlays, and effects.
- `scripts/components/` — reusable combat/data components.
- `scripts/systems/` — run, arena, economy, build, upgrade, camera, and wave coordination.
- `data/upgrades/` — run-upgrade definitions.
- `assets/` — runtime vector art and environment assets.
- `tools/` — optional offline art preprocessing utilities.
- `tests/` — headless regression/smoke tests.
- `export_presets.cfg` — Windows x86_64 export preset.

## Scope boundary

This vertical slice intentionally excludes online multiplayer, procedural world generation, permanent meta-progression, multiple playable heroes, a large inventory system, and mobile/console-specific ports.
