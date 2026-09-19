# Gold Rush Roguelike — Visual Overhaul Design Spec

## Status
Approved direction: **2.5D redraw + selective Tripo 3D**, preserving the existing playable Godot 4.7.2 vertical slice and its gameplay architecture.

This spec extends `2026-09-19-gold-rush-roguelike-design.md`. It does not replace the existing gameplay, economy, wave, arena, build, upgrade, depth-sort, boss, or CI contracts unless a visual requirement explicitly needs a presentation-layer change.

## Goal
Raise the project from functional prototype visuals to a cohesive, production-style 2.5D isometric western presentation where:

- the Prospector, enemies, defenses and boss read clearly at gameplay zoom;
- locations feel authored, layered and atmospheric rather than flat or assembled from unrelated pieces;
- animation has visible weight, anticipation and follow-through;
- combat VFX make hits, shots, deaths, pickups and boss attacks readable without hiding gameplay;
- HUD presentation matches the world art instead of looking like a separate debug layer;
- visual quality remains stable under the existing five-arena run and Windows export pipeline.

## Chosen Approach
Use a **hybrid 2.5D pipeline** rather than converting the game to runtime 3D.

### Runtime
Gameplay remains in Godot's 2D pipeline using the current top-down / pseudo-isometric camera, collision, Y-sorting and scene structure.

### High-detail source creation
Use Tripo 3D selectively for source geometry where consistent volume helps:

- Prospector body / equipment blockout if useful;
- major defense silhouettes;
- mining machinery;
- mine-cart / rail props;
- large rock formations;
- boss hard-surface reference;
- reusable environment hero props.

These 3D assets are **source art**, not a mandatory runtime dependency for the first overhaul pass. They should be rendered or traced into clean transparent 2D sprites / sprite sequences from a locked isometric camera so the current gameplay architecture does not need to become a 3D game.

### 2D paint-over / redraw
Final gameplay assets should use a unified illustrated 2.5D look with:

- crisp silhouettes;
- controlled dark outlines instead of heavy cartoon borders everywhere;
- warm sandstone / ochre / rust palette;
- saturated gold and cyan energy accents;
- painted form shadows and rim highlights;
- consistent light direction;
- soft contact shadows;
- transparent margins with no rectangular cutout artifacts;
- enough internal detail to remain readable at target render size.

## Art Bible
### Camera and projection
All character, enemy, defense and major prop art must respect the same pseudo-isometric view.

Target presentation:
- three-quarter top-down view;
- visible front and side planes;
- ground footprint aligned consistently;
- no asset may look front-on while neighboring assets look top-down;
- sprite pivots sit at the actor's ground-contact point.

### Light direction
Primary warm key light comes from upper-left / north-west screen direction. Cyan energy objects can add a secondary local light. Fire / molten gold adds warm orange local light.

### Material language
- Sandstone: matte, layered warm beige to orange.
- Timber: dry dark brown with warm edge highlights.
- Metal: dark desaturated steel with selective bright edge accents.
- Gold enemies: rich yellow-gold midtone, orange shadow, pale hot highlight, darker creases.
- Energy technology: cyan / turquoise emissive accents.
- Boss / danger telegraphs: orange-red with white-hot centers.

### Detail hierarchy
At gameplay zoom:
- silhouette first;
- face / weapon / attack direction second;
- costume or mechanical detail third;
- micro texture last.

No asset should gain detail at the cost of combat readability.

## Character Overhaul
### Prospector
The Prospector becomes the visual quality benchmark for all actor work.

Required states:
- idle;
- locomotion / run;
- aim facing support;
- primary fire recoil;
- dash;
- hit reaction;
- death / defeat.

Presentation goals:
- readable hat / head silhouette;
- clear torso, arms and legs rather than merged shapes;
- weapon visually separated from body;
- coat / scarf / gear movement used for secondary motion;
- footsteps generate restrained dust;
- muzzle flash and recoil sync tightly to projectile spawn;
- hit reaction does not interrupt controls longer than the gameplay state requires.

### Animation quality target
Animation can use frame sequences, bone-like transforms, AnimationPlayer, or a hybrid, but must avoid the current 'single cutout wobble' look.

Minimum animation principles:
- idle breathing / weight shift;
- run cycle with alternating legs and vertical body compression;
- fire anticipation + recoil + settle;
- dash stretch / lean with dust trail;
- hit flash plus directional body impulse;
- death with a clear fall / collapse silhouette.

## Enemy Overhaul
All normal enemies must share the same rendering quality but keep distinct silhouettes.

### GoldHopper
- compact nugget creature;
- strong squash / stretch on hop;
- visible wind-up before lunge;
- dust / gold chip impact on landing.

