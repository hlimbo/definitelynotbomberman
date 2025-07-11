extends AudioStreamPlayer

# measured in seconds AND you must know when it starts and ends for it to loop smoothly....
# takes a lot of trial and error especially if you didn't make the music yourself.....
@export var loop_start: float = 1.18
@export var loop_end: float = 12.0
@export var end_tolerance: float = 0.01


# Lessons Learned: 
# this can theoretically loop the music however it is pretty choppy as you need the EXACT STARTING AND STOPPING POINTS....
# will it loop smoothly?
func _process(delta: float):
	var playback_position_seconds: float = self.get_playback_position()
	var is_within_range: bool = playback_position_seconds > loop_end - end_tolerance and playback_position_seconds <  loop_end + end_tolerance
	if self.is_playing() and is_within_range:
		self.play(loop_start)
