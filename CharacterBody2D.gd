extends CharacterBody2D

var impactos_recibidos: int = 0
const SPEED = 200.0
const JUMP_VELOCITY = -400.0

const BOLA_PELOS_SCENE = preload("res://bola_de_pelos_1.tscn")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sonido_salto: AudioStreamPlayer2D = $SonidoSalto
@onready var sonido_maullido: AudioStreamPlayer2D = $SonidoMaullido
@onready var sonido_item: AudioStreamPlayer2D = $SonidoItem
@onready var sonido_daño: AudioStreamPlayer2D = $SonidoDaño
@onready var sonido_reaparicion: AudioStreamPlayer2D = $SonidoReaparicion
@onready var sonido_muerte: AudioStreamPlayer2D = $SonidoMuerte

var puede_disparar: bool = true
const COOLDOWN_TIEMPO: float = 1.5

# Variables de control
var start_position: Vector2
var invulnerable: bool = false
var esta_muriendo: bool = false
var esta_atacando: bool = false
var animando_daño: bool = false 

func _ready() -> void:
	start_position = global_position

# Función auxiliar súper segura para evitar errores de null
func _esperar_seguro(tiempo: float) -> bool:
	var tree = get_tree()
	if tree == null or not is_inside_tree():
		return false
	await tree.create_timer(tiempo).timeout
	return is_inside_tree() and get_tree() != null

func _physics_process(_delta: float) -> void:
	if esta_muriendo:
		return

	if esta_atacando:
		if not is_on_floor():
			velocity += get_gravity() * _delta
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * _delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if sonido_salto and sonido_salto.stream:
			sonido_salto.pitch_scale = randf_range(0.95, 1.08)
			sonido_salto.play()

	if (Input.is_action_just_pressed("ui_focus_next") or Input.is_key_pressed(KEY_E)) and puede_disparar:
		disparar_bola_pelos()
		return

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
		animated_sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if not animando_daño:
		if not is_on_floor():
			animated_sprite.play("jump" if velocity.y < 0 else "fall")
		else:
			animated_sprite.play("walk" if direction != 0 else "idle")

	move_and_slide()

	if global_position.y > 300:
		morir_y_reaparecer("caida")

func disparar_bola_pelos() -> void:
	puede_disparar = false
	esta_atacando = true  
	
	animated_sprite.play("ataque")
	
	if sonido_maullido and sonido_maullido.stream:
		sonido_maullido.pitch_scale = randf_range(0.9, 1.15)
		sonido_maullido.play()
	
	var bola = BOLA_PELOS_SCENE.instantiate()
	var dir = -1 if animated_sprite.flip_h else 1
	bola.global_position = global_position + Vector2(30 * dir, 90)
	bola.scale = Vector2(0.5, 0.5)
	if "direction" in bola:
		bola.direction = dir
	if dir == -1:
		bola.scale.x = -0.5
	
	var tree = get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(bola)
	
	if not await _esperar_seguro(1.0): return
	esta_atacando = false  
	
	var tiempo_restante = COOLDOWN_TIEMPO - 1.0
	if tiempo_restante > 0:
		if not await _esperar_seguro(tiempo_restante): return
		
	puede_disparar = true  

func morir_y_reaparecer(tipo_muerte: String = "caida") -> void:
	if esta_muriendo:
		return
		
	esta_muriendo = true
	esta_atacando = false 
	animando_daño = false
	velocity = Vector2.ZERO 
	
	if tipo_muerte == "caida":
		global_position = start_position
		
		if sonido_reaparicion and sonido_reaparicion.stream:
			sonido_reaparicion.play()
			
		animated_sprite.play("morir-caida")
		await animated_sprite.animation_finished
		
	elif tipo_muerte == "enemigo":
		if sonido_muerte and sonido_muerte.stream:
			sonido_muerte.play()
			
		animated_sprite.play("muerte-enemigo")
		await animated_sprite.animation_finished
		
		global_position = start_position
		
		if sonido_reaparicion and sonido_reaparicion.stream:
			sonido_reaparicion.play()
			
		animated_sprite.play("morir-caida")
		await animated_sprite.animation_finished
	
	impactos_recibidos = 0
	invulnerable = true
	for i in range(10):
		if not is_inside_tree(): return
		animated_sprite.modulate.a = 0.3  
		if not await _esperar_seguro(0.1): return
		animated_sprite.modulate.a = 1.0  
		if not await _esperar_seguro(0.1): return
		
	invulnerable = false
	esta_muriendo = false

func recibir_daño() -> void:
	if invulnerable or esta_muriendo:
		return
		
	impactos_recibidos += 1
	print("¡Golpes recibidos: ", impactos_recibidos, " / 3!")
	
	if sonido_daño and sonido_daño.stream:
		sonido_daño.pitch_scale = randf_range(0.95, 1.05)
		sonido_daño.play()
	
	animando_daño = true
	animated_sprite.play("daño-enemigo")
	
	invulnerable = true
	if not await _esperar_seguro(0.4): return
	animando_daño = false 
	
	for i in range(3):
		if not is_inside_tree(): return
		animated_sprite.modulate.a = 0.3
		if not await _esperar_seguro(0.08): return
		animated_sprite.modulate.a = 1.0
		if not await _esperar_seguro(0.08): return
	invulnerable = false
	
	if impactos_recibidos >= 3:
		morir_y_reaparecer("enemigo")

func recibir_daño_espacio() -> void:
	if invulnerable or esta_muriendo:
		return
		
	impactos_recibidos += 1
	print("¡Daño por entorno espacial! Golpes: ", impactos_recibidos, " / 3!")
	
	if sonido_daño and sonido_daño.stream:
		sonido_daño.pitch_scale = randf_range(0.95, 1.05)
		sonido_daño.play()
	
	animando_daño = true
	animated_sprite.play("daño-espacio")
	
	invulnerable = true
	if not await _esperar_seguro(0.4): return
	animando_daño = false
	
	for i in range(3):
		if not is_inside_tree(): return
		animated_sprite.modulate.a = 0.3
		if not await _esperar_seguro(0.08): return
		animated_sprite.modulate.a = 1.0
		if not await _esperar_seguro(0.08): return
	invulnerable = false
	
	if impactos_recibidos >= 3:
		morir_y_reaparecer("enemigo")

func curar_daño() -> void:
	if sonido_item and sonido_item.stream:
		sonido_item.pitch_scale = randf_range(0.95, 1.1)
		sonido_item.play()

	if impactos_recibidos > 0:
		impactos_recibidos -= 1
		print("¡Vida recuperada con orbe! Golpes actuales: ", impactos_recibidos, " / 3")
		
		for i in range(3):
			if not is_inside_tree(): return
			animated_sprite.modulate = Color(0, 1, 0)
			if not await _esperar_seguro(0.08): return
			animated_sprite.modulate = Color(1, 1, 1)
			if not await _esperar_seguro(0.08): return
