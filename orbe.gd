extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if animated_sprite:
		animated_sprite.play("default")

# Función que se ejecuta cuando algo entra en el área del orbe
func _on_body_entered(body: Node2D) -> void:
	print("-> ¡Algo tocó al orbe! Objeto: ", body.name)
	
	# Verifica si es el jugador (por nombre o porque tiene la función curar_daño)
	if body.name == "CharacterBody2D" or body.has_method("curar_daño"):
		print("-> ¡Es el gato! Curando y eliminando orbe.")
		body.curar_daño()
		queue_free() # Destruye el orbe
	else:
		print("-> El objeto que tocó el orbe NO es el gato o no tiene curar_daño.")
