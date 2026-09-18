# Dacha: Last Day — Vertical Slice Design

## Goal
A humorous 2D isometric/top-down roguelike shooter in Godot 4.7.2 combining Survival waves with short Tower Defence build phases.

## Core loop
Move and shoot -> kill enemies -> collect XP/scrap -> choose perks -> every third wave build defenses -> survive the next wave.

## Asset policy
One character = one dedicated character asset/sheet. One weapon, prop or VFX = one dedicated asset. No production gameplay dependencies on concept collages.

## Prototype content
Player: Uncle Vitya. Enemies: psycho chicken, charging boar, ranged neighbor. Defense: potato-style auto turret. Perks: damage, speed, heal.

## Architecture
Gameplay actors are independent Godot scenes. Player and enemies use CharacterBody2D. Bullets and XP use Area2D. The main scene owns waves, build phases, enemy spawning and HUD. Individual scenes own combat/movement behavior.
