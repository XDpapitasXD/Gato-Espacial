extends Area2D

const SPEED = 200.0
var direction = 1    # 1 para derecha, -1 para izquierda

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Reproduce la animación por defecto
	animated_sprite.play("default")
	
	# Seguridad: se destruye a los 3 segundos si no choca con nada
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Mueve la bola de pelos horizontalmente
	position.x += direction * SPEED * delta

# Esta función se ejecuta automáticamente al chocar con un muro, piso o TileMap
func _on_body_entered(body: Node2D) -> void:
	# Si choca con cualquier cosa que NO sea el propio jugador, desaparece
	if body.name != "CharacterBody2D":
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
