extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sonido_rescate: AudioStreamPlayer2D = $SonidoRescate

const VELOCIDAD: float = 35.0
const DISTANCIA_PASITOS: float = 40.0

var posicion_inicial: Vector2
var direccion: int = -1
var esta_caminando: bool = true
var juego_terminado: bool = false

func _ready() -> void:
	posicion_inicial = global_position
	ciclo_comportamiento()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if esta_caminando and not juego_terminado:
		velocity.x = direccion * VELOCIDAD
		animated_sprite.play("caminar")
		animated_sprite.flip_h = (direccion < 0)
		
		var distancia = global_position.x - posicion_inicial.x
		if (direccion == 1 and distancia >= DISTANCIA_PASITOS) or \
		   (direccion == -1 and distancia <= -DISTANCIA_PASITOS) or \
		   is_on_wall():
			direccion *= -1
	else:
		velocity.x = 0
		animated_sprite.play("idle")

	move_and_slide()

func ciclo_comportamiento() -> void:
	while not juego_terminado:
		esta_caminando = true
		await get_tree().create_timer(4.0).timeout
		
		esta_caminando = false
		await get_tree().create_timer(3.0).timeout

func _on_zona_rescate_body_entered(body: Node) -> void:
	if juego_terminado:
		return
		
	if body.name == "CharacterBody2D" or body.has_method("recibir_daño"):
		juego_terminado = true
		print("¡Rescataste a tu amigo gato! Cambiando de escenario...")
		
		# 1. Reproduce el sonido en la raíz global (sobrevive al cambio de escena y se borra solo al terminar)
		if sonido_rescate and sonido_rescate.stream:
			var audio_temp = sonido_rescate.duplicate()
			get_tree().root.add_child(audio_temp)
			audio_temp.global_position = global_position
			audio_temp.play()
			audio_temp.finished.connect(audio_temp.queue_free)
		
		# 2. Pequeña espera súper corta (0.3 segundos) solo para que se sienta el impacto del rescate
		await get_tree().create_timer(0.3).timeout
		
		# 3. Cambia de escena de inmediato
		get_tree().change_scene_to_file("res://pantalla_victoria.tscn")
