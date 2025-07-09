extends CanvasLayer

signal initiate_round
signal ending_round
signal round_timeout
signal initiate_contruction

enum Estado {
	ESPERANDO,
	CONSTRUCCION,
	JUGANDO,
	TERMINANDO
}

@onready var round_message = $RoundMessage
@onready var timer_label = $TimerLabel
@onready var round_timer = $RoundTimer
@export var round_time: int
@export var building_player_scene: PackedScene
@export var object_placeholder_scene: PackedScene
@export var planeta_scene: PackedScene
@export var agujero_negro_scene: PackedScene

var time_remaining = 0.0
var estado_actual: Estado = Estado.ESPERANDO
var active_builders = 0
@onready var selection_ui = $ObjectSelectionUI
@onready var objetos_seleccionados = {}

var game_paused: bool = false  # Nuevo: estado actual de pausa


#SONIDOS 
@onready var music_player: AudioStreamPlayer = $Node/MusicPlayer
const playing_music = preload("res://assets/Music/Flim well cut.mp3")
const lobby_music = preload("res://assets/Music/patapim well cut.mp3")
@onready var start_sound: AudioStreamPlayer = $Node/StartSound
@onready var winning_sound: AudioStreamPlayer = $Node/WinningSound


func reproducir_musica(stream: AudioStream):
	if music_player.stream != stream:
		music_player.stream = stream
		music_player.play()
func cambio_volumen_gradual(target_db):
	var fade_time = 1.0  # segundos
	var start_db = music_player.volume_db
	var timer = 0.0
	while timer < fade_time:
		var t = timer / fade_time
		music_player.volume_db = lerp(start_db, target_db, t)
		await get_tree().process_frame
		timer += get_process_delta_time()
	music_player.volume_db = target_db
func _ready():
	round_timer.wait_time = 1.0
	round_timer.one_shot = false
	round_timer.timeout.connect(_on_round_timer_tick)
	selection_ui.object_selected.connect(enviar_seleccion)
	set_multiplayer_authority(1)
	process_mode = Node.PROCESS_MODE_ALWAYS
	round_timer.process_mode = Node.PROCESS_MODE_PAUSABLE  # Nuevo: el temporizador se detiene durante la pausa

func _process(delta):
	# Mantener mensaje de espera en estado ESPERANDO (código existente)
	if estado_actual == Estado.ESPERANDO:
		round_message.visible = true
		if is_multiplayer_authority():
			round_message.text = "Click to start round"
			if Input.is_action_just_pressed("fire"):
				start_building_fase.rpc()
		else:
			round_message.text = "Waiting for host to start"
		center_message()

	# Nuevo: Gestión de input de pausa solo durante el juego
	if estado_actual == Estado.JUGANDO:
		if Input.is_action_just_pressed("pause"):
			if not game_paused:
				pause_game.rpc()   # cualquier jugador puede solicitar pausar
			else:
				resume_game.rpc()  # cualquier jugador puede quitar la pausa

func cambiar_fase(nuevo_estado: Estado):
	estado_actual = nuevo_estado
	match nuevo_estado:
		Estado.ESPERANDO:
			reproducir_musica(lobby_music)
			music_player.volume_db = -10.0 
			round_message.text = "Waiting for round to start"
			round_message.visible = true
		Estado.CONSTRUCCION:
			round_message.text = "Construction phase"
			round_message.visible = true
			center_message()
			await get_tree().create_timer(2.0).timeout
			round_message.visible = false
			emit_signal("initiate_contruction")
			if multiplayer.get_unique_id() == 1:
				mostrar_ui_seleccion()
				objetos_seleccionados = {}
				await esperar_seleccion_objetos()
				spawn_building_players.rpc(objetos_seleccionados)
			else:
				mostrar_ui_seleccion()
		Estado.JUGANDO:
			reproducir_musica(playing_music)
			music_player.volume_db = 0.0
			round_message.visible = false
			if is_multiplayer_authority():
				start_round.rpc()
		Estado.TERMINANDO:
			end_round("Round Over")
	center_message()

func mostrar_ui_seleccion():
	selection_ui.show_ui()

@rpc("any_peer", "call_remote")
func recibir_seleccion(player_id: int, objeto_data: Dictionary):
	objetos_seleccionados[player_id] = objeto_data
	print("Jugador %d seleccionó: %s" % [player_id, objeto_data.get("name", "Desconocido")])
	print("estado actual objetos seleccionados: ")
	print(objetos_seleccionados)

