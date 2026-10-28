class_name AudioLatencyProbe
extends Node

## Debug builds only: logs the audio output latency at startup and with every sound played,
## to read with `adb logcat -s godot`. Removed with the other debug tools in step 3.1.

const MILLISECONDS_PER_SECOND: float = 1000.0


func _ready() -> void:
	print("Audio driver: %s, mix rate %d Hz, output latency %.1f ms" % [
		AudioServer.get_driver_name(), AudioServer.get_mix_rate(), AudioServer.get_output_latency() * MILLISECONDS_PER_SECOND
	])
	AudioManager.effect_played.connect(_on_effect_played)


## The sound is heard about output latency + time to next mix after the frame that started it.
func _on_effect_played(effect: SoundEffect) -> void:
	print("Audio latency: output=%.1fms next_mix=%.1fms frame=%d sound=%s" % [
		AudioServer.get_output_latency() * MILLISECONDS_PER_SECOND,
		AudioServer.get_time_to_next_mix() * MILLISECONDS_PER_SECOND,
		Engine.get_process_frames(),
		effect.stream.resource_path.get_file(),
	])
