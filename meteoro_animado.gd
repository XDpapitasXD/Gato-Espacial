extends AnimatedSprite2D

func _ready() -> void:
	# Comprueba si tiene animaciones y reproduce la correspondiente de forma automática
	if sprite_frames:
		if sprite_frames.has_animation("girar"):
			play("girar")
		elif sprite_frames.has_animation("default"):
			play("default")
		else:
			# Si le pusiste otro nombre a tu animación, reproduce la primera que encuentre disponible
			var animaciones = sprite_frames.get_animation_names()
			if animaciones.size() > 0:
				play(animaciones[0])