func esperar_seleccion_objetos():
	for player_data in Game.players:
		if not objetos_seleccionados.has(player_data.id):
			objetos_seleccionados[player_data.id] = null
	while objetos_seleccionados.values().has(null):
		await get_tree().process_frame

func enviar_seleccion(objeto_data: Dictionary):
	var player_id = multiplayer.get_unique_id()
	if is_multiplayer_authority():
		player_id = 1
		recibir_seleccion(player_id, objeto_data)
		print("Servidor seleccionó de : ", player_id, " con objeto: ", objeto_data)
	else:
		recibir_seleccion.rpc(player_id, objeto_data)
		print("Enviando selección de: ", player_id, " con objeto: ", objeto_data)

@rpc("authority", "call_local")
func start_building_fase():
	cambiar_fase(Estado.CONSTRUCCION)

@rpc("authority", "call_local")
func spawn_building_players(objetos_seleccionados_temp):
	print("inicio spawneo de constructores")
	active_builders = Game.players.size()
	for i in Game.players.size():
		var player_data = Game.players[i]
		var builder = building_player_scene.instantiate()
		var player_id = Game.players[i].id
		var obj_data = objetos_seleccionados_temp.get(player_id, {})
		var scene_path = obj_data.get("scene_path", "")
		if scene_path != "":
			var loaded_scene = load(scene_path)
			if loaded_scene is PackedScene:
				builder.object_scene = loaded_scene
			else:
				print("⚠️ Error: Escena no válida cargada desde path:", scene_path)
				builder.object_scene = object_placeholder_scene
		else:
			builder.object_scene = object_placeholder_scene
		builder.name = "Builder" + str(i)
		builder.global_position = Vector2(100 + i * 100, 200)
		builder.round_manager = self
		get_parent().get_node("BuildingPlayers").add_child(builder)
		builder.setup(player_data)

func notify_building_done():
	active_builders -= 1
	print("Building done por un builder, Builders restantes : " + str(active_builders))
	if active_builders <= 0:
		end_builiding_fase.rpc()

@rpc("authority", "call_local")
func end_builiding_fase():
	cambio_volumen_gradual(-50.0)
	start_sound.play()
	round_message.visible = true
	round_message.text = "Starting round in 3"
	await get_tree().create_timer(1.0).timeout
	round_message.text = "Starting round in 2"
	await get_tree().create_timer(1.0).timeout
	round_message.text = "Starting round in 1"
	await get_tree().create_timer(1.0).timeout
	cambiar_fase(Estado.JUGANDO)

@rpc("authority", "call_local")
func start_round():
	time_remaining = round_time
	update_timer_label()
	round_timer.start()
	emit_signal("initiate_round")

func _on_round_timer_tick():
	time_remaining -= 1
	update_timer_label()
	if time_remaining <= 0:
		round_timer.stop()
		timer_label.text = ""
		emit_signal("round_timeout")

func update_timer_label():
	timer_label.text = str(int(time_remaining))
	var screen_size = get_viewport().get_visible_rect().size
	timer_label.set_position(Vector2(
		screen_size.x / 2 - timer_label.size.x / 2,
		20
	))

func end_round(message: String):
	winning_sound.play()
	round_timer.stop()
	round_message.text = message
	round_message.visible = true
	center_message()
	await get_tree().create_timer(3.0).timeout
	round_message.visible = false
	emit_signal("ending_round")
	time_remaining = round_time
	update_timer_label()

func center_message():
	var screen_size = get_viewport().get_visible_rect().size
	round_message.set_position(screen_size / 2 - round_message.get_size() / 2)

func change_text(message: String):
	round_message.text = message
	round_message.visible = true
	center_message()

# Nuevas funciones RPC para pausar/reanudar el juego:
@rpc("any_peer", "call_local")
func pause_game():
	if game_paused:
		return  # Ya estaba pausado, no hacer nada
	game_paused = true
	get_tree().paused = true                        # Pausar el árbol de la escena (detiene juego)
	round_message.text = "Pause (press escape to resume)"
	round_message.visible = true                    # Mostrar mensaje de pausa
	center_message()                                # Centrar "Pausado" en pantalla

@rpc("any_peer", "call_local")
func resume_game():
	if not game_paused:
		return  # Si no estaba pausado, nada que reanudar
	game_paused = false
	get_tree().paused = false                       # Quitar la pausa global
	round_message.visible = false                   # Ocultar mensaje de pausa
