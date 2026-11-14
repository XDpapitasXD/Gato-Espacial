extends Control

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://tu_escena_principal.tscn") # Pon aquí la ruta exacta de tu nivel