### GoldCoinSentinel
- stacked / plated coin-machine silhouette;
- ranged weapon or emitter clearly visible;
- attack telegraph separates anticipation from shot release;
- rotating or tilting mechanical elements provide life between attacks.

### FlyingGoldDisc
- cleaner saucer / disc volume;
- visible altitude shadow separated from sprite;
- banking motion while changing direction;
- short energy trail / spark accent while attacking.

### MoltenGoldSlime
- semi-fluid silhouette with brighter core;
- body deformation while moving;
- trailing molten drips / puddle feedback;
- emissive warm light kept below boss-level intensity.

### GoldBarTank
Boss remains the largest silhouette and receives the most layered detail.

Requirements:
- clearly readable armored gold-bar construction;
- cyan internal tech / energy contrast;
- phase-change presentation;
- charge telegraph, laser, slam and add-spawn each have distinct anticipation and impact language;
- mechanical movement, recoil and hit response should sell mass.

## Defense Overhaul
### MagneticTurret
- unmistakable rotating weapon head;
- cyan magnetic coil / energy chamber;
- target tracking visible in animation;
- firing pulse synchronized with shot.

### CactusSentry
- western/comedic cactus silhouette;
- planted base reads as part of the ground;
- recoil / arm or barrel movement when firing;
- muzzle flash and tiny thorn / dust accents.

### TNTBarrel
- classic western TNT readability without relying on text alone;
- fuse / danger pulse;
- pre-explosion anticipation;
- explosion combines flash, fire, smoke, dust and debris in controlled layers.

## Arena01 — Visual Benchmark
Arena01 is rebuilt first and becomes the reference scene for the remaining arenas.

### Ground
Replace flat-feeling ground presentation with layered painted terrain:
- large warm sand value variation;
- worn paths / compacted dirt;
- subtle rock strata;
- darker contact zones beneath structures;
- no obvious tiling or repeated texture pattern at normal camera scale.

### Perimeter
Use layered canyon / mine boundaries with:
- foreground and background rock tiers;
- mine supports;
- broken fences;
- rails / carts;
- crates / barrels;
- sparse desert plants;
- gold seams used as accent, not wallpaper.

### Composition
The arena must preserve combat visibility.

Rules:
- playfield center remains readable;
- high-detail props live mostly near edges or landmarks;
- tall props cannot hide player, enemies or defense placement for long;
- navigable and non-navigable regions remain visually obvious;
- Gold Core must stand out from environment values.

### Atmosphere
Arena01 adds:
- low-density drifting dust;
- occasional tiny wind streak / sand particle;
- localized cyan Gold Core glow;
- restrained warm rim / bounce lighting near western props;
- impact dust where actors move or hit ground.

No full-screen effect should reduce aiming clarity.

## Remaining Arena Identity
Once Arena01 passes the visual benchmark, apply the same quality bar with different identities:

- Arena02: mining yard / industrial defense unlock space;
- Arena03: rail and explosives arena with denser obstacle rhythm;
- Arena04: harsher elite canyon / extraction site;
- Arena05: boss foundry / molten-gold stronghold.

The five arenas should feel related, not copied. Shared prop kits are allowed, but each arena needs a distinct landmark and atmosphere accent.

## VFX Overhaul
### Player weapon
- bright compact muzzle flash;
- readable projectile / tracer core;
- optional short local light on high-value shots only;
- impact spark + dust / chip response based on target class.

### Enemy hits
- directional hit flash;
- small gold chips / sparks;
- brief controlled impact burst;
- stronger effects on critical or heavy hits.

### Deaths
Normal enemy death combines:
- silhouette breakup or collapse;
- gold fragments;
- dust / smoke accent;
- drop spawn readability;
- no giant explosion for weak enemies.

### Pickups
Gold pickup uses:
- clean gem / nugget silhouette;
- glow and bob;
- short attraction / collect trail if technically cheap;
- collection burst and HUD currency pulse.

### Heavy impacts
Boss slam, TNT and major attacks may use:
- short screen shake;
- expanding dust ring;
- flash / light burst;
- debris;
- brief ground mark if it does not create cleanup problems.

## HUD / UI Direction
Use Figma selectively to define a consistent visual system for HUD and menus.

HUD goals:
- dark western metal / leather-inspired panel shapes;
- gold trim used sparingly for currency / important rewards;
- cyan reserved for friendly energy / Core tech;
- boss danger and damage use orange-red;
- maintain current information hierarchy and screen-space efficiency.

Required polish:
- player HP and Core HP become visually distinct;
- build slots have clear icon silhouettes and active / cooldown states;
- gold collection produces restrained feedback;
- boss bar has phase / danger readability;
- upgrade cards visually match world art.

