extends Node

### dependencies
@export var event_bus: EventBus = EventBus

@export var bg_music_player: AudioStreamPlayer
@export var menu_music_player: AudioStreamPlayer
@export var game_won_music_player: AudioStreamPlayer
@export var game_over_music_player: AudioStreamPlayer

# this represents the entire game state - this is needed to only pause the game and not the entire scene root
@export var game_root_node: Node2D
@onready var hp_bar: HpUiView = $GameHUD/HpBar
@onready var bomb_ui_picker: BombUIPickerView = $GameHUD/BombUiPicker


#region Animation Names
const HIDE_START_GAME_SCREEN: StringName = &"ui_canvas_layer/hide_start_game_screen"
const TOGGLE_PLAYER_HUD: StringName = &"game_hud/toggle_player_hud"
const TOGGLE_CLOCK_HUD: StringName = &"clock_hud/toggle"
const TOGGLE_PAUSE_HUD: StringName = &"pause_hud/toggle"
const TOGGLE_PAUSE_SCREEN: StringName = &"PauseScreen/toggle"
#endregion

@onready var start_game_anim_player: AnimationPlayer = $StartGameScreen/AnimationPlayer
@onready var game_hud_anim_player: AnimationPlayer = $GameHUD/AnimationPlayer
@onready var clock_hud_anim_player: AnimationPlayer = $ClockHUD/AnimationPlayer
@onready var pause_hud_anim_player: AnimationPlayer = $PauseHUD/AnimationPlayer

@onready var play_button: TextureButton = $StartGameScreen/TitleBorder/PlayButton
@onready var play_again_button: TextureButton = $GameOverScreen/Container/PlayAgainButton
@onready var play_again_button2: TextureButton = $GameWonScreen/Container/PlayAgainButton
@onready var play_again_button_audio: AudioStreamPlayer = $PlayAgainButtonAudio
@onready var pause_button: TextureButton = $PauseHUD/PauseButton
@onready var resume_button: TextureButton = $PauseScreen/VBoxContainer/ResumeButton

@onready var game_over_screen: Control = $GameOverScreen
@onready var game_won_screen: Control = $GameWonScreen
@onready var pause_screen: Control = $PauseScreen
@onready var game_over_anim: AnimationPlayer = $GameOverScreen/AnimationPlayer
@onready var game_won_anim: AnimationPlayer = $GameWonScreen/AnimationPlayer
@onready var pause_screen_anim: AnimationPlayer = $PauseScreen/AnimationPlayer


@onready var audio_crossfade_timer: Timer = $audio_crossfade_timer
@onready var clock_hud: ClockHUD = $ClockHUD/Label

func _ready():
	play_button.pressed.connect(on_play_pressed)
	play_again_button.pressed.connect(on_play_again_button_pressed)
	play_again_button2.pressed.connect(on_play_again_button_pressed)
	play_again_button_audio.finished.connect(reset_scene)
	
	resume_button.pressed.connect(on_resume_pressed)
	pause_button.pressed.connect(on_pause_pressed)
	
	event_bus.on_game_end.connect(on_game_end)

func transition_track(outgoing_player: AudioStreamPlayer, incoming_player: AudioStreamPlayer, fade_time: float = 2.0):
	incoming_player.play()
	
	# Crossfade from one music player to the next
	var t = 0.0
	audio_crossfade_timer.start()
	
	# obtains the linear energy of the audio and is used to crossfade b/w 2 tracks
	# this ensures that the audio levels set in the editor are maintained and
	# don't get reset back to their default values
	var linear_energy: float = db_to_linear(outgoing_player.volume_db)
	var other_linear: float = db_to_linear(incoming_player.volume_db)
	
	while t < fade_time:
		outgoing_player.volume_db = linear_to_db((1.0  - t / fade_time) * linear_energy)
		incoming_player.volume_db = linear_to_db((t / fade_time) * other_linear)
		t += audio_crossfade_timer.wait_time
		await audio_crossfade_timer.timeout
		
	# Stop menu music
	outgoing_player.stop()
	audio_crossfade_timer.stop()

func on_play_pressed():
	toggle_start_game_screen()
	toggle_player_hud(false)
	toggle_clock_hud(false)
	toggle_pause_hud(false)
	clock_hud.start_countdown()
	
	event_bus.on_game_start.emit()
	await transition_track(menu_music_player, bg_music_player)

func on_pause_pressed():
	toggle_pause_screen(false)
	toggle_pause_hud(true)
	toggle_clock_hud(true)
	toggle_pause(true)
	
func on_resume_pressed():
	toggle_pause_screen(true)
	toggle_pause_hud(false)
	toggle_clock_hud(false)
	toggle_pause(false)

func on_play_again_button_pressed():
	if !play_again_button_audio.playing:
		play_again_button_audio.play()

func reset_scene():
	get_tree().reload_current_scene()
	
func on_game_end(game_state: String):
	if game_over_screen.visible or game_won_screen.visible:
		return
	
	toggle_player_hud()
	toggle_clock_hud()
	toggle_pause_hud()
	clock_hud.stop_countdown()
	
	# these should be disabled to prevent player from dying or going through different bomb types
	hp_bar.process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
	bomb_ui_picker.process_mode = Node.PROCESS_MODE_DISABLED
	
	if game_state == "GameOver":
		game_over_screen.visible = true
		game_over_anim.play(&"game_over_screen/toggle")
		await transition_track(bg_music_player, game_over_music_player, 0.5)
	else:
		game_won_screen.visible = true
		game_won_anim.play(&"game_won_screen_animations/toggle")
		await transition_track(bg_music_player, game_won_music_player, 0.25)


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

func toggle_clock_hud(is_hidden: bool = true):
	if is_hidden:
		clock_hud_anim_player.play_backwards(TOGGLE_CLOCK_HUD)
	else:
		clock_hud_anim_player.play(TOGGLE_CLOCK_HUD)

func toggle_pause_hud(is_hidden: bool = true):
	if is_hidden:
		pause_hud_anim_player.play(TOGGLE_PAUSE_HUD)
	else:
		pause_hud_anim_player.play_backwards(TOGGLE_PAUSE_HUD)

func toggle_pause_screen(is_hidden: bool = true):
	if is_hidden:
		pause_screen_anim.play(TOGGLE_PAUSE_SCREEN)
	else:
		pause_screen_anim.play_backwards(TOGGLE_PAUSE_SCREEN)

func toggle_pause(is_paused: bool):
	assert(game_root_node != null)
	if is_paused:
		game_root_node.process_mode = Node.PROCESS_MODE_DISABLED
		clock_hud.process_mode = Node.PROCESS_MODE_DISABLED
		hp_bar.process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
		bomb_ui_picker.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		game_root_node.process_mode = Node.PROCESS_MODE_PAUSABLE
		clock_hud.process_mode = Node.PROCESS_MODE_PAUSABLE
		hp_bar.process_mode = Node.ProcessMode.PROCESS_MODE_PAUSABLE
		bomb_ui_picker.process_mode = Node.PROCESS_MODE_PAUSABLE
