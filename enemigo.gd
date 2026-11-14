extends CharacterBody2D

const BOLA_FUEGO_SCENE = preload("res://bola_de_fuego.tscn")
const ORBE_SCENE = preload("res://orbe.tscn")

var direccion: int = 1
var velocidad: float = 40.0

# Variables para limitar el recorrido y evitar que se caiga
var posicion_inicial: Vector2
const DISTANCIA_MAXIMA: float = 25.0 # Píxeles que camina hacia cada lado

@onready var animated_sprite: AnimatedSprite2D = $Alieen1
@onready var sonido_disparo: AudioStreamPlayer2D = $SonidoDisparo
@onready var sonido_muerte: AudioStreamPlayer2D = $SonidoMuerte

func _ready() -> void:
	posicion_inicial = global_position # Guarda el punto exacto donde nace el alien
	bucle_disparo()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	velocity.x = direccion * velocidad
	move_and_slide()

	# Animación de caminar
	var anim_a_reproducir = "caminar"
	if not animated_sprite.sprite_frames.has_animation(anim_a_reproducir):
		anim_a_reproducir = "default"
		
	if animated_sprite.animation != anim_a_reproducir:
		animated_sprite.play(anim_a_reproducir)

	# Control de giro por distancia máxima o choque con pared
	var distancia_recorrida = global_position.x - posicion_inicial.x
	
	if (direccion == 1 and distancia_recorrida >= DISTANCIA_MAXIMA) or \
	   (direccion == -1 and distancia_recorrida <= -DISTANCIA_MAXIMA) or \
	   is_on_wall():
		direccion *= -1
		
	animated_sprite.flip_h = (direccion > 0)

func bucle_disparo() -> void:
	while true:
		var tiempo_espera = randf_range(2.0, 4.0)
		await get_tree().create_timer(tiempo_espera).timeout
		disparar()

func disparar() -> void:
	if sonido_disparo and sonido_disparo.stream:
		sonido_disparo.pitch_scale = randf_range(0.9, 1.1)
		sonido_disparo.play()

	var fuego = BOLA_FUEGO_SCENE.instantiate()
	fuego.global_position = global_position + Vector2(-10 * direccion, 90)
	
	if "direction" in fuego:
		fuego.direction = direccion
		
	get_tree().current_scene.add_child(fuego)

# ==========================================
# SEÑALES DE COMBATE SEGURAS
# ==========================================

func _on_hitbox_body_entered(body: Node) -> void:
	if body.has_method("recibir_daño"):
		body.recibir_daño()

func _on_hitbox_area_entered(_area: Area2D) -> void:
	# Delegamos la creación del orbe y borrado a una función diferida 
	# para evitar completamente el error de "flushing queries"
	call_deferred("_morir_y_soltar_orbe", _area)

func _morir_y_soltar_orbe(_area: Area2D) -> void:
	# 1. Reproduce y "rescata" el sonido de muerte para que no se corte
	if sonido_muerte and sonido_muerte.stream:
		var audio_temp = sonido_muerte.duplicate()
		get_tree().current_scene.add_child(audio_temp)
		audio_temp.global_position = global_position
		audio_temp.pitch_scale = randf_range(0.95, 1.05)
		audio_temp.play()
		# Se autodestruye al terminar de sonar para no gastar memoria
		audio_temp.finished.connect(audio_temp.queue_free)

	# 2. Instancia y coloca el orbe en el mapa de forma segura
	var orbe = ORBE_SCENE.instantiate()
	orbe.global_position = global_position + Vector2(0, 110)
	get_tree().current_scene.add_child(orbe)
	
	# 3. Destruye la bola de pelos
	if is_instance_valid(_area):
		_area.queue_free()
		
	# 4. Destruye al enemigo
	queue_free()