## Figma Role
Figma is a design/reference tool, not a hard runtime dependency.

Use it for:
- palette board;
- HUD component reference;
- icon construction guides;
- spacing / typography decisions;
- before/after visual review boards when useful.

Game assets remain stored in the repository and imported by Godot.

## Asset Technical Standards
### Source and export
- Keep editable high-resolution source assets separate from runtime exports where practical.
- Runtime sprites use transparent backgrounds.
- Avoid lossy repeated re-encoding during iteration.
- Texture sizes should be power-of-two only where it materially helps; do not inflate assets without visible benefit.
- Preserve a consistent pixels-per-world-unit relationship per actor class.

### Pivot / margins
- Actor pivot: ground contact point.
- Flying actor pivot: projected ground center, with visual sprite offset above it.
- Consistent transparent padding across animation frames.
- No frame may crop weapons, hats, effects or feet.

### Animation atlases
- Frames in a sequence share identical canvas size.
- Stable anchor point across all frames.
- Naming clearly identifies actor, state, direction and frame order.

## Scene Integration Rules
- Replace visuals without changing gameplay collision shapes unless a mismatch is proven.
- Presentation nodes may be added below actor scenes without changing public gameplay interfaces.
- Y-sort and z-index rules from the current GREEN build remain authoritative.
- Runtime local lights are reserved for meaningful emissive elements and short bursts; do not attach expensive lights to every particle.
- VFX must self-clean and never leak nodes between waves.

## Performance Budget
Target smooth play on the current Windows desktop baseline while preserving CI/headless compatibility.

Guidelines:
- avoid dozens of simultaneous PointLight2D nodes from projectiles;
- cap persistent ambient particles;
- prefer sprite / polygon glow where a dynamic light adds little;
- atlas repeated small effects where useful;
- disable off-screen cosmetic processing if it becomes measurable.

No optimization should visibly degrade the hero, boss or primary combat feedback unless profiling shows it is necessary.

## Quality Gates
A visual block is accepted only when all of the following are true:

1. Existing functional tests remain GREEN.
2. No parser, missing-resource or invalid-node errors are introduced.
3. Gameplay preview shows no visible rectangular cutout artifacts.
4. Prospector / enemy / defense silhouettes are readable at normal gameplay zoom.
5. No required animation frame is cropped or anchor-shifted.
6. Arena props do not cover critical actors for sustained periods.
7. VFX are synchronized to the gameplay event they represent.
8. Effects self-clean after completion.
9. Boss telegraphs remain more readable, not less readable, after art replacement.
10. Windows export succeeds.

## Visual QA Captures
Maintain automated captures and extend them when needed.

Required benchmark images:
- Arena01 normal gameplay composition;
- dense mixed-enemy combat;
- defense-heavy combat;
- Gold pickup / collection moment;
- boss charge / laser telegraph;
- boss slam / heavy impact;
- upgrade UI;
- victory / defeat overlay.

These captures are compared manually for composition, clarity and art consistency in addition to automated contract tests.

## Implementation Order
### Pass 1 — Quality benchmark
1. Prospector redesign and animation presentation.
2. All normal enemy redraws / animation presentation.
3. Three defense redesigns.
4. Arena01 environment rebuild.
5. Core combat VFX pass.
6. HUD alignment pass for the benchmark screenshot.

### Pass 2 — World consistency
1. Arena02–Arena04 environment identity.
2. Arena05 boss environment.
3. Boss art / animation refinement.
4. Remaining environment props and atmospheric systems.

### Pass 3 — Final polish
1. Hit / death / pickup timing polish.
2. Animation timing consistency.
3. UI transitions / upgrade cards.
4. Sound trigger alignment where assets exist.
5. Balance/readability regression.
6. Fresh gameplay and boss captures.
7. Fresh Windows release-candidate export.

## Non-Goals
This overhaul does **not**:
- convert the entire project to runtime 3D;
- replace the current gameplay systems;
- redesign the economy or five-arena progression unless visual QA reveals a readability blocker;
- add multiplayer;
- add a new playable hero;
- introduce a dependency on Figma or Tripo at runtime.

## Definition of Done
The visual overhaul is considered release-candidate-ready when:

- the game presents one coherent art direction across player, enemies, defenses, environment, VFX and HUD;
- Arena01 no longer reads as flat prototype composition;
- all five arenas have distinct but related identities;
- actor animations communicate movement and attacks clearly;
- combat feedback is readable in dense waves;
- boss telegraphs remain unmistakable;
- screenshots no longer contain obvious crude placeholder-like forms or mismatched art styles;
- the full CI pipeline and Windows export are GREEN on the final commit.