extends CharacterBody2D

var impactos_recibidos: int = 0
const SPEED = 200.0
const JUMP_VELOCITY = -400.0

const BOLA_PELOS_SCENE = preload("res://bola_de_pelos_1.tscn")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var puede_disparar: bool = true
const COOLDOWN_TIEMPO: float = 1.5

# Variables de control
var start_position: Vector2
var invulnerable: bool = false
var esta_muriendo: bool = false
var esta_atacando: bool = false
var animando_daño: bool = false # Permite que la animación de daño se vea sin congelar el movimiento

func _ready() -> void:
	start_position = global_position

func _physics_process(delta: float) -> void:
	# SI ESTÁ MURIENDO: Bloquea todo por completo
	if esta_muriendo:
		return

	# SI ESTÁ ATACANDO: Frena el movimiento únicamente al disparar
	if esta_atacando:
		if not is_on_floor():
			velocity += get_gravity() * delta
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	# 1. Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Disparar bola de pelo
	if (Input.is_action_just_pressed("ui_focus_next") or Input.is_key_pressed(KEY_E)) and puede_disparar:
		disparar_bola_pelos()
		return

	# 4. Movimiento horizontal (¡Libre en todo momento!)
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
		animated_sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 5. Animaciones normales (Solo se ejecutan si NO está reproduciéndose la animación de daño)
	if not animando_daño:
		if not is_on_floor():
			animated_sprite.play("jump" if velocity.y < 0 else "fall")
		else:
			animated_sprite.play("walk" if direction != 0 else "idle")

	move_and_slide()

	# 6. DETECCIÓN DE CAÍDA AL VACÍO
	if global_position.y > 300:
		morir_y_reaparecer("caida")

func disparar_bola_pelos() -> void:
	puede_disparar = false
	esta_atacando = true  
	
	animated_sprite.play("ataque")
	
	var bola = BOLA_PELOS_SCENE.instantiate()
	var dir = -1 if animated_sprite.flip_h else 1
	bola.global_position = global_position + Vector2(30 * dir, 90)
	bola.scale = Vector2(0.5, 0.5)
	if "direction" in bola:
		bola.direction = dir
	if dir == -1:
		bola.scale.x = -0.5
	get_tree().current_scene.add_child(bola)
	
	await get_tree().create_timer(1.0).timeout
	esta_atacando = false  
	
	var tiempo_restante = COOLDOWN_TIEMPO - 1.0
	if tiempo_restante > 0:
		await get_tree().create_timer(tiempo_restante).timeout
		
	puede_disparar = true  

# Función de reaparición inteligente según el tipo de muerte
func morir_y_reaparecer(tipo_muerte: String = "caida") -> void:
	if esta_muriendo:
		return
		
	esta_muriendo = true
	esta_atacando = false 
	animando_daño = false
	velocity = Vector2.ZERO 
	
	if tipo_muerte == "caida":
		global_position = start_position
		animated_sprite.play("morir-caida")
		await animated_sprite.animation_finished
		
	elif tipo_muerte == "enemigo":
		animated_sprite.play("muerte-enemigo")
		await animated_sprite.animation_finished
		
		global_position = start_position
		animated_sprite.play("morir-caida")
		await animated_sprite.animation_finished
	
	impactos_recibidos = 0
	invulnerable = true
	for i in range(10):
		animated_sprite.modulate.a = 0.3  
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate.a = 1.0  
		await get_tree().create_timer(0.1).timeout
		
	invulnerable = false
	esta_muriendo = false

# Daño por contacto físico o bola de fuego del enemigo
func recibir_daño() -> void:
	if invulnerable or esta_muriendo:
		return
		
	impactos_recibidos += 1
	print("¡Golpes recibidos: ", impactos_recibidos, " / 3!")
	
	animando_daño = true
	animated_sprite.play("daño-enemigo")
	
	invulnerable = true
	await get_tree().create_timer(0.4).timeout
	animando_daño = false 
	
	for i in range(3):
		animated_sprite.modulate.a = 0.3
		await get_tree().create_timer(0.08).timeout
		animated_sprite.modulate.a = 1.0
		await get_tree().create_timer(0.08).timeout
	invulnerable = false
	
	if impactos_recibidos >= 3:
		morir_y_reaparecer("enemigo")

# Daño ambiental por el entorno del espacio (activado por la interfaz cada 15 segundos)
func recibir_daño_espacio() -> void:
	if invulnerable or esta_muriendo:
		return
		
	impactos_recibidos += 1
	print("¡Daño por entorno espacial! Golpes: ", impactos_recibidos, " / 3!")
	
	animando_daño = true
	animated_sprite.play("daño-espacio")
	
	invulnerable = true
	await get_tree().create_timer(0.4).timeout
	animando_daño = false
	
	for i in range(3):
		animated_sprite.modulate.a = 0.3
		await get_tree().create_timer(0.08).timeout
		animated_sprite.modulate.a = 1.0
		await get_tree().create_timer(0.08).timeout
	invulnerable = false
	
	if impactos_recibidos >= 3:
		morir_y_reaparecer("enemigo")

# Función para curar al gato cuando recoge un orbe
func curar_daño() -> void:
	if impactos_recibidos > 0:
		impactos_recibidos -= 1
		print("¡Vida recuperada con orbe! Golpes actuales: ", impactos_recibidos, " / 3")
		
		for i in range(3):
			animated_sprite.modulate = Color(0, 1, 0)
			await get_tree().create_timer(0.08).timeout
			animated_sprite.modulate = Color(1, 1, 1)
			await get_tree().create_timer(0.08).timeout
