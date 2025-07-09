extends Node2D

@export var box_scene: PackedScene = preload("res://scenes/structures/damageable_block.tscn")
@export var fire_speed := 600.0  # Magnitud de la velocidad
@export var fire_interval := 1.0
@export var authority_peer := 1  # Generalmente 1 = servidor

@onready var spawn_point: Marker2D = $SpawnPoint

func _ready():
	if is_multiplayer_authority():
		_fire_loop()
	else:
		set_process(false)

func _fire_loop():
	await get_tree().create_timer(fire_interval).timeout
	fire_box.rpc()
	_fire_loop()
@rpc("authority","call_local")
func fire_box():
	var box = box_scene.instantiate()

	box.affected_by_gravity = true
	box.infinite_health = false

	box.position = spawn_point.global_position
	box.set_multiplayer_authority(authority_peer)
	get_tree().current_scene.add_child(box)

	var random_scale = randf_range(1.0, 1.5)

	# Escala visual
	if box.has_node("Sprite2D"):
		box.get_node("Sprite2D").scale = box.get_node("Sprite2D").scale * random_scale

	# Escala colisión (solo funciona si es shape tipo Rectangle, Circle, etc.)
	if box.has_node("CollisionShape2D"):
		box.get_node("CollisionShape2D").scale = box.get_node("Sprite2D").scale * random_scale

	if box is RigidBody2D:
		var direction = Vector2.RIGHT.rotated(global_rotation)
		box.linear_velocity = direction * fire_speed
