# Gold Rush Roguelike

A Godot 4.7.2 top-down roguelike shooter with real-time tower-defense construction.

## Current vertical slice

The first playable slice contains one Prospector, a protected Gold Core, five handcrafted desert/mining arenas, four normal gold-enemy archetypes, three buildable defenses, run-scoped 1-of-3 upgrades, and the Gold Bar Tank boss.

### Core loop

1. Enter an arena and protect the Gold Core.
2. Move and shoot continuously while enemies attack.
3. Pick up gold dropped by enemies.
4. Spend gold to place defenses during active combat.
5. Clear the arena and choose one of three roguelike upgrades.
6. Advance through five arenas.
7. Defeat the Gold Bar Tank while keeping the Prospector and Gold Core alive.

## Requirements

- Godot **4.7.2** (standard GDScript build)
- Windows, Linux, or macOS editor supported by Godot
- Python 3 + Pillow only if regenerating sprite assets with the optional sheet slicer

## Launch

Open `project.godot` in Godot 4.7.2 and run the project with `F6/F5` as appropriate. The configured main scene is:

`res://scenes/main/Main.tscn`

Command-line smoke launch:

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

Defense progression in the current slice starts with Cactus Sentry. Magnetic Turret unlocks from Arena 2 and TNT Barrel from Arena 3.

## Enemies

- **Gold Hopper** — aggressive short-range chaser.
- **Gold Coin Sentinel** — ranged enemy with a visible attack telegraph.
- **Flying Gold Disc** — fast hovering ranged harasser that ignores ground-body collision.
- **Molten Gold Slime** — durable pursuer that leaves damaging molten puddles.
- **Gold Bar Tank** — multi-phase boss with charge, projectile burst, ground slam, and add-spawn attacks.

## Defenses

- **Cactus Sentry** — inexpensive short-range automatic defense.
- **Magnetic Turret** — longer-range automatic turret.
- **TNT Barrel** — disposable area-damage trap with automatic or manual triggering.

All build costs and most combat tuning values are exported in scenes/scripts so the balance pass does not require architecture changes.

## Roguelike upgrades

Current run-scoped upgrade pool includes weapon damage, fire rate, projectile speed, maximum HP, dash recovery, turret damage, turret fire rate, defense maximum HP, gold pickup value, and critical-hit chance.

There is no permanent metaprogression in this vertical slice.

## Art pipeline

Prototype character/enemy/defense visuals are derived from the concept/reference sheets supplied for this project. The integrated atlases have edge-connected background removal and bottom-centered alignment rather than rectangular white-background crops.

The reusable preprocessing tool is:

```bash
python tools/slice_reference_sheets.py \
  --input assets/source/example.jpeg \
  --output assets/sprites/generated/example \
  --prefix example
```

Useful tuning options include `--threshold`, `--max-chroma`, `--min-area`, `--padding`, `--feather`, and `--canvas`.

The current integration deliberately uses a single approved frame where a clean animation strip has not yet passed visual QA. It does not duplicate one frame into fake motion sequences.

## Automated tests

From the directory containing this Godot project:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/test_health_and_teams.gd
godot --headless --path . --script res://tests/test_weapon_and_projectile.gd
godot --headless --path . --script res://tests/test_economy_and_building.gd
godot --headless --path . --script res://tests/test_upgrades.gd
godot --headless --path . --script res://tests/test_run_flow.gd
godot --headless --path . --script res://tests/smoke_main_scene.gd
```

GitHub Actions runs the same headless checks on `feature/gold-rush-vertical-slice` using Godot 4.7.2.

## Project layout

- `scenes/` — editable gameplay, arena, UI, defense, enemy, and VFX scenes.
- `scripts/components/` — reusable combat/data components.
- `scripts/systems/` — run, arena, economy, build, upgrade, camera, and wave coordination.
- `scripts/player/`, `scripts/enemies/`, `scripts/defenses/` — focused actor controllers.
- `data/upgrades/` — run-upgrade definitions.
- `assets/sprites/` — processed game-ready art atlases.
- `tools/` — offline art preprocessing utilities.
- `tests/` — headless regression/smoke tests.

## Scope boundary

This slice intentionally excludes online multiplayer, procedural world generation, permanent meta-progression, multiple playable heroes, a large inventory system, and mobile/console-specific ports.
