extends CanvasLayer
class_name GoldRushHUD

var _player: Prospector
var _core: GoldCore
var _economy: EconomyController
var _build_controller: BuildController
var _boss_health: HealthComponent

@onready var player_hp: ProgressBar = $Root/TopLeft/PlayerHP
@onready var core_hp: ProgressBar = $Root/TopLeft/CoreHP
@onready var gold_label: Label = $Root/TopLeft/Gold
@onready var arena_label: Label = $Root/TopCenter/Arena
@onready var wave_label: Label = $Root/TopCenter/Wave
@onready var dash_bar: ProgressBar = $Root/BottomLeft/Dash
@onready var build_labels: Array[Label] = [
	$Root/BottomCenter/Slots/Slot1,
	$Root/BottomCenter/Slots/Slot2,
	$Root/BottomCenter/Slots/Slot3,
]
@onready var boss_panel: Control = $Root/BossPanel
@onready var boss_bar: ProgressBar = $Root/BossPanel/VBox/BossHP


func _ready() -> void:
	boss_panel.visible = false


func bind_player(player: Prospector) -> void:
	_player = player
	if player == null:
		return
	player.health_component.health_changed.connect(_on_player_health_changed)
	player.dash_cooldown_changed.connect(_on_dash_cooldown_changed)
	_on_player_health_changed(player.health_component.current_health, player.health_component.max_health)
	_on_dash_cooldown_changed(player.get_dash_cooldown_remaining(), player.get_dash_cooldown_maximum())


func bind_core(core: GoldCore) -> void:
	_core = core
	if core == null:
		return
	core.health_component.health_changed.connect(_on_core_health_changed)
	_on_core_health_changed(core.health_component.current_health, core.health_component.max_health)


func bind_economy(economy: EconomyController) -> void:
	_economy = economy
	if economy == null:
		return
	economy.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(economy.gold)


func bind_build_controller(build_controller: BuildController) -> void:
	_build_controller = build_controller
	if build_controller == null:
		return
	build_controller.defense_unlocked.connect(_on_defense_unlock_changed)
	build_controller.selection_changed.connect(_on_build_selection_changed)
	_refresh_build_slots()


func set_arena(index: int) -> void:
	arena_label.text = "ARENA %d / 5" % index


func set_wave(number: int) -> void:
	wave_label.text = "WAVE %d" % number


func show_boss(health_component: HealthComponent) -> void:
	if _boss_health != null and _boss_health.health_changed.is_connected(_on_boss_health_changed):
		_boss_health.health_changed.disconnect(_on_boss_health_changed)
	_boss_health = health_component
	boss_panel.visible = health_component != null
	if health_component == null:
		return
	health_component.health_changed.connect(_on_boss_health_changed)
	_on_boss_health_changed(health_component.current_health, health_component.max_health)


func _on_player_health_changed(current: float, maximum: float) -> void:
	player_hp.max_value = maximum
	player_hp.value = current
	player_hp.tooltip_text = "Prospector %.0f / %.0f" % [current, maximum]


func _on_core_health_changed(current: float, maximum: float) -> void:
	core_hp.max_value = maximum
	core_hp.value = current
	core_hp.tooltip_text = "Gold Core %.0f / %.0f" % [current, maximum]


func _on_gold_changed(total: int) -> void:
	gold_label.text = "GOLD  %d" % total


func _on_dash_cooldown_changed(remaining: float, maximum: float) -> void:
	dash_bar.max_value = maxf(maximum, 0.001)
	dash_bar.value = maxf(maximum - remaining, 0.0)


func _on_boss_health_changed(current: float, maximum: float) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current


func _on_defense_unlock_changed(_slot: int) -> void:
	_refresh_build_slots()


func _on_build_selection_changed(_slot: int) -> void:
	_refresh_build_slots()


func _refresh_build_slots() -> void:
	if _build_controller == null:
		return
	var names := ["MAGNETIC", "CACTUS", "TNT"]
	var costs := [45, 28, 20]
	for index in range(build_labels.size()):
		var slot := index + 1
		var unlocked := _build_controller.is_unlocked(slot)
		var prefix := "> " if _build_controller.selected_slot == slot else ""
		build_labels[index].text = "%s%d  %s  $%d" % [prefix, slot, names[index], costs[index]] if unlocked else "%d  LOCKED" % slot
