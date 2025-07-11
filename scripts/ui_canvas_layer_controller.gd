extends Node

### dependencies
@export var event_bus: EventBus = EventBus

@export var game_scene: PackedScene

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

func _ready():
	play_button.pressed.connect(on_play_pressed)
	play_again_button.pressed.connect(reset_scene)
	play_again_button2.pressed.connect(reset_scene)
	
	event_bus.on_game_end.connect(on_game_end)

func on_play_pressed():
	toggle_start_game_screen()
	toggle_player_hud(false)

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
	
