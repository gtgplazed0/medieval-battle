extends Node2D
func play_sound(sound):
	for child in get_children():
		if child is AudioStreamPlayer:
			if sound:
				if !child.playing:
					var new_sound = load(sound)
					child.stream = new_sound
					child.play()
					break
