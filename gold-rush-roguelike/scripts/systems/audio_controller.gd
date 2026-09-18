extends Node
class_name AudioController

@onready var music_player: AudioStreamPlayer = $Music
@onready var sfx_player: AudioStreamPlayer = $SFX
@onready var ui_player: AudioStreamPlayer = $UI


func play_music(stream: AudioStream, restart: bool = false) -> void:
	if stream == null:
		return
	if music_player.stream == stream and music_player.playing and not restart:
		return
	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	music_player.stop()


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	sfx_player.play()


func play_ui(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	ui_player.stream = stream
	ui_player.volume_db = volume_db
	ui_player.play()
