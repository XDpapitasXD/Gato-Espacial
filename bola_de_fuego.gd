extends Area2D

var direction: int = 1
const SPEED: float = 250.0 

func _ready() -> void:
	
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	
	global_position.x += SPEED * direction * delta

# Señal cuando algo entra en contacto con la bola de fuego
func _on_body_entered(body: Node2D) -> void:
	
	if body.name == "CharacterBody2D" or body.has_method("recibir_daño"):
		body.recibir_daño()
		
