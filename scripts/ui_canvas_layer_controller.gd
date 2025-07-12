extends Node

### dependencies
@export var event_bus: EventBus = EventBus

@export var bg_music_player: AudioStreamPlayer
@export var menu_music_player: AudioStreamPlayer


#region Animation Names
const HIDE_START_GAME_SCREEN: StringName = &"ui_canvas_layer/hide_start_game_screen"
const TOGGLE_PLAYER_HUD: StringName = &"game_hud/toggle_player_hud"
#endregion

@onready var start_game_anim_player: AnimationPlayer = $StartGameScreen/AnimationPlayer
@onready var game_hud_anim_player: AnimationPlayer = $GameHUD/AnimationPlayer
@onready var play_button: TextureButton = $StartGameScreen/TitleBorder/PlayButton
@onready var play_again_button: TextureButton = $GameOverScreen/PlayAgainButton
@onready var play_again_button2: TextureButton = $GameWonScreen/PlayAgainButton

@onready var game_over_screen: Control = $GameOverScreen
@onready var game_won_screen: Control = $GameWonScreen

@onready var audio_crossfade_timer: Timer = $audio_crossfade_timer


func _ready():
	play_button.pressed.connect(on_play_pressed)
	play_again_button.pressed.connect(reset_scene)
	play_again_button2.pressed.connect(reset_scene)
	
	event_bus.on_game_end.connect(on_game_end)

func transition_track():
	bg_music_player.play()
	
	# Crossfade from menu music to game music
	var fade_time = 2.0  # seconds
	var t = 0.0
	audio_crossfade_timer.start()
	
	# obtains the linear energy of the audio and is used to crossfade b/w 2 tracks
	# this ensures that the audio levels set in the editor are maintained and
	# don't get reset back to their default values
	var linear_energy: float = db_to_linear(menu_music_player.volume_db)
	var other_linear: float = db_to_linear(bg_music_player.volume_db)
	
	while t < fade_time:
		menu_music_player.volume_db = linear_to_db(linear_energy - t / fade_time)
		bg_music_player.volume_db = linear_to_db((t / fade_time) * other_linear)
		t += audio_crossfade_timer.wait_time
		await audio_crossfade_timer.timeout
		
	# Stop menu music
	menu_music_player.stop()
	audio_crossfade_timer.stop()

func on_play_pressed():
	toggle_start_game_screen()
	toggle_player_hud(false)
	await transition_track()
	#menu_music_player.stop()
	#bg_music_player.play()

func reset_scene():
	get_tree().reload_current_scene()
	# get_tree().change_scene_to_packed(game_scene)

func on_game_end(game_state: String):
	toggle_player_hud()
	if game_state == "GameOver":
		game_over_screen.visible = true
	else:
		game_won_screen.visible = true

func toggle_start_game_screen(is_hidden: bool = true):
	if is_hidden:
		start_game_anim_player.play(HIDE_START_GAME_SCREEN)
	else:
		start_game_anim_player.play_backwards(HIDE_START_GAME_SCREEN)
	
func toggle_player_hud(is_hidden: bool = true):
	if is_hidden:
		game_hud_anim_player.play(TOGGLE_PLAYER_HUD)
	else:
		game_hud_anim_player.play_backwards(TOGGLE_PLAYER_HUD)
	
