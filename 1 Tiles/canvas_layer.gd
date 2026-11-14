extends CanvasLayer

@onready var label_tiempo: Label = $Label
@onready var timer_espacio: Timer = $Timer
@onready var gato: CharacterBody2D = get_node("../CharacterBody2D") 

@onready var corazones: Array[AnimatedSprite2D] = [
	$Corazon1,
	$Corazon2,
	$Corazon3
]

var vidas_anteriores: int = 3

func _ready() -> void:
	timer_espacio.wait_time = 15.0
	timer_espacio.one_shot = false 
	timer_espacio.start()
	
	var estilo_espacial = LabelSettings.new()
	estilo_espacial.font_size = 28
	estilo_espacial.font_color = Color(0.0, 1.0, 0.8)
	estilo_espacial.outline_size = 4
	estilo_espacial.outline_color = Color(0.0, 0.0, 0.0)
	label_tiempo.label_settings = estilo_espacial
	
	# Nos aseguramos de que los 3 corazones empiecen intactos
	for c in corazones:
		c.visible = true
		c.play("lleno")

func _process(delta: float) -> void:
	var tiempo_restante = ceil(timer_espacio.time_left)
	label_tiempo.text = "DAÑO DEL ENTORNO ESPACIAL EN: " + str(tiempo_restante)
	
	if gato:
		var vidas_actuales = clamp(3 - gato.impactos_recibidos, 0, 3)
		if vidas_actuales != vidas_anteriores:
			actualizar_corazones(vidas_anteriores, vidas_actuales)
			vidas_anteriores = vidas_actuales

func actualizar_corazones(antes: int, ahora: int) -> void:
	# SI PERDIMOS VIDA: Reproduce tu animación frame por frame
	if ahora < antes:
		for i in range(ahora, antes):
			var corazon = corazones[i]
			corazon.play("romper")
			# Si quieres que el corazón desaparezca del todo al terminar de romperse,
			# descomenta las siguientes dos líneas quitando el símbolo #:
			# await corazon.animation_finished
			# corazon.visible = false
			
	# SI GANAMOS VIDA (Orbe o reaparición): Vuelve a estar lleno
	elif ahora > antes:
		for i in range(antes, ahora):
			var corazon = corazones[i]
			corazon.visible = true
			corazon.play("lleno")

func _on_timer_timeout() -> void:
	if gato and gato.has_method("recibir_daño_espacio"):
		gato.recibir_daño_espacio()
		
