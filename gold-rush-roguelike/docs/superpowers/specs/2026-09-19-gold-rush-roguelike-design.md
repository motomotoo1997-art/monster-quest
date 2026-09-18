# Gold Rush Roguelike — Design Spec

## Goal
Build a standalone Godot 4.7.x top-down 2D roguelike shooter with real-time tower-defense mechanics, using the supplied western/gold-rush artwork as the visual target and source material for prototyping.

## Core Fantasy
The player is a prospector defending a portable gold core while pushing through hostile mining arenas. Enemies are animated gold creatures and machines. The player fights directly with firearms while placing defensive devices during combat.

## Core Controls
- WASD: movement
- Mouse: aim
- Left mouse: primary fire
- Space or right mouse: dash
- Q/E/R: active abilities / defensive placement slots
- 1/2/3: quick-select buildable defenses when unlocked

## Core Loop
1. Enter an arena.
2. Fight enemies in real time while protecting the Gold Core.
3. Kill enemies to earn gold and temporary run XP.
4. Spend gold during combat to place or upgrade defenses.
5. Complete a wave or arena objective.
6. Choose one of three roguelike upgrades.
7. Move to the next arena.
8. Every few arenas, face an elite encounter or event.
9. End the first vertical slice with the Gold Bar Tank boss.

## Hybrid Tower Defense Rules
Tower-defense construction remains available during active combat. The player can reposition freely and continue shooting while building. Construction uses a short placement preview and immediate placement rather than a separate build phase.

The vertical slice includes:
- Magnetic Turret: ranged automatic turret with magnetic VFX and target tracking.
- Cactus Sentry: cheaper short-range automatic defense.
- TNT Barrel: disposable trap that explodes on contact or player trigger.

All defenses use the same health/damage/team component interfaces as other combat actors where possible.

## Player
### Prospector
- CharacterBody2D root.
- Movement with acceleration/deceleration.
- Mouse-facing aim pivot.
- Primary revolver/rifle-style projectile weapon.
- Dash with short invulnerability window and cooldown.
- Health, hit flash, knockback resistance and death state.
- AnimatedSprite2D or AnimationPlayer-driven state presentation.

## Enemies
The first slice uses at least four normal archetypes plus one boss:
- Gold Nugget / Hopper: basic melee chaser, can hop toward the player.
- Gold Coin Sentinel: ranged enemy with telegraphed shots.
- Flying Gold Disc: flying harasser that ignores some ground obstacles.
- Molten Gold Slime: slow enemy that leaves a temporary damaging puddle.
- Gold Bar Tank: boss with charge, projectile burst, ground slam and add-spawn phases.

Enemy logic is data-driven through exported tuning values and shared components rather than one giant script.

## Arena Structure
Use compact handcrafted 2D arenas for the first slice rather than procedural generation.

Arena flow:
- Arena 1: tutorial combat + basic enemies.
- Arena 2: unlock Magnetic Turret.
- Arena 3: mixed enemy wave + TNT usage.
- Arena 4: elite encounter.
- Arena 5: Gold Bar Tank boss.

Each arena includes obstacle props, mine/canyon dressing, spawn markers, defense placement zones, player spawn and Gold Core spawn.

## Gold Core
The Gold Core is the tower-defense objective. Enemies can target either the player or the core depending on archetype and threat rules. The run fails if the player dies or the Gold Core reaches zero HP.

## Roguelike Progression
After an arena or major wave, pause spawning and present three upgrade cards. The player selects one.

Initial upgrade pool:
- +weapon damage
- +fire rate
- +projectile speed
- +maximum HP
- +dash cooldown recovery
- +turret damage
- +turret fire rate
- +defense maximum HP
- +gold pickup value
- chance for critical hits

Upgrades are run-scoped only for the first slice; permanent metaprogression is out of scope.

## Economy
Gold is both score and tactical build currency. Enemies drop pickups. Gold is spent on defenses and defense upgrades during the run.

Initial costs are exported values so balancing does not require code edits.

## Visual Direction
Target a polished 2D top-down / pseudo-isometric western gold-rush look matching the supplied references:
- hand-painted / illustrated sprites
- strong silhouettes
- warm sand and canyon palette
- bright gold enemy materials
- soft ground shadows
- Y-sorting for actors and props
- hit flashes, muzzle flashes, dust, sparks and gold particles
- screen shake only for strong impacts
- no raw debug shapes in the final presentation layer

The supplied image sheets are treated as source references and prototype sprite material. Any cropping/slicing must keep transparent margins consistent and avoid visible rectangular cutout artifacts.

## Rendering and Scene Strategy
- Godot 4.7.x
- 2D renderer
- CharacterBody2D for moving actors
- Area2D for hitboxes, pickups and triggers
- AnimatedSprite2D for sprite-sheet animation where appropriate
- AnimationPlayer for compound presentation and non-frame-based animation
- CanvasLayer for HUD
- Y-sort enabled on gameplay actor containers
- Object pooling for frequently spawned projectiles/VFX only if profiling shows it is needed

## Component Architecture
Core reusable components:
- HealthComponent
- HurtboxComponent
- HitboxComponent
- TeamComponent
- WeaponComponent
- ProjectileComponent
- TargetingComponent
- GoldDropComponent
- StatusEffectComponent

Gameplay systems:
- RunController
- ArenaController
- WaveDirector
- BuildController
- UpgradeController
- EconomyController
- CameraEffectsController

Actors communicate through signals and small public interfaces. Avoid monolithic player/enemy scripts.

## UI
HUD:
- player HP
- Gold Core HP
- gold currency
- current wave / arena
- dash cooldown
- three build-slot icons with costs
- boss HP bar when active

Menus for vertical slice:
- title/start screen
- pause menu
- upgrade choice overlay
- death/victory screen with restart

## Audio
First slice needs hooks and categories even if final audio assets are not yet available:
- gunshots
- impacts
- gold pickup
- build placement
- explosions
- turret fire
- enemy cues
- boss attacks
- music / ambience buses

## Failure States
Run failure:
- player HP reaches zero, or
- Gold Core HP reaches zero.

On failure, show summary and restart option.

Victory condition for slice:
- defeat Gold Bar Tank and keep Gold Core alive.

## Testing Requirements
The first vertical slice is not considered complete until:
- project opens without parser errors,
- main scene launches,
- player can move, aim, shoot and dash,
- enemies spawn and damage valid targets,
- gold pickups increase currency,
- all three defenses can be placed and function,
- upgrade selection changes run stats,
- Gold Bar Tank encounter can be completed,
- player/core death transitions to failure state,
- victory screen appears after boss death,
- no critical missing-resource errors appear in Godot output.

## Scope Boundary
Included: one playable 5-arena vertical slice, one playable character, 4 normal enemy archetypes, one boss, 3 defenses, run upgrades, HUD, VFX hooks, audio hooks.

Not included in this first slice: online multiplayer, procedural world generation, meta-progression hub, save-game campaign, multiple playable heroes, console/mobile ports, large inventory system.

## Project Location
Keep the project isolated under `gold-rush-roguelike/` so the existing web game files in the repository are not modified by this Godot project.
