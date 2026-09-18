# Дача: Last Day — Prototype 0.4

Godot 4.7.2 vertical slice: 2D isometric Survival + Tower Defence.

## Current gameplay
- WASD movement, mouse aim/fire, R reload, Shift dash.
- Survival waves: psycho chickens, charging boars, ranged neighbors.
- XP, levels and 3 perk choices.
- Scrap economy.
- Every third wave opens a build phase, followed by a real DachaCore defense wave.
- Four structures: potato turret, brazier, healing fridge and barricade.
- King Boar miniboss every fifth wave.
- Day/evening/defense atmosphere tint.
- Muzzle flash and impact VFX.
- HUD health/XP bars and boss readout.

## Production sprite pipeline
Character scenes support 4x8 atlases: 4 animation frames for each of 8 directions, 192x192 per frame. Put these optional production PNGs into `res://assets/characters/`:

- `vitya_atlas.png`
- `chicken_atlas.png`
- `boar_atlas.png`
- `neighbor_atlas.png`

When an atlas is absent the project automatically falls back to the vector placeholder for CI/source checkouts. The packaged art build contains the normalized atlases.

Optional audio files in `res://audio/`:
- `shotgun.wav`
- `hit.wav`
- `level_up.wav`

## Validation
GitHub Actions downloads Godot 4.7.2, imports/parses the project, runs the gameplay smoke test, renders a real 1280x720 preview under Xvfb, and uploads both the screenshot and source ZIP as artifacts.
