extends AudioStreamPlayer

var last_pitch = 1.0

func play2(from_position=0.0):
	pitch_scale = randf_range(0.5, 1.2)
	
	# Ensure the new pitch scale is sufficiently different from the last one
	while abs(pitch_scale - last_pitch) < 0.1:
		pitch_scale = randf_range(0.5, 1.2)
	
	last_pitch = pitch_scale
	pitch_scale = clamp(pitch_scale, 0.5, 1.2)  # Ensure pitch scale is within bounds
	play(from_position)  # Play the audio from the specified position
