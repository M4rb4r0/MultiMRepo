extends Node2D

@export var player_scene: PackedScene
@onready var markers: Node2D = $Markers

@onready var planets: Node2D = $Planets
@onready var players: Node2D = $Players
func _ready() -> void:
	spawn_players()
@rpc("authority","call_local")
func spawn_players():
	print("spawn players")
	for child in players.get_children():
		child.queue_free()
	for i in Game.players.size():
		var player_data = Game.players[i]
		var player_instance = player_scene.instantiate()
		players.add_child(player_instance)
		player_instance.setup(player_data,true)
		player_instance.global_position = markers.get_child(i).global_position
		player_instance.spawn_point = markers.get_child(i).global_position
